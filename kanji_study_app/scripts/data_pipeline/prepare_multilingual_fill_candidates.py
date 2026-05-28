#!/usr/bin/env python3
"""Select rows that still need KANJI-11 multilingual fields."""

from __future__ import annotations

import argparse
from collections import Counter
from pathlib import Path
from typing import Any

from common import DEFAULT_OUTPUT_DIR, read_json, write_json
from generate_jp_word_meanings import has_japanese as has_japanese_text
from generate_kanji_multilang_content import backfill_row, has_english, has_japanese, missing_fields


def rows_from_json(path: Path, key: str) -> list[dict[str, Any]]:
    data = read_json(path)
    if isinstance(data, list):
        return data
    if isinstance(data, dict) and isinstance(data.get(key), list):
        return data[key]
    raise ValueError(f"input JSON must be a list or contain a '{key}' list")


def has_word_meanings_jp(row: dict[str, Any]) -> bool:
    meanings = row.get("meanings_jp") or []
    return bool(meanings) and any(
        has_japanese_text(meaning.get("meaning") if isinstance(meaning, dict) else meaning)
        for meaning in meanings
    )


def word_candidates(rows: list[dict[str, Any]]) -> list[dict[str, Any]]:
    candidates = [
        row
        for row in rows
        if row.get("id") is not None
        and row.get("word")
        and row.get("reading")
        and not has_word_meanings_jp(row)
        and (row.get("meanings_ko") or row.get("meanings") or row.get("meanings_en"))
    ]
    return sorted(candidates, key=lambda row: row.get("id") or 0)


def kanji_candidates(rows: list[dict[str, Any]]) -> list[dict[str, Any]]:
    candidates = []
    for row in rows:
        filled = backfill_row(row)
        fields = missing_fields(filled)
        if row.get("id") is not None and row.get("character") and fields:
            candidates.append({**filled, "missing_multilingual_fields": fields})
    return sorted(candidates, key=lambda row: row.get("id") or 0)


def duplicate_values(rows: list[dict[str, Any]], field: str) -> list[Any]:
    counts = Counter(row.get(field) for row in rows if row.get(field) is not None)
    return [value for value, count in counts.items() if count > 1]


def preflight(words: list[dict[str, Any]], kanji: list[dict[str, Any]]) -> dict[str, Any]:
    errors: list[dict[str, Any]] = []
    duplicate_word_ids = duplicate_values(words, "id")
    duplicate_kanji_ids = duplicate_values(kanji, "id")
    if duplicate_word_ids:
        errors.append({"type": "duplicate_word_candidate_ids", "ids": duplicate_word_ids[:50]})
    if duplicate_kanji_ids:
        errors.append({"type": "duplicate_kanji_candidate_ids", "ids": duplicate_kanji_ids[:50]})
    return {
        "failed": bool(errors),
        "errors": errors,
        "totals": {"words": len(words), "kanji": len(kanji)},
        "kanji_missing_fields": dict(sorted(Counter(field for row in kanji for field in row["missing_multilingual_fields"]).items())),
    }


def report_for(all_words: list[dict[str, Any]], all_kanji: list[dict[str, Any]], words: list[dict[str, Any]], kanji: list[dict[str, Any]]) -> dict[str, Any]:
    return {
        "input": {"words": len(all_words), "kanji": len(all_kanji)},
        "candidates": {"words": len(words), "kanji": len(kanji)},
        "already_filled": {
            "words_meanings_jp": sum(1 for row in all_words if has_word_meanings_jp(row)),
            "kanji_jp_meanings": sum(1 for row in all_kanji if row.get("jp_meanings")),
            "kanji_jp_commentary": sum(1 for row in all_kanji if has_japanese(row.get("jp_commentary"))),
            "kanji_en_commentary": sum(1 for row in all_kanji if has_english(row.get("en_commentary"))),
        },
        "preflight": preflight(words, kanji),
    }


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--words", type=Path, required=True, help="Current Supabase words export JSON")
    parser.add_argument("--kanji", type=Path, required=True, help="Current Supabase kanji export JSON")
    parser.add_argument("--output-dir", type=Path, default=DEFAULT_OUTPUT_DIR / "kanji11-full")
    args = parser.parse_args()

    all_words = rows_from_json(args.words, "words")
    all_kanji = rows_from_json(args.kanji, "kanji")
    words = word_candidates(all_words)
    kanji = kanji_candidates(all_kanji)
    report = report_for(all_words, all_kanji, words, kanji)

    write_json(args.output_dir / "words_missing_jp_meanings.json", {"words": words})
    write_json(args.output_dir / "kanji_missing_multilingual_content.json", {"kanji": kanji})
    write_json(args.output_dir / "multilingual_fill_candidate_report.json", report)
    print(
        f"multilingual fill candidates words={len(words)} kanji={len(kanji)} "
        f"failed={report['preflight']['failed']} -> {args.output_dir}"
    )
    if report["preflight"]["failed"]:
        raise SystemExit(1)


if __name__ == "__main__":
    main()
