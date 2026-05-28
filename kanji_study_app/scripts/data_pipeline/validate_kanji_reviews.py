#!/usr/bin/env python3
"""Validate ai_draft kanji rows before human review."""

from __future__ import annotations

import argparse
import re
from collections import Counter, defaultdict
from pathlib import Path
from typing import Any

from common import DEFAULT_OUTPUT_DIR, QUALITY_AI_DRAFT, read_json, write_json


HANGUL_RE = re.compile(r"[가-힣]")
LATIN_RE = re.compile(r"[A-Za-z]")
SENTENCE_RE = re.compile(r"[.!?。]|(입니다|한다|하다|되다|이다)$")
EMPHATIC_RE = re.compile(r"(매우|아주|극히|대단히|완전히|최고)")
SPECIALIZED_TAG_PREFIXES = ("domain:", "register:")
RARE_TAGS = {"rare", "obsolete", "archaism", "rarely-used kanji form", "out-dated or obsolete kana usage"}


def rows_from_json(path: Path) -> list[dict[str, Any]]:
    data = read_json(path)
    if isinstance(data, list):
        return data
    if isinstance(data, dict) and isinstance(data.get("kanji"), list):
        return data["kanji"]
    raise ValueError("input JSON must be a list or contain a 'kanji' list")


def has_korean(value: Any) -> bool:
    return bool(HANGUL_RE.search(str(value or "")))


def is_english_only(value: Any) -> bool:
    text = str(value or "").strip()
    return bool(text and LATIN_RE.search(text) and not has_korean(text))


def string_list(value: Any) -> list[str]:
    if not isinstance(value, list):
        return []
    return [str(item).strip() for item in value if str(item).strip()]


def reading_lists(row: dict[str, Any]) -> tuple[list[str] | None, list[str] | None, str | None]:
    readings = row.get("readings")
    if isinstance(readings, dict):
        on = readings.get("on")
        kun = readings.get("kun")
        if not isinstance(on or [], list) or not isinstance(kun or [], list):
            return None, None, "readings_on_kun_not_list"
        return string_list(on or []), string_list(kun or []), None

    on = row.get("on_readings")
    kun = row.get("kun_readings")
    if on is not None or kun is not None:
        if not isinstance(on or [], list) or not isinstance(kun or [], list):
            return None, None, "on_readings_or_kun_readings_not_list"
        return string_list(on or []), string_list(kun or []), None

    return None, None, "readings_missing"


def batch_tags(row: dict[str, Any]) -> list[str]:
    return [tag for tag in row.get("tags") or [] if str(tag).startswith("batch:")]


def group_counts(rows: list[dict[str, Any]]) -> dict[str, Any]:
    tag_counts: Counter[str] = Counter()
    for row in rows:
        tag_counts.update(str(tag) for tag in row.get("tags") or [])

    return {
        "total": len(rows),
        "by_batch": dict(sorted((tag, count) for tag, count in tag_counts.items() if tag.startswith("batch:"))),
        "by_source_tag": dict(sorted((tag, count) for tag, count in tag_counts.items() if tag.startswith("source:"))),
        "by_domain_tag": dict(sorted((tag, count) for tag, count in tag_counts.items() if tag.startswith("domain:"))),
        "by_quality_status": dict(sorted(Counter(str(row.get("quality_status") or "") for row in rows).items())),
        "by_meaning_source": dict(sorted(Counter(str(row.get("meaning_source") or "") for row in rows).items())),
    }


def duplicate_errors(rows: list[dict[str, Any]], field: str, error_type: str) -> list[dict[str, Any]]:
    groups: dict[Any, list[int]] = defaultdict(list)
    for row in rows:
        value = row.get(field)
        if value:
            groups[value].append(row.get("id"))
    return [
        {"type": error_type, "value": value, "ids": ids}
        for value, ids in sorted(groups.items(), key=lambda item: str(item[0]))
        if len(ids) > 1
    ]


def hard_errors_for_row(row: dict[str, Any]) -> list[dict[str, Any]]:
    errors: list[dict[str, Any]] = []
    meanings = string_list(row.get("meanings"))
    meanings_ko = string_list(row.get("meanings_ko"))
    meanings_en = string_list(row.get("meanings_en"))
    on, kun, reading_error = reading_lists(row)

    checks = [
        ("empty_character", not row.get("character")),
        ("empty_meanings", not meanings),
        ("empty_meanings_ko", not meanings_ko),
        ("missing_meanings_en", not meanings_en),
        ("missing_quality_status", not row.get("quality_status")),
        ("missing_meaning_source", not row.get("meaning_source")),
    ]
    for error_type, failed in checks:
        if failed:
            errors.append({"type": error_type})

    english_only = [value for value in [*meanings, *meanings_ko] if is_english_only(value)]
    if english_only:
        errors.append({"type": "korean_display_meanings_contain_english_only", "values": english_only[:5]})
    if reading_error:
        errors.append({"type": "invalid_reading_structure", "error": reading_error})
    return errors


