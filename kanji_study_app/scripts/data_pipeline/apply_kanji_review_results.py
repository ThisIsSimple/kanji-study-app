#!/usr/bin/env python3
"""Build dry-run patches from human-reviewed kanji validation results."""

from __future__ import annotations

import argparse
from collections import Counter
from datetime import datetime, timezone
from pathlib import Path
from typing import Any

from common import DEFAULT_OUTPUT_DIR, QUALITY_REVIEWED, dedupe, read_json, write_json
from validate_kanji_reviews import has_korean, rows_from_json


def review_rows(path: Path) -> list[dict[str, Any]]:
    data = read_json(path)
    if isinstance(data, list):
        return data
    if isinstance(data, dict) and isinstance(data.get("kanji"), list):
        return data["kanji"]
    raise ValueError("review JSON must be a list or contain a 'kanji' list")


def existing_by_id(rows: list[dict[str, Any]]) -> dict[int, dict[str, Any]]:
    return {int(row["id"]): row for row in rows if row.get("id") is not None}


def build_patch(row: dict[str, Any], existing: dict[int, dict[str, Any]], updated_at: str) -> tuple[dict[str, Any] | None, dict[str, Any] | None]:
    if row.get("review_decision") != "approve":
        return None, {"id": row.get("id"), "reason": "review_decision_not_approve"}
    if row.get("id") is None:
        return None, {"id": None, "reason": "missing_id"}

    row_id = int(row["id"])
    current = existing.get(row_id)
    if not current:
        return None, {"id": row_id, "reason": "id_not_found_in_existing_kanji"}
    if row.get("character") and row.get("character") != current.get("character"):
        return None, {"id": row_id, "reason": "character_mismatch", "expected": current.get("character"), "actual": row.get("character")}

    meanings_ko = dedupe(row.get("meanings_ko") or row.get("meanings") or [])
    meanings_ko = [meaning for meaning in meanings_ko if has_korean(meaning)]
    if not meanings_ko:
        return None, {"id": row_id, "reason": "empty_or_non_korean_meanings_ko"}

    patch = {
        "id": row_id,
        "character": current.get("character"),
        "meanings": meanings_ko,
        "meanings_ko": meanings_ko,
        "quality_status": QUALITY_REVIEWED,
        "meaning_source": "human_review",
        "updated_at": updated_at,
    }
    if row.get("review_notes"):
        patch["review_notes"] = row.get("review_notes")
    return patch, None


def build_dry_run(
    review_items: list[dict[str, Any]],
    existing_rows: list[dict[str, Any]],
    updated_at: str | None = None,
) -> dict[str, Any]:
    updated_at = updated_at or datetime.now(timezone.utc).isoformat()
    existing = existing_by_id(existing_rows)
    patches: list[dict[str, Any]] = []
    skipped: list[dict[str, Any]] = []
    for row in review_items:
        patch, skip = build_patch(row, existing, updated_at)
        if patch:
            patches.append(patch)
        if skip:
            skipped.append(skip)
    duplicate_patch_ids = [row_id for row_id, count in Counter(patch["id"] for patch in patches).items() if count > 1]
    return {
        "dry_run": True,
        "failed": bool(duplicate_patch_ids),
        "patches": patches,
        "skipped": skipped,
        "summary": {
            "review_rows": len(review_items),
            "patch_count": len(patches),
            "skipped_count": len(skipped),
            "duplicate_patch_ids": duplicate_patch_ids,
        },
    }


def apply_patches(_patches: list[dict[str, Any]]) -> None:
    raise RuntimeError(
        "--apply is intentionally not enabled for KANJI-8. Review the dry-run report and run a dedicated approved apply task."
    )


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--reviews", type=Path, required=True, help="Human review JSON")
    parser.add_argument("--existing-kanji", type=Path, required=True, help="Current kanji export JSON")
    parser.add_argument("--output-dir", type=Path, default=DEFAULT_OUTPUT_DIR / "kanji8")
    parser.add_argument("--apply", action="store_true", help="Reserved; not executed in KANJI-8")
    args = parser.parse_args()

    review_items = review_rows(args.reviews)
    existing_rows = rows_from_json(args.existing_kanji)
    report = build_dry_run(review_items, existing_rows)
    write_json(args.output_dir / "kanji_review_apply_dry_run.json", report)
    if args.apply:
        apply_patches(report["patches"])
    print(
        f"kanji review dry-run patches={report['summary']['patch_count']} skipped={report['summary']['skipped_count']} "
        f"-> {args.output_dir}"
    )
    if report["failed"]:
        raise SystemExit(1)


if __name__ == "__main__":
    main()
