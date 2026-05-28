#!/usr/bin/env python3
"""Select deterministic KANJI-7 v2 candidates from the KANJI-6 merged backlog."""

from __future__ import annotations

import argparse
import random
import re
from collections import Counter, defaultdict
from pathlib import Path
from typing import Any

from common import (
    DEFAULT_OUTPUT_DIR,
    QUALITY_AI_DRAFT,
    SOURCE_JMDICT,
    SOURCE_KANJIDIC2,
    add_common_output_args,
    read_json,
    write_json,
)
from tag_normalization import (
    derive_kanji_domain_tags,
    normalized_kanji_tags,
    normalized_tag_counts,
    normalized_word_tags,
)


DEFAULT_WORD_LIMIT = 10_000
DEFAULT_KANJI_LIMIT = 1_000
SAMPLE_SIZE = 100
SAMPLE_SEED = 20260528
KANJI_RE = re.compile(r"[\u3400-\u9fff\uf900-\ufaff]")
KANA_RE = re.compile(r"[\u3040-\u30ff]")
LATIN_DIGIT_ONLY_RE = re.compile(r"^[A-Za-z0-9\s._+/#&'’()\\-]+$")
EXCLUDED_WORD_TAGS = {
    "word usually written using kana alone",
    "rare term",
    "obsolete term",
    "dated term",
    "archaism",
    "archaic",
    "historical term",
    "derogatory",
    "vulgar expression or word",
}


def rows(data: Any, key: str) -> list[dict[str, Any]]:
    if isinstance(data, list):
        return data
    if isinstance(data, dict) and isinstance(data.get(key), list):
        return data[key]
    raise ValueError(f"JSON must be a list or contain '{key}'")


def load_rows(path: Path, key: str) -> list[dict[str, Any]]:
    return rows(read_json(path), key)


def kanji_chars(value: str) -> set[str]:
    return set(KANJI_RE.findall(value or ""))


def has_kana_or_kanji(value: str) -> bool:
    return bool(KANA_RE.search(value or "") or KANJI_RE.search(value or ""))


def is_latin_digit_only(value: str) -> bool:
    text = str(value or "").strip()
    return bool(text and LATIN_DIGIT_ONLY_RE.fullmatch(text) and not has_kana_or_kanji(text))


def is_single_kanji_word(value: str) -> bool:
    text = str(value or "").strip()
    return len(text) == 1 and bool(KANJI_RE.fullmatch(text))


def has_word_meanings(row: dict[str, Any]) -> bool:
    return bool(row.get("meanings"))


def has_excluded_word_tag(row: dict[str, Any]) -> bool:
    return bool(set(row.get("tags") or []) & EXCLUDED_WORD_TAGS)


def has_kanji_meanings(row: dict[str, Any]) -> bool:
    return bool(row.get("meanings"))


def has_kanji_reading(row: dict[str, Any]) -> bool:
    readings = row.get("readings") or {}
    return bool((readings.get("on") or []) or (readings.get("kun") or []))


def word_key(row: dict[str, Any]) -> tuple[str, str]:
    return (str(row.get("word") or "").strip(), str(row.get("reading") or "").strip())


def valid_backlog_words(
    merged_words: list[dict[str, Any]],
    imported_word_ids: set[int],
) -> tuple[list[dict[str, Any]], Counter[str]]:
    exclusions: Counter[str] = Counter()
    valid: list[dict[str, Any]] = []
    seen_keys: set[tuple[str, str]] = set()
    seen_external_ids: set[str] = set()
    for row in sorted(merged_words, key=lambda item: int(item.get("id") or 0)):
        if row.get("id") in imported_word_ids:
            exclusions["already_imported"] += 1
            continue
        if row.get("source") != SOURCE_JMDICT:
            exclusions["non_jmdict_source"] += 1
            continue
        if row.get("quality_status") != QUALITY_AI_DRAFT:
            exclusions["not_ai_draft"] += 1
            continue
        word, reading = word_key(row)
        if not word or not reading:
            exclusions["empty_word_or_reading"] += 1
            continue
        if not has_word_meanings(row):
            exclusions["empty_meanings"] += 1
            continue
        if is_latin_digit_only(word):
            exclusions["latin_digit_only_word"] += 1
            continue
        if is_single_kanji_word(word):
            exclusions["single_kanji_word"] += 1
            continue
        if has_excluded_word_tag(row):
            exclusions["excluded_word_tag"] += 1
            continue
        if word_key(row) in seen_keys:
            exclusions["duplicate_word_reading"] += 1
            continue
        external_id = row.get("external_id")
        if external_id and external_id in seen_external_ids:
            exclusions["duplicate_external_id"] += 1
            continue
        seen_keys.add(word_key(row))
        if external_id:
            seen_external_ids.add(external_id)
        valid.append(row)
    return valid, exclusions


