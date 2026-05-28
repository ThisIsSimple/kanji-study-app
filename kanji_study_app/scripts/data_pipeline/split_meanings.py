#!/usr/bin/env python3
"""Split Korean display meanings from English source glosses."""

from __future__ import annotations

import argparse
import re
from collections import Counter, defaultdict
from pathlib import Path
from typing import Any

from common import QUALITY_AI_DRAFT, add_common_output_args, dedupe, dedupe_meanings, read_json, write_json
from generate_ko_meaning_drafts import draft_key, load_checkpoint_mapping


HANGUL_RE = re.compile(r"[가-힣]")


def has_korean(value: Any) -> bool:
    return bool(HANGUL_RE.search(str(value or "")))


def _rows(data: Any, key: str) -> list[dict[str, Any]]:
    if isinstance(data, list):
        return data
    if isinstance(data, dict) and isinstance(data.get(key), list):
        return data[key]
    raise ValueError(f"JSON must be a list or contain '{key}'")


def _word_meaning_text(meaning: dict[str, Any]) -> str:
    return str(meaning.get("meaning") or "").strip()


def split_word_meanings(
    row: dict[str, Any],
    checkpoint_mapping: dict[str, list[str]],
) -> tuple[list[dict[str, Any]], list[dict[str, Any]], str]:
    raw_meanings = row.get("meanings") or []
    korean_meanings = [meaning for meaning in raw_meanings if has_korean(_word_meaning_text(meaning))]
    english_meanings = [meaning for meaning in raw_meanings if not has_korean(_word_meaning_text(meaning))]
    meaning_source = row.get("meaning_source") or "legacy_naver"

    if not korean_meanings:
        drafts = checkpoint_mapping.get(draft_key(row)) or checkpoint_mapping.get(
            f"{row.get('word')}|{row.get('reading')}"
        )
        if drafts:
            pos = raw_meanings[0].get("part_of_speech", "") if raw_meanings else ""
            korean_meanings = [
                {
                    "part_of_speech": pos,
                    "meaning": draft,
                    "source": "ai_translation",
                    "quality_status": QUALITY_AI_DRAFT,
                }
                for draft in drafts
                if has_korean(draft)
            ]
            meaning_source = "ai_translation"

    return dedupe_meanings(korean_meanings), dedupe_meanings(english_meanings), meaning_source


def split_words(
    rows: list[dict[str, Any]],
    checkpoint_mapping: dict[str, list[str]],
) -> tuple[list[dict[str, Any]], dict[str, Any]]:
    result: list[dict[str, Any]] = []
    excluded: list[dict[str, Any]] = []
    for row in rows:
        meanings_ko, meanings_en, meaning_source = split_word_meanings(row, checkpoint_mapping)
        if not meanings_ko:
            excluded.append({"id": row.get("id"), "word": row.get("word"), "reading": row.get("reading")})
            continue
        result.append(
            {
                **row,
                "meanings": meanings_ko,
                "meanings_ko": meanings_ko,
                "meanings_en": meanings_en,
                "meaning_source": meaning_source,
            }
        )
    return result, {"excluded_no_korean": excluded}


def split_kanji(rows: list[dict[str, Any]]) -> tuple[list[dict[str, Any]], dict[str, Any]]:
    result: list[dict[str, Any]] = []
    excluded: list[dict[str, Any]] = []
    for row in rows:
        meanings = [str(meaning).strip() for meaning in row.get("meanings") or [] if str(meaning).strip()]
        meanings_ko = dedupe(meaning for meaning in meanings if has_korean(meaning))
        meanings_en = dedupe(meaning for meaning in meanings if not has_korean(meaning))
        if not meanings_ko:
            excluded.append({"id": row.get("id"), "character": row.get("character"), "meanings_en": meanings_en})
            continue
        result.append({**row, "meanings": meanings_ko, "meanings_ko": meanings_ko, "meanings_en": meanings_en})
    return result, {"excluded_no_korean": excluded}


def duplicate_groups(rows: list[dict[str, Any]], key: str | tuple[str, str]) -> dict[Any, list[dict[str, Any]]]:
    groups: dict[Any, list[dict[str, Any]]] = defaultdict(list)
    for row in rows:
        if isinstance(key, tuple):
            group_key = tuple(row.get(part) for part in key)
        else:
            group_key = row.get(key)
        if group_key:
            groups[group_key].append(row)
    return {group_key: group_rows for group_key, group_rows in groups.items() if len(group_rows) > 1}


def existing_duplicate_keys(existing_rows: list[dict[str, Any]], key: str | tuple[str, str]) -> set[Any]:
    return set(duplicate_groups(existing_rows, key).keys())


def has_english_only_meaning(value: Any) -> bool:
    if isinstance(value, list):
        for item in value:
            if isinstance(item, dict):
                text = item.get("meaning")
            else:
                text = item
            if str(text or "").strip() and not has_korean(text):
                return True
    return False


