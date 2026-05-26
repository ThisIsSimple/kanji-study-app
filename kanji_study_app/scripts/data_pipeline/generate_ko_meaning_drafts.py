#!/usr/bin/env python3
"""Generate or apply Korean meaning drafts for entries without Korean meanings."""

from __future__ import annotations

import argparse
import json
import os
import re
import urllib.request
from pathlib import Path
from typing import Any

from common import QUALITY_AI_DRAFT, add_common_output_args, dedupe_meanings, read_json, write_json


HANGUL_RE = re.compile(r"[가-힣]")


def has_korean_meaning(row: dict[str, Any]) -> bool:
    return any(HANGUL_RE.search(str(meaning.get("meaning", ""))) for meaning in row.get("meanings") or [])


def draft_key(row: dict[str, Any]) -> str:
    return row.get("external_id") or f"{row.get('word')}|{row.get('reading')}"


def load_mapping(path: Path | None) -> dict[str, list[str]]:
    if not path:
        return {}
    data = read_json(path)
    if not isinstance(data, dict):
        raise ValueError("translation map must be a JSON object")
    result: dict[str, list[str]] = {}
    for key, value in data.items():
        if isinstance(value, str):
            result[key] = [value]
        elif isinstance(value, list):
            result[key] = [str(item) for item in value if str(item).strip()]
    return result


def gemini_translate(row: dict[str, Any], model: str) -> list[str]:
    api_key = os.getenv("GEMINI_API_KEY")
    if not api_key:
        return []
    glosses = [meaning.get("meaning", "") for meaning in row.get("meanings") or []]
    prompt = (
        "일본어 학습 앱에 넣을 한국어 뜻 초안을 JSON 배열로만 반환하세요. "
        "간결한 사전식 표현만 쓰고 설명 문장은 쓰지 마세요.\n"
        f"단어: {row.get('word')}\n읽기: {row.get('reading')}\n영어 뜻: {glosses}"
    )
    body = json.dumps({"contents": [{"parts": [{"text": prompt}]}]}).encode("utf-8")
    url = f"https://generativelanguage.googleapis.com/v1beta/models/{model}:generateContent?key={api_key}"
    request = urllib.request.Request(url, data=body, headers={"Content-Type": "application/json"})
    with urllib.request.urlopen(request, timeout=30) as response:
        payload = json.loads(response.read().decode("utf-8"))
    text = payload["candidates"][0]["content"]["parts"][0]["text"].strip()
    if text.startswith("```"):
        text = re.sub(r"^```(?:json)?\s*|\s*```$", "", text, flags=re.S)
    parsed = json.loads(text)
    if not isinstance(parsed, list):
        return []
    return [str(item).strip() for item in parsed if str(item).strip()]


def apply_drafts(
    words: list[dict[str, Any]],
    mapping: dict[str, list[str]],
    provider: str,
    model: str,
    limit: int | None,
) -> tuple[list[dict[str, Any]], dict[str, Any]]:
    updated = 0
    skipped = 0
    exported_prompts: list[dict[str, Any]] = []
    for row in words:
        if has_korean_meaning(row):
            skipped += 1
            continue
        if row.get("quality_status") != QUALITY_AI_DRAFT:
            skipped += 1
            continue
        if limit is not None and updated >= limit:
            break

        key = draft_key(row)
        drafts = mapping.get(key) or mapping.get(f"{row.get('word')}|{row.get('reading')}") or []
        if not drafts and provider == "gemini":
            drafts = gemini_translate(row, model)
        if not drafts:
            exported_prompts.append(
                {
                    "key": key,
                    "word": row.get("word"),
                    "reading": row.get("reading"),
                    "english_meanings": [m.get("meaning") for m in row.get("meanings") or []],
                }
            )
            continue

        pos = ""
        if row.get("meanings"):
            pos = row["meanings"][0].get("part_of_speech", "")
        row["meanings"] = dedupe_meanings(
            [
                {
                    "part_of_speech": pos,
                    "meaning": draft,
                    "source": "ai_translation",
                    "quality_status": QUALITY_AI_DRAFT,
                }
                for draft in drafts
            ]
        )
        row["meaning_source"] = "ai_translation"
        row["quality_status"] = QUALITY_AI_DRAFT
        updated += 1
    return words, {"updated": updated, "skipped": skipped, "needs_translation": exported_prompts}


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--input", type=Path, required=True, help="merged_words.json")
    parser.add_argument("--translation-map", type=Path, help="external_id 또는 word|reading -> 한국어 뜻 배열")
    parser.add_argument("--provider", choices=["none", "mapping", "gemini"], default="mapping")
    parser.add_argument("--model", default="gemini-1.5-flash")
    parser.add_argument("--limit", type=int)
    add_common_output_args(parser)
    args = parser.parse_args()

    data = read_json(args.input)
    words = data["words"]
    mapping = load_mapping(args.translation_map)
    words, report = apply_drafts(words, mapping, args.provider, args.model, args.limit)
    write_json(args.output_dir / "merged_words_with_ko_drafts.json", {"words": words})
    write_json(args.output_dir / "ko_draft_report.json", report)
    print(f"ko_drafts updated={report['updated']} needs_translation={len(report['needs_translation'])}")


if __name__ == "__main__":
    main()