def valid_backlog_kanji(
    merged_kanji: list[dict[str, Any]],
    imported_kanji_ids: set[int],
) -> tuple[list[dict[str, Any]], Counter[str]]:
    exclusions: Counter[str] = Counter()
    valid: list[dict[str, Any]] = []
    seen_characters: set[str] = set()
    seen_external_ids: set[str] = set()
    for row in sorted(merged_kanji, key=lambda item: int(item.get("id") or 0)):
        if row.get("id") in imported_kanji_ids:
            exclusions["already_imported"] += 1
            continue
        if row.get("source") != SOURCE_KANJIDIC2:
            exclusions["non_kanjidic2_source"] += 1
            continue
        if row.get("quality_status") != QUALITY_AI_DRAFT:
            exclusions["not_ai_draft"] += 1
            continue
        character = str(row.get("character") or "").strip()
        if not character:
            exclusions["empty_character"] += 1
            continue
        if character in seen_characters:
            exclusions["duplicate_character"] += 1
            continue
        external_id = row.get("external_id")
        if external_id and external_id in seen_external_ids:
            exclusions["duplicate_external_id"] += 1
            continue
        if not has_kanji_meanings(row):
            exclusions["empty_meanings"] += 1
            continue
        if not has_kanji_reading(row):
            exclusions["empty_readings"] += 1
            continue
        seen_characters.add(character)
        if external_id:
            seen_external_ids.add(external_id)
        valid.append(row)
    return valid, exclusions


def kanji_frequency(words: list[dict[str, Any]]) -> Counter[str]:
    counts: Counter[str] = Counter()
    for row in words:
        counts.update(kanji_chars(str(row.get("word") or "")))
    return counts


def grade_sort_value(row: dict[str, Any]) -> int:
    grade = int(row.get("grade") or 0)
    return grade if grade > 0 else 999


def select_kanji(
    candidates: list[dict[str, Any]],
    word_kanji_frequency: Counter[str],
    limit: int,
) -> list[dict[str, Any]]:
    ranked = sorted(
        candidates,
        key=lambda row: (
            -word_kanji_frequency.get(str(row.get("character") or ""), 0),
            not bool(row.get("is_common")),
            grade_sort_value(row),
            int(row.get("strokeCount") or 0),
            int(row.get("id") or 0),
        ),
    )
    return ranked[:limit]


def word_rank(row: dict[str, Any], allowed_kanji: set[str], selected_kanji: set[str]) -> tuple[Any, ...]:
    chars = kanji_chars(str(row.get("word") or ""))
    contains_kanji = bool(chars)
    covered = chars.issubset(allowed_kanji)
    selected_overlap = len(chars & selected_kanji)
    reading_len = len(str(row.get("reading") or ""))
    return (
        not (contains_kanji and covered),
        not contains_kanji,
        len(str(row.get("word") or "")),
        reading_len,
        -selected_overlap,
        int(row.get("id") or 0),
    )


def select_words(
    candidates: list[dict[str, Any]],
    imported_kanji: list[dict[str, Any]],
    selected_kanji: list[dict[str, Any]],
    limit: int,
) -> list[dict[str, Any]]:
    imported_chars = {row.get("character") for row in imported_kanji if row.get("character")}
    selected_chars = {row.get("character") for row in selected_kanji if row.get("character")}
    allowed_kanji = imported_chars | selected_chars
    ranked = sorted(candidates, key=lambda row: word_rank(row, allowed_kanji, selected_chars))
    return ranked[:limit]


