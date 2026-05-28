#!/usr/bin/env python3
"""Post-check KANJI-11 multilingual patch application."""

from __future__ import annotations

import argparse
import hashlib
from pathlib import Path
from typing import Any

from common import DEFAULT_OUTPUT_DIR, read_json, write_json
from generate_jp_word_meanings import has_japanese as word_has_japanese
from generate_kanji_multilang_content import has_english, has_japanese


PROTECTED_WORD_FIELDS = ("meanings", "meanings_ko", "meanings_en")
PROTECTED_KANJI_FIELDS = ("meanings", "meanings_ko", "meanings_en", "commentary", "kr_commentary", "tags")


def rows_from_json(path: Path, key: str) -> list[dict[str, Any]]:
    data = read_json(path)
    if isinstance(data, list):
        return data
    if isinstance(data, dict) and isinstance(data.get(key), list):
        return data[key]
    raise ValueError(f"input JSON must be a list or contain a '{key}' list")


def by_id(rows: list[dict[str, Any]]) -> dict[int, dict[str, Any]]:
    return {int(row["id"]): row for row in rows if row.get("id") is not None}


def stable_hash(value: Any) -> str:
    import json

    return hashlib.sha256(json.dumps(value, ensure_ascii=False, sort_keys=True).encode("utf-8")).hexdigest()


def word_has_jp(row: dict[str, Any]) -> bool:
    meanings = row.get("meanings_jp") or []
    return bool(meanings) and any(
        word_has_japanese(meaning.get("meaning") if isinstance(meaning, dict) else meaning)
        for meaning in meanings
    )


def protected_changes(before: dict[int, dict[str, Any]], after: dict[int, dict[str, Any]], ids: set[int], fields: tuple[str, ...]) -> list[dict[str, Any]]:
    changes: list[dict[str, Any]] = []
    for row_id in sorted(ids):
        old = before.get(row_id)
        new = after.get(row_id)
        if not old or not new:
            continue
        changed = [field for field in fields if stable_hash(old.get(field)) != stable_hash(new.get(field))]
        if changed:
            changes.append({"id": row_id, "fields": changed})
    return changes


def build_report(
    before_words: list[dict[str, Any]],
    before_kanji: list[dict[str, Any]],
    after_words: list[dict[str, Any]],
    after_kanji: list[dict[str, Any]],
    patch_report: dict[str, Any],
) -> dict[str, Any]:
    before_words_by_id = by_id(before_words)
    before_kanji_by_id = by_id(before_kanji)
    after_words_by_id = by_id(after_words)
    after_kanji_by_id = by_id(after_kanji)
    word_patch_ids = {int(row["id"]) for row in patch_report["words"]["patches"]}
    kanji_patch_ids = {int(row["id"]) for row in patch_report["kanji"]["patches"]}

    missing_word_ids = [row_id for row_id in sorted(word_patch_ids) if not word_has_jp(after_words_by_id.get(row_id, {}))]
    missing_kanji_ids = [
        row_id
        for row_id in sorted(kanji_patch_ids)
        if not after_kanji_by_id.get(row_id, {}).get("jp_meanings")
        or not has_japanese(after_kanji_by_id.get(row_id, {}).get("jp_commentary"))
        or not has_english(after_kanji_by_id.get(row_id, {}).get("en_commentary"))
    ]
    word_protected = protected_changes(before_words_by_id, after_words_by_id, word_patch_ids, PROTECTED_WORD_FIELDS)
    kanji_protected = protected_changes(before_kanji_by_id, after_kanji_by_id, kanji_patch_ids, PROTECTED_KANJI_FIELDS)
    errors = []
    if missing_word_ids:
        errors.append({"type": "patched_words_still_missing_meanings_jp", "ids": missing_word_ids[:100]})
    if missing_kanji_ids:
        errors.append({"type": "patched_kanji_still_missing_multilingual_content", "ids": missing_kanji_ids[:100]})
    if word_protected:
        errors.append({"type": "protected_word_fields_changed", "items": word_protected[:100]})
    if kanji_protected:
        errors.append({"type": "protected_kanji_fields_changed", "items": kanji_protected[:100]})
    return {
        "failed": bool(errors),
        "errors": errors,
        "summary": {
            "word_patch_count": len(word_patch_ids),
            "kanji_patch_count": len(kanji_patch_ids),
            "patched_words_still_missing": len(missing_word_ids),
            "patched_kanji_still_missing": len(missing_kanji_ids),
            "protected_word_field_changes": len(word_protected),
            "protected_kanji_field_changes": len(kanji_protected),
        },
        "samples": {
            "words": [after_words_by_id[row_id] for row_id in sorted(word_patch_ids)[:50] if row_id in after_words_by_id],
            "kanji": [after_kanji_by_id[row_id] for row_id in sorted(kanji_patch_ids)[:50] if row_id in after_kanji_by_id],
        },
    }


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--before-words", type=Path, required=True)
    parser.add_argument("--before-kanji", type=Path, required=True)
    parser.add_argument("--after-words", type=Path, required=True)
    parser.add_argument("--after-kanji", type=Path, required=True)
    parser.add_argument("--patch-report", type=Path, required=True)
    parser.add_argument("--output-dir", type=Path, default=DEFAULT_OUTPUT_DIR / "kanji11-full")
    args = parser.parse_args()

    report = build_report(
        rows_from_json(args.before_words, "words"),
        rows_from_json(args.before_kanji, "kanji"),
        rows_from_json(args.after_words, "words"),
        rows_from_json(args.after_kanji, "kanji"),
        read_json(args.patch_report),
    )
    write_json(args.output_dir / "post_multilingual_fill_check_report.json", report)
    print(f"post-check failed={report['failed']} -> {args.output_dir / 'post_multilingual_fill_check_report.json'}")
    if report["failed"]:
        raise SystemExit(1)


if __name__ == "__main__":
    main()