def preflight_report(
    words: list[dict[str, Any]],
    kanji: list[dict[str, Any]],
    existing_words: list[dict[str, Any]],
    existing_kanji: list[dict[str, Any]],
) -> dict[str, Any]:
    errors: list[dict[str, Any]] = []
    warnings: list[dict[str, Any]] = []

    duplicate_word_ids = [key for key, count in Counter(row.get("id") for row in words).items() if count > 1]
    duplicate_word_external_ids = [
        key for key, count in Counter(row.get("external_id") for row in words if row.get("external_id")).items() if count > 1
    ]
    duplicate_kanji_ids = [key for key, count in Counter(row.get("id") for row in kanji).items() if count > 1]

    for name, values in (
        ("duplicate_word_ids", duplicate_word_ids),
        ("duplicate_word_external_ids", duplicate_word_external_ids),
        ("duplicate_kanji_ids", duplicate_kanji_ids),
    ):
        if values:
            errors.append({"type": name, "values": values[:50]})

    existing_word_duplicate_keys = existing_duplicate_keys(existing_words, ("word", "reading"))
    for group_key, group_rows in duplicate_groups(words, ("word", "reading")).items():
        payload = {"word": group_key[0], "reading": group_key[1], "ids": [row.get("id") for row in group_rows]}
        if group_key in existing_word_duplicate_keys:
            warnings.append({"type": "existing_word_reading_duplicate", **payload})
        else:
            errors.append({"type": "new_word_reading_duplicate", **payload})

    existing_kanji_duplicate_keys = existing_duplicate_keys(existing_kanji, "character")
    for group_key, group_rows in duplicate_groups(kanji, "character").items():
        payload = {"character": group_key, "ids": [row.get("id") for row in group_rows]}
        if group_key in existing_kanji_duplicate_keys:
            warnings.append({"type": "existing_kanji_character_duplicate", **payload})
        else:
            errors.append({"type": "new_kanji_character_duplicate", **payload})

    bad_word_meanings = [
        row.get("id") for row in words if has_english_only_meaning(row.get("meanings")) or has_english_only_meaning(row.get("meanings_ko"))
    ]
    bad_kanji_meanings = [
        row.get("id") for row in kanji if has_english_only_meaning(row.get("meanings")) or has_english_only_meaning(row.get("meanings_ko"))
    ]
    if bad_word_meanings:
        errors.append({"type": "word_korean_meanings_contain_english_only", "ids": bad_word_meanings[:50]})
    if bad_kanji_meanings:
        errors.append({"type": "kanji_korean_meanings_contain_english_only", "ids": bad_kanji_meanings[:50]})

    missing_word_english = [
        row.get("id")
        for row in words
        if row.get("source") == "jmdict" and not row.get("meanings_en")
    ]
    missing_kanji_english = [
        row.get("id")
        for row in kanji
        if row.get("source") in {"kanjidic2", "legacy_excel"} and row.get("external_id") and not row.get("meanings_en")
    ]
    if missing_word_english:
        warnings.append({"type": "jmdict_rows_missing_english_gloss", "ids": missing_word_english[:50]})
    if missing_kanji_english:
        warnings.append({"type": "kanjidic_rows_missing_english_gloss", "ids": missing_kanji_english[:50]})

    return {
        "failed": bool(errors),
        "errors": errors,
        "warnings": warnings,
        "totals": {"words": len(words), "kanji": len(kanji)},
    }


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--words", type=Path, required=True)
    parser.add_argument("--kanji", type=Path, required=True)
    parser.add_argument("--existing-words", type=Path)
    parser.add_argument("--existing-kanji", type=Path)
    parser.add_argument("--checkpoint-provider", default="codex-cli")
    parser.add_argument("--checkpoint-model", default="")
    add_common_output_args(parser)
    args = parser.parse_args()

    checkpoint_mapping = load_checkpoint_mapping(args.output_dir, args.checkpoint_provider, args.checkpoint_model)
    words, word_report = split_words(_rows(read_json(args.words), "words"), checkpoint_mapping)
    kanji, kanji_report = split_kanji(_rows(read_json(args.kanji), "kanji"))
    existing_words = _rows(read_json(args.existing_words), "words") if args.existing_words else []
    existing_kanji = _rows(read_json(args.existing_kanji), "kanji") if args.existing_kanji else []
    preflight = preflight_report(words, kanji, existing_words, existing_kanji)

    report = {
        "checkpoint_translations": len(checkpoint_mapping),
        "words": word_report,
        "kanji": kanji_report,
        "preflight": preflight,
    }
    write_json(args.output_dir / "recommended_v1_words_split_meanings.json", {"words": words})
    write_json(args.output_dir / "recommended_v1_kanji_split_meanings.json", {"kanji": kanji})
    write_json(args.output_dir / "split_meanings_report.json", report)
    print(
        f"split meanings words={len(words)} kanji={len(kanji)} "
        f"failed={preflight['failed']} -> {args.output_dir}"
    )


if __name__ == "__main__":
    main()
