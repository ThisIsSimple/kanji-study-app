#!/usr/bin/env python3
"""Merge KANJI-11 multilingual generation shard outputs."""

from __future__ import annotations

import argparse
from collections import Counter
from pathlib import Path
from typing import Any

from common import DEFAULT_OUTPUT_DIR, read_json, write_json
from generate_jp_word_meanings import preflight as word_preflight
from generate_kanji_multilang_content import preflight as kanji_preflight


def rows_from_json(path: Path, key: str) -> list[dict[str, Any]]:
    data = read_json(path)
    if isinstance(data, list):
        return data
    if isinstance(data, dict) and isinstance(data.get(key), list):
        return data[key]
    raise ValueError(f"input JSON must be a list or contain a '{key}' list")


def merge_rows(paths: list[Path], key: str) -> list[dict[str, Any]]:
    rows: list[dict[str, Any]] = []
    for path in paths:
        rows.extend(rows_from_json(path, key))
    return sorted(rows, key=lambda row: row.get("id") or 0)


def duplicate_ids(rows: list[dict[str, Any]]) -> list[int]:
    counts = Counter(row.get("id") for row in rows)
    return [int(row_id) for row_id, count in counts.items() if row_id is not None and count > 1]


def build_report(words: list[dict[str, Any]], kanji: list[dict[str, Any]], expected_words: int | None, expected_kanji: int | None) -> dict[str, Any]:
    errors: list[dict[str, Any]] = []
    word_duplicates = duplicate_ids(words)
    kanji_duplicates = duplicate_ids(kanji)
    if word_duplicates:
        errors.append({"type": "duplicate_word_ids", "ids": word_duplicates[:50]})
    if kanji_duplicates:
        errors.append({"type": "duplicate_kanji_ids", "ids": kanji_duplicates[:50]})
    word_report = word_preflight(words, expected_words)
    kanji_report = kanji_preflight(kanji, expected_kanji)
    errors.extend({"scope": "words", **error} for error in word_report["errors"])
    errors.extend({"scope": "kanji", **error} for error in kanji_report["errors"])
    return {
        "failed": bool(errors),
        "errors": errors,
        "totals": {"words": len(words), "kanji": len(kanji)},
        "expected": {"words": expected_words, "kanji": expected_kanji},
    }


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--word-shard", type=Path, action="append", default=[])
    parser.add_argument("--kanji-shard", type=Path, action="append", default=[])
    parser.add_argument("--expected-words", type=int)
    parser.add_argument("--expected-kanji", type=int)
    parser.add_argument("--output-dir", type=Path, default=DEFAULT_OUTPUT_DIR / "kanji11-full")
    parser.add_argument("--word-output", default="words_jp_meanings_full.json")
    parser.add_argument("--kanji-output", default="kanji_multilang_full.json")
    args = parser.parse_args()

    words = merge_rows(args.word_shard, "words") if args.word_shard else []
    kanji = merge_rows(args.kanji_shard, "kanji") if args.kanji_shard else []
    report = build_report(words, kanji, args.expected_words, args.expected_kanji)
    if args.word_shard:
        write_json(args.output_dir / args.word_output, {"words": words})
    if args.kanji_shard:
        write_json(args.output_dir / args.kanji_output, {"kanji": kanji})
    write_json(args.output_dir / "multilingual_fill_merge_report.json", report)
    print(f"merged words={len(words)} kanji={len(kanji)} failed={report['failed']} -> {args.output_dir}")
    if report["failed"]:
        raise SystemExit(1)


if __name__ == "__main__":
    main()
