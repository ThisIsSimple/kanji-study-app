#!/usr/bin/env python3
"""Merge existing Supabase exports with normalized open-license datasets."""

from __future__ import annotations

import argparse
from pathlib import Path
from typing import Any

from common import (
    QUALITY_AI_DRAFT,
    QUALITY_REVIEWED,
    SOURCE_LEGACY_EXCEL,
    SOURCE_LEGACY_NAVER,
    add_common_output_args,
    dedupe,
    dedupe_meanings,
    meaning_tokens,
    normalize_text,
    read_json,
    write_json,
)


def _rows(data: Any, key: str) -> list[dict[str, Any]]:
    if isinstance(data, list):
        return data
    if isinstance(data, dict):
        value = data.get(key)
        if isinstance(value, list):
            return value
    raise ValueError(f"JSON must be a list or contain '{key}'")


def _word_key(row: dict[str, Any]) -> tuple[str, str]:
    return (normalize_text(row.get("word")).casefold(), normalize_text(row.get("reading")).casefold())


def _word_defaults(row: dict[str, Any]) -> dict[str, Any]:
    return {
        **row,
        "source": row.get("source") or SOURCE_LEGACY_NAVER,
        "external_id": row.get("external_id"),
        "source_version": row.get("source_version"),
        "quality_status": row.get("quality_status") or QUALITY_REVIEWED,
        "meaning_source": row.get("meaning_source") or SOURCE_LEGACY_NAVER,
        "is_common": bool(row.get("is_common", False)),
        "priority_rank": row.get("priority_rank"),
        "tags": dedupe(row.get("tags") or []),
    }


def _kanji_defaults(row: dict[str, Any]) -> dict[str, Any]:
    return {
        **row,
        "source": row.get("source") or SOURCE_LEGACY_EXCEL,
        "external_id": row.get("external_id"),
        "source_version": row.get("source_version"),
        "quality_status": row.get("quality_status") or QUALITY_REVIEWED,
        "meaning_source": row.get("meaning_source") or SOURCE_LEGACY_EXCEL,
        "is_common": bool(row.get("is_common", False)),
        "priority_rank": row.get("priority_rank"),
        "tags": dedupe(row.get("tags") or []),
    }


def _merge_word(existing: dict[str, Any], incoming: dict[str, Any]) -> dict[str, Any]:
    merged = dict(existing)
    merged["meanings"] = dedupe_meanings([*(existing.get("meanings") or []), *(incoming.get("meanings") or [])])
    merged["tags"] = dedupe([*(existing.get("tags") or []), *(incoming.get("tags") or [])])
    if not merged.get("external_id") and incoming.get("external_id"):
        merged["external_id"] = incoming["external_id"]
    if not merged.get("source_version") and incoming.get("source_version"):
        merged["source_version"] = incoming["source_version"]
    if incoming.get("is_common"):
        merged["is_common"] = True
    incoming_rank = incoming.get("priority_rank")
    if incoming_rank is not None:
        current_rank = merged.get("priority_rank")
        merged["priority_rank"] = incoming_rank if current_rank is None else min(current_rank, incoming_rank)
    return merged


def _word_similarity_match(
    incoming: dict[str, Any],
    by_surface: dict[str, list[dict[str, Any]]],
) -> dict[str, Any] | None:
    candidates = by_surface.get(normalize_text(incoming.get("word")).casefold(), [])
    incoming_tokens = meaning_tokens(incoming.get("meanings") or [])
    incoming_pos = {normalize_text(m.get("part_of_speech")).casefold() for m in incoming.get("meanings") or []}
    for candidate in candidates:
        candidate_tokens = meaning_tokens(candidate.get("meanings") or [])
        if incoming_tokens and candidate_tokens and incoming_tokens & candidate_tokens:
            return candidate
        candidate_pos = {normalize_text(m.get("part_of_speech")).casefold() for m in candidate.get("meanings") or []}
        if incoming_pos and candidate_pos and incoming_pos & candidate_pos:
            return candidate
    return None


def merge_words(existing_rows: list[dict[str, Any]], incoming_rows: list[dict[str, Any]]) -> tuple[list[dict[str, Any]], dict]:
    merged = [_word_defaults(row) for row in existing_rows]
    next_id = max([int(row.get("id", 0)) for row in merged] or [0]) + 1
    by_key = {_word_key(row): row for row in merged}
    by_external = {
        row["external_id"]: row
        for row in merged
        if row.get("external_id")
    }
    by_surface: dict[str, list[dict[str, Any]]] = {}
    for row in merged:
        by_surface.setdefault(normalize_text(row.get("word")).casefold(), []).append(row)

    report = {"existing": len(merged), "incoming": len(incoming_rows), "added": 0, "merged": 0, "conflicts": []}
    for raw in incoming_rows:
        incoming = _word_defaults(raw)
        target = by_key.get(_word_key(incoming))
        if target is None and incoming.get("external_id"):
            target = by_external.get(incoming["external_id"])
        if target is None:
            target = _word_similarity_match(incoming, by_surface)
        if target is not None:
            before_meaning_count = len(target.get("meanings") or [])
            updated = _merge_word(target, incoming)
            target.update(updated)
            report["merged"] += 1
            if len(target.get("meanings") or []) == before_meaning_count and _word_key(target) != _word_key(incoming):
                report["conflicts"].append({"existing_id": target.get("id"), "incoming": incoming.get("word")})
            continue

        incoming["id"] = next_id
        next_id += 1
        merged.append(incoming)
        by_key[_word_key(incoming)] = incoming
        if incoming.get("external_id"):
            by_external[incoming["external_id"]] = incoming
        by_surface.setdefault(normalize_text(incoming.get("word")).casefold(), []).append(incoming)
        report["added"] += 1
    return merged, report