def warnings_for_row(row: dict[str, Any]) -> list[dict[str, Any]]:
    warnings: list[dict[str, Any]] = []
    meanings_ko = string_list(row.get("meanings_ko"))
    meanings_en = string_list(row.get("meanings_en"))
    _, _, reading_error = reading_lists(row)
    tags = [str(tag) for tag in row.get("tags") or []]

    if len(meanings_ko) > 6:
        warnings.append({"type": "too_many_korean_meanings", "count": len(meanings_ko)})
    long_meanings = [meaning for meaning in meanings_ko if len(meaning) > 12]
    if long_meanings:
        warnings.append({"type": "long_korean_meanings", "values": long_meanings[:5]})
    sentence_like = [meaning for meaning in meanings_ko if SENTENCE_RE.search(meaning)]
    if sentence_like:
        warnings.append({"type": "sentence_like_korean_meanings", "values": sentence_like[:5]})
    emphatic = [meaning for meaning in meanings_ko if EMPHATIC_RE.search(meaning)]
    if emphatic:
        warnings.append({"type": "emphatic_korean_meanings", "values": emphatic[:5]})
    if meanings_ko and meanings_en and abs(len(meanings_ko) - len(meanings_en)) >= 5:
        warnings.append({"type": "meaning_count_imbalance", "ko": len(meanings_ko), "en": len(meanings_en)})
    if not string_list(row.get("korean_on_readings")):
        warnings.append({"type": "missing_korean_on_readings"})
    if any(tag.startswith(SPECIALIZED_TAG_PREFIXES) for tag in tags) or any(tag in RARE_TAGS for tag in tags):
        warnings.append({"type": "specialized_or_rare_tags", "tags": tags})
    if reading_error is None:
        on, kun, _ = reading_lists(row)
        if on == [] and kun == []:
            warnings.append({"type": "no_japanese_readings"})
    return warnings


def annotate_rows(rows: list[dict[str, Any]]) -> tuple[list[dict[str, Any]], list[dict[str, Any]]]:
    candidates: list[dict[str, Any]] = []
    for row in rows:
        errors = hard_errors_for_row(row)
        warnings = warnings_for_row(row)
        candidates.append(
            {
                "id": row.get("id"),
                "character": row.get("character"),
                "external_id": row.get("external_id"),
                "meanings": row.get("meanings") or [],
                "meanings_ko": row.get("meanings_ko") or [],
                "meanings_en": row.get("meanings_en") or [],
                "on_readings": row.get("on_readings") or (row.get("readings") or {}).get("on") or [],
                "kun_readings": row.get("kun_readings") or (row.get("readings") or {}).get("kun") or [],
                "korean_on_readings": row.get("korean_on_readings") or [],
                "tags": row.get("tags") or [],
                "quality_status": row.get("quality_status"),
                "meaning_source": row.get("meaning_source"),
                "validation": {
                    "hard_errors": errors,
                    "warnings": warnings,
                    "review_priority": review_priority(errors, warnings, row),
                },
            }
        )
    samples = sorted(
        candidates,
        key=lambda row: (
            -len(row["validation"]["hard_errors"]),
            -len(row["validation"]["warnings"]),
            row.get("id") or 0,
        ),
    )
    return candidates, samples


def review_priority(errors: list[dict[str, Any]], warnings: list[dict[str, Any]], row: dict[str, Any]) -> int:
    priority = len(errors) * 100 + len(warnings) * 10
    if "batch:kanji7_v2" in (row.get("tags") or []):
        priority += 1
    return priority


def validation_report(all_rows: list[dict[str, Any]], target_rows: list[dict[str, Any]], candidates: list[dict[str, Any]]) -> dict[str, Any]:
    hard_error_counts: Counter[str] = Counter()
    warning_counts: Counter[str] = Counter()
    hard_error_items: list[dict[str, Any]] = []
    warning_items: list[dict[str, Any]] = []

    for duplicate_error in [
        *duplicate_errors(target_rows, "id", "duplicate_ids"),
        *duplicate_errors(target_rows, "character", "duplicate_characters"),
        *duplicate_errors(target_rows, "external_id", "duplicate_external_ids"),
    ]:
        hard_error_counts[duplicate_error["type"]] += 1
        hard_error_items.append(duplicate_error)

    for row in candidates:
        row_id = row.get("id")
        character = row.get("character")
        for error in row["validation"]["hard_errors"]:
            hard_error_counts[error["type"]] += 1
            hard_error_items.append({"id": row_id, "character": character, **error})
        for warning in row["validation"]["warnings"]:
            warning_counts[warning["type"]] += 1
            warning_items.append({"id": row_id, "character": character, **warning})

    return {
        "failed": bool(hard_error_items),
        "scope": {
            "input_rows": len(all_rows),
            "target_filter": {"quality_status": QUALITY_AI_DRAFT},
            "target_rows": len(target_rows),
        },
        "counts": group_counts(target_rows),
        "hard_errors": {
            "total": len(hard_error_items),
            "by_type": dict(sorted(hard_error_counts.items())),
            "items_sample": hard_error_items[:100],
        },
        "warnings": {
            "total": len(warning_items),
            "by_type": dict(sorted(warning_counts.items())),
            "items_sample": warning_items[:100],
        },
    }


def target_ai_draft_rows(rows: list[dict[str, Any]]) -> list[dict[str, Any]]:
    return [row for row in rows if row.get("quality_status") == QUALITY_AI_DRAFT]


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--input", type=Path, required=True, help="Supabase kanji export or snapshot JSON")
    parser.add_argument("--output-dir", type=Path, default=DEFAULT_OUTPUT_DIR / "kanji8")
    parser.add_argument("--sample-size", type=int, default=100)
    args = parser.parse_args()

    all_rows = rows_from_json(args.input)
    target_rows = target_ai_draft_rows(all_rows)
    candidates, sorted_candidates = annotate_rows(target_rows)
    report = validation_report(all_rows, target_rows, candidates)

    write_json(args.output_dir / "kanji_validation_report.json", report)
    write_json(args.output_dir / "kanji_validation_candidates.json", {"kanji": candidates})
    write_json(args.output_dir / "kanji_review_sample_100.json", {"kanji": sorted_candidates[: args.sample_size]})

    print(
        f"validated ai_draft kanji={len(target_rows)} hard_errors={report['hard_errors']['total']} "
        f"warnings={report['warnings']['total']} -> {args.output_dir}"
    )
    if report["failed"]:
        raise SystemExit(1)


if __name__ == "__main__":
    main()