def sample_rows(rows_: list[dict[str, Any]]) -> list[dict[str, Any]]:
    by_id = sorted(rows_, key=lambda row: int(row.get("id") or 0))
    rng = random.Random(SAMPLE_SEED)
    random_rows = rng.sample(rows_, min(len(rows_), SAMPLE_SIZE // 3)) if rows_ else []
    selected: list[dict[str, Any]] = []
    seen: set[int] = set()
    for group in (by_id[: SAMPLE_SIZE // 3], random_rows):
        for row in group:
            row_id = int(row.get("id") or 0)
            if row_id not in seen:
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


def preflight(
    words_: list[dict[str, Any]],
    kanji_: list[dict[str, Any]],
    imported_word_ids: set[int],
    imported_kanji_ids: set[int],
    expected_words: int,
    expected_kanji: int,
) -> dict[str, Any]:
    errors: list[dict[str, Any]] = []
    warnings: list[dict[str, Any]] = []

    if len(words_) != expected_words:
        errors.append({"type": "unexpected_word_count", "expected": expected_words, "actual": len(words_)})
    if len(kanji_) != expected_kanji:
        errors.append({"type": "unexpected_kanji_count", "expected": expected_kanji, "actual": len(kanji_)})

    word_ids = [row.get("id") for row in words_]
    kanji_ids = [row.get("id") for row in kanji_]
    word_keys = [word_key(row) for row in words_]
    kanji_characters = [row.get("character") for row in kanji_]
    kanji_external_ids = [row.get("external_id") for row in kanji_ if row.get("external_id")]
    word_external_ids = [row.get("external_id") for row in words_ if row.get("external_id")]

    def duplicates(values: list[Any]) -> list[Any]:
        return [value for value, count in Counter(values).items() if value and count > 1]

    checks = [
        ("duplicate_word_ids", duplicates(word_ids)),
        ("duplicate_word_reading", duplicates(word_keys)),
        ("duplicate_word_external_ids", duplicates(word_external_ids)),
        ("duplicate_kanji_ids", duplicates(kanji_ids)),
        ("duplicate_kanji_characters", duplicates(kanji_characters)),
        ("duplicate_kanji_external_ids", duplicates(kanji_external_ids)),
        ("v1_word_id_overlap", sorted(set(word_ids) & imported_word_ids)),
        ("v1_kanji_id_overlap", sorted(set(kanji_ids) & imported_kanji_ids)),
        ("empty_word_or_reading", [row.get("id") for row in words_ if not word_key(row)[0] or not word_key(row)[1]]),
        ("empty_word_meanings", [row.get("id") for row in words_ if not has_word_meanings(row)]),
        ("latin_digit_only_words", [row.get("id") for row in words_ if is_latin_digit_only(str(row.get("word") or ""))]),
        ("single_kanji_words", [row.get("id") for row in words_ if is_single_kanji_word(str(row.get("word") or ""))]),
        ("excluded_word_tags", [row.get("id") for row in words_ if has_excluded_word_tag(row)]),
        ("empty_kanji_character", [row.get("id") for row in kanji_ if not row.get("character")]),
        ("empty_kanji_meanings", [row.get("id") for row in kanji_ if not has_kanji_meanings(row)]),
        ("empty_kanji_readings", [row.get("id") for row in kanji_ if not has_kanji_reading(row)]),
    ]
    for check_type, values in checks:
        if values:
            errors.append({"type": check_type, "items": values[:50]})

    kana_only_count = sum(1 for row in words_ if not kanji_chars(str(row.get("word") or "")))
    kanji_word_count = len(words_) - kana_only_count
    if kana_only_count:
        warnings.append({"type": "kana_only_word_backfill", "count": kana_only_count})

    return {
        "failed": bool(errors),
        "errors": errors,
        "warnings": warnings,
        "totals": {"words": len(words_), "kanji": len(kanji_)},
        "coverage": {"kanji_word_count": kanji_word_count, "kana_only_word_count": kana_only_count},
    }


def compact_word_sample(row: dict[str, Any]) -> dict[str, Any]:
    return {
        "id": row.get("id"),
        "word": row.get("word"),
        "reading": row.get("reading"),
        "meanings": row.get("meanings"),
        "external_id": row.get("external_id"),
        "tags": row.get("tags") or [],
    }


def compact_kanji_sample(row: dict[str, Any]) -> dict[str, Any]:
    readings = row.get("readings") or {}
    return {
        "id": row.get("id"),
        "character": row.get("character"),
        "meanings": row.get("meanings"),
        "on_readings": readings.get("on") or [],
        "kun_readings": readings.get("kun") or [],
        "external_id": row.get("external_id"),
        "grade": row.get("grade"),
        "strokeCount": row.get("strokeCount"),
        "tags": row.get("tags") or [],
    }


def normalize_selected_tags(
    selected_words: list[dict[str, Any]],
    selected_kanji: list[dict[str, Any]],
) -> tuple[list[dict[str, Any]], list[dict[str, Any]], dict[str, list[str]]]:
    tagged_words = [{**row, "tags": normalized_word_tags(row, batch="kanji7_v2")} for row in selected_words]
    derived_kanji_tags = derive_kanji_domain_tags(selected_kanji, tagged_words)
    tagged_kanji = [
        {
            **row,
            "tags": normalized_kanji_tags(
                row,
                derived_kanji_tags.get(str(row.get("character") or ""), []),
                batch="kanji7_v2",
            ),
        }
        for row in selected_kanji
    ]
    return tagged_words, tagged_kanji, derived_kanji_tags


def tag_backfill_report(imported_words: list[dict[str, Any]], imported_kanji: list[dict[str, Any]]) -> dict[str, Any]:
    word_candidates: list[dict[str, Any]] = []
    for row in imported_words:
        current_tags = set(row.get("tags") or [])
        normalized = normalized_word_tags(row)
        additions = [tag for tag in normalized if tag not in current_tags and ":" in tag]
        if additions:
            word_candidates.append(
                {
                    "id": row.get("id"),
                    "word": row.get("word"),
                    "reading": row.get("reading"),
                    "external_id": row.get("external_id"),
                    "add_tags": additions,
                }
            )

    kanji_candidates: list[dict[str, Any]] = []
    for row in imported_kanji:
        current_tags = set(row.get("tags") or [])
        normalized = normalized_kanji_tags(row)
        additions = [tag for tag in normalized if tag not in current_tags and ":" in tag]
        if additions:
            kanji_candidates.append(
                {
                    "id": row.get("id"),
                    "character": row.get("character"),
                    "external_id": row.get("external_id"),
                    "add_tags": additions,
                }
            )

    return {
        "strategy": "기존 row는 삭제/덮어쓰기 없이 external_id/id 기준으로 정규화 태그만 추가하는 backfill 후보로 추적합니다.",
        "words": {
            "candidate_count": len(word_candidates),
            "sample": word_candidates[:50],
        },
        "kanji": {
            "candidate_count": len(kanji_candidates),
            "sample": kanji_candidates[:50],
        },
    }


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--merged-words", type=Path, default=DEFAULT_OUTPUT_DIR / "merged_words.json")
    parser.add_argument("--merged-kanji", type=Path, default=DEFAULT_OUTPUT_DIR / "merged_kanji.json")
    parser.add_argument("--imported-words", type=Path, default=DEFAULT_OUTPUT_DIR / "recommended_v1_words_split_meanings.json")
    parser.add_argument("--imported-kanji", type=Path, action="append", default=[])
    parser.add_argument("--word-limit", type=int, default=DEFAULT_WORD_LIMIT)
    parser.add_argument("--kanji-limit", type=int, default=DEFAULT_KANJI_LIMIT)
    add_common_output_args(parser)
    args = parser.parse_args()

    imported_kanji_paths = args.imported_kanji or [
        DEFAULT_OUTPUT_DIR / "recommended_v1_kanji_split_meanings.json",
        DEFAULT_OUTPUT_DIR / "recommended_v1_new_kanji_split_meanings.json",
    ]

    merged_words = load_rows(args.merged_words, "words")
    merged_kanji = load_rows(args.merged_kanji, "kanji")
    imported_words = load_rows(args.imported_words, "words")
    imported_kanji: list[dict[str, Any]] = []
    for path in imported_kanji_paths:
        imported_kanji.extend(load_rows(path, "kanji"))

    imported_word_ids = {int(row["id"]) for row in imported_words}
    imported_kanji_ids = {int(row["id"]) for row in imported_kanji}

    valid_words, word_exclusions = valid_backlog_words(merged_words, imported_word_ids)
    valid_kanji, kanji_exclusions = valid_backlog_kanji(merged_kanji, imported_kanji_ids)
    frequency = kanji_frequency(valid_words)
    selected_kanji = select_kanji(valid_kanji, frequency, args.kanji_limit)
    selected_words = select_words(valid_words, imported_kanji, selected_kanji, args.word_limit)
    selected_words, selected_kanji, derived_kanji_tags = normalize_selected_tags(selected_words, selected_kanji)
    gate = preflight(
        selected_words,
        selected_kanji,
        imported_word_ids,
        imported_kanji_ids,
        args.word_limit,
        args.kanji_limit,
    )

    selected_kanji_chars = {row["character"] for row in selected_kanji}
    imported_kanji_chars = {row["character"] for row in imported_kanji if row.get("character")}
    known_chars = imported_kanji_chars | selected_kanji_chars
    word_coverage = Counter(
        "kanji_covered"
        if kanji_chars(str(row.get("word") or "")) and kanji_chars(str(row.get("word") or "")).issubset(known_chars)
        else "kana_only"
        if not kanji_chars(str(row.get("word") or ""))
        else "kanji_not_fully_covered"
        for row in selected_words
    )

    report = {
        "issue": "KANJI-7",
        "selection_policy": "app_coverage_v2",
        "limits": {"words": args.word_limit, "kanji": args.kanji_limit},
        "inputs": {
            "merged_words": str(args.merged_words),
            "merged_kanji": str(args.merged_kanji),
            "imported_words": str(args.imported_words),
            "imported_kanji": [str(path) for path in imported_kanji_paths],
        },
        "backlog": {
            "words": len(merged_words) - len(imported_word_ids),
            "kanji": len(merged_kanji) - len(imported_kanji_ids),
            "valid_words": len(valid_words),
            "valid_kanji": len(valid_kanji),
            "word_exclusions": dict(word_exclusions),
            "kanji_exclusions": dict(kanji_exclusions),
        },
        "selected": {
            "words": len(selected_words),
            "kanji": len(selected_kanji),
            "word_coverage": dict(word_coverage),
            "selected_kanji_with_word_frequency": sum(
                1 for row in selected_kanji if frequency.get(str(row.get("character") or ""), 0) > 0
            ),
            "tag_counts": {
                "words": normalized_tag_counts(selected_words),
                "kanji": normalized_tag_counts(selected_kanji),
                "kanji_with_derived_tags": len(derived_kanji_tags),
            },
        },
        "preflight": gate,
        "samples": {
            "words": [compact_word_sample(row) for row in sample_rows(selected_words)],
            "kanji": [compact_kanji_sample(row) for row in sample_rows(selected_kanji)],
        },
    }

    write_json(args.output_dir / "recommended_v2_words.json", {"words": selected_words})
    write_json(args.output_dir / "recommended_v2_kanji.json", {"kanji": selected_kanji})
    write_json(args.output_dir / "recommended_v2_selection_report.json", report)
    write_json(args.output_dir / "recommended_v2_tag_backfill_report.json", tag_backfill_report(imported_words, imported_kanji))
    print(
        f"selected v2 words={len(selected_words)} kanji={len(selected_kanji)} "
        f"preflight_failed={gate['failed']}"
    )
    if gate["failed"]:
        raise SystemExit(1)


if __name__ == "__main__":
    main()
