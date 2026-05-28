#!/usr/bin/env python3
"""Prepare dry-run tag backfill payloads for already imported KANJI-6 rows."""

from __future__ import annotations

import argparse
import random
from collections import Counter
from pathlib import Path
from typing import Any

from common import DEFAULT_OUTPUT_DIR, add_common_output_args, read_json, write_json
from tag_normalization import normalized_kanji_tags, normalized_tag_counts, normalized_word_tags


SAMPLE_SIZE = 100
SAMPLE_SEED = 20260528


def rows(data: Any, key: str) -> list[dict[str, Any]]:
    if isinstance(data, list):
        return data
    if isinstance(data, dict) and isinstance(data.get(key), list):
        return data[key]
    raise ValueError(f"JSON must be a list or contain '{key}'")


def load_rows(path: Path, key: str) -> list[dict[str, Any]]:
    return rows(read_json(path), key)


def backfill_word(row: dict[str, Any]) -> dict[str, Any] | None:
    current = [str(tag) for tag in row.get("tags") or [] if str(tag).strip()]
    merged = normalized_word_tags(row)
    add_tags = [tag for tag in merged if tag not in current and ":" in tag]
    if not add_tags:
        return None
    return {
        "id": row["id"],
        "word": row.get("word"),
        "reading": row.get("reading"),
        "external_id": row.get("external_id"),
        "current_tags": current,
        "add_tags": add_tags,
        "tags": merged,
    }


def backfill_kanji(row: dict[str, Any]) -> dict[str, Any] | None:
    current = [str(tag) for tag in row.get("tags") or [] if str(tag).strip()]
    merged = normalized_kanji_tags(row)
    add_tags = [tag for tag in merged if tag not in current and ":" in tag]
    if not add_tags:
        return None
    return {
        "id": row["id"],
        "character": row.get("character"),
        "external_id": row.get("external_id"),
        "current_tags": current,
        "add_tags": add_tags,
        "tags": merged,
    }


def sample_rows(rows_: list[dict[str, Any]]) -> list[dict[str, Any]]:
    by_id = sorted(rows_, key=lambda row: int(row.get("id") or 0))
    rng = random.Random(SAMPLE_SEED)
    selected: list[dict[str, Any]] = []
    seen: set[int] = set()
    for group in (by_id[: SAMPLE_SIZE // 2], rng.sample(rows_, min(len(rows_), SAMPLE_SIZE // 2)) if rows_ else []):
        for row in group:
            row_id = int(row.get("id") or 0)
            if row_id in seen:
                continue
            seen.add(row_id)
            selected.append(row)
    for row in by_id:
        if len(selected) >= SAMPLE_SIZE:
            break
        row_id = int(row.get("id") or 0)
        if row_id not in seen:
            seen.add(row_id)
            selected.append(row)
    return selected[:SAMPLE_SIZE]


def preflight(words: list[dict[str, Any]], kanji: list[dict[str, Any]]) -> dict[str, Any]:
    errors: list[dict[str, Any]] = []

    def duplicates(values: list[Any]) -> list[Any]:
        return [value for value, count in Counter(values).items() if value and count > 1]

    checks = [
        ("duplicate_word_ids", duplicates([row.get("id") for row in words])),
        ("duplicate_kanji_ids", duplicates([row.get("id") for row in kanji])),
        ("empty_word_add_tags", [row.get("id") for row in words if not row.get("add_tags")]),
        ("empty_kanji_add_tags", [row.get("id") for row in kanji if not row.get("add_tags")]),
    ]
    for check_type, values in checks:
        if values:
            errors.append({"type": check_type, "items": values[:50]})

    return {
        "failed": bool(errors),
        "errors": errors,
        "totals": {"words": len(words), "kanji": len(kanji)},
    }


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--words", type=Path, default=DEFAULT_OUTPUT_DIR / "recommended_v1_words_split_meanings.json")
    parser.add_argument("--kanji", type=Path, action="append", default=[])
    add_common_output_args(parser)
    args = parser.parse_args()

    kanji_paths = args.kanji or [
        DEFAULT_OUTPUT_DIR / "recommended_v1_kanji_split_meanings.json",
        DEFAULT_OUTPUT_DIR / "recommended_v1_new_kanji_split_meanings.json",
    ]
    word_rows = load_rows(args.words, "words")
    kanji_rows: list[dict[str, Any]] = []
    for path in kanji_paths:
        kanji_rows.extend(load_rows(path, "kanji"))

    word_backfills = [item for row in word_rows if (item := backfill_word(row))]
    kanji_backfills = [item for row in kanji_rows if (item := backfill_kanji(row))]
    gate = preflight(word_backfills, kanji_backfills)
    report = {
        "dry_run": True,
        "strategy": "Merge tags only. Existing rows are matched by id and current tags are preserved.",
        "inputs": {"words": str(args.words), "kanji": [str(path) for path in kanji_paths]},
        "preflight": gate,
        "counts": {
            "words": len(word_backfills),
            "kanji": len(kanji_backfills),
            "word_tag_counts": normalized_tag_counts(word_backfills),
            "kanji_tag_counts": normalized_tag_counts(kanji_backfills),
        },
        "samples": {
            "words": sample_rows(word_backfills),
            "kanji": sample_rows(kanji_backfills),
        },
    }

    write_json(args.output_dir / "tag_backfill_words.json", {"words": word_backfills})
    write_json(args.output_dir / "tag_backfill_kanji.json", {"kanji": kanji_backfills})
    write_json(args.output_dir / "tag_backfill_dry_run.json", report)
    print(f"tag backfill dry-run words={len(word_backfills)} kanji={len(kanji_backfills)} failed={gate['failed']}")
    if gate["failed"]:
        raise SystemExit(1)


if __name__ == "__main__":
    main()