def _merge_kanji(existing: dict[str, Any], incoming: dict[str, Any]) -> dict[str, Any]:
    merged = dict(existing)
    merged["meanings"] = dedupe([*(existing.get("meanings") or []), *(incoming.get("meanings") or [])])
    merged["korean_on_readings"] = dedupe(
        [*(existing.get("korean_on_readings") or []), *(incoming.get("korean_on_readings") or [])]
    )
    merged["korean_kun_readings"] = dedupe(
        [*(existing.get("korean_kun_readings") or []), *(incoming.get("korean_kun_readings") or [])]
    )
    readings = existing.get("readings") or {}
    incoming_readings = incoming.get("readings") or {}
    merged["readings"] = {
        "on": dedupe([*(readings.get("on") or []), *(incoming_readings.get("on") or [])]),
        "kun": dedupe([*(readings.get("kun") or []), *(incoming_readings.get("kun") or [])]),
    }
    merged["tags"] = dedupe([*(existing.get("tags") or []), *(incoming.get("tags") or [])])
    for key in ("radical", "commentary", "external_id", "source_version"):
        if not merged.get(key) and incoming.get(key):
            merged[key] = incoming[key]
    if incoming.get("is_common"):
        merged["is_common"] = True
    return merged


def merge_kanji(existing_rows: list[dict[str, Any]], incoming_rows: list[dict[str, Any]]) -> tuple[list[dict[str, Any]], dict]:
    merged = [_kanji_defaults(row) for row in existing_rows]
    next_id = max([int(row.get("id", 0)) for row in merged] or [0]) + 1
    by_character = {row.get("character"): row for row in merged}
    report = {"existing": len(merged), "incoming": len(incoming_rows), "added": 0, "merged": 0, "conflicts": []}

    for raw in incoming_rows:
        incoming = _kanji_defaults(raw)
        character = incoming.get("character")
        if not character:
            continue
        target = by_character.get(character)
        if target is not None:
            target.update(_merge_kanji(target, incoming))
            report["merged"] += 1
            continue
        incoming["id"] = next_id
        next_id += 1
        merged.append(incoming)
        by_character[character] = incoming
        report["added"] += 1
    return merged, report


def quality_report(words: list[dict[str, Any]], kanji: list[dict[str, Any]], merge_report: dict) -> dict:
    invalid_jlpt = [row.get("id") for row in words if row.get("jlpt_level") not in {0, 1, 2, 3, 4, 5}]
    empty_words = [row.get("id") for row in words if not row.get("word") or not row.get("reading")]
    empty_word_meanings = [row.get("id") for row in words if not row.get("meanings")]
    empty_kanji = [row.get("id") for row in kanji if not row.get("character")]
    empty_kanji_meanings = [row.get("id") for row in kanji if not row.get("meanings")]
    return {
        **merge_report,
        "totals": {"words": len(words), "kanji": len(kanji)},
        "ai_draft": {
            "words": sum(1 for row in words if row.get("quality_status") == QUALITY_AI_DRAFT),
            "kanji": sum(1 for row in kanji if row.get("quality_status") == QUALITY_AI_DRAFT),
        },
        "invalid": {
            "word_ids_with_invalid_jlpt": invalid_jlpt[:100],
            "word_ids_empty_word_or_reading": empty_words[:100],
            "word_ids_empty_meanings": empty_word_meanings[:100],
            "kanji_ids_empty_character": empty_kanji[:100],
            "kanji_ids_empty_meanings": empty_kanji_meanings[:100],
        },
        "samples": {
            "new_words": [row for row in words if row.get("quality_status") == QUALITY_AI_DRAFT][:50],
            "new_kanji": [row for row in kanji if row.get("quality_status") == QUALITY_AI_DRAFT][:50],
        },
    }


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--existing-words", type=Path, required=True)
    parser.add_argument("--existing-kanji", type=Path, required=True)
    parser.add_argument("--incoming-words", type=Path, required=True)
    parser.add_argument("--incoming-kanji", type=Path, required=True)
    add_common_output_args(parser)
    args = parser.parse_args()

    words, word_report = merge_words(_rows(read_json(args.existing_words), "words"), _rows(read_json(args.incoming_words), "words"))
    kanji, kanji_report = merge_kanji(_rows(read_json(args.existing_kanji), "kanji"), _rows(read_json(args.incoming_kanji), "kanji"))
    report = quality_report(words, kanji, {"words": word_report, "kanji": kanji_report})

    write_json(args.output_dir / "merged_words.json", {"words": words})
    write_json(args.output_dir / "merged_kanji.json", {"kanji": kanji})
    write_json(args.output_dir / "merge_report.json", report)
    print(f"merged words={len(words)} kanji={len(kanji)} -> {args.output_dir}")


if __name__ == "__main__":
    main()
