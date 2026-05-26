#!/usr/bin/env python3
"""Dry-run or apply merged datasets to Supabase."""

from __future__ import annotations

import argparse
import os
from pathlib import Path
from typing import Any

from common import DEFAULT_OUTPUT_DIR, read_json, write_json


def load_client():
    try:
        from supabase import create_client
    except ModuleNotFoundError as error:
        raise RuntimeError(
            "supabase 패키지가 필요합니다. `pip install -r scripts/requirements.txt` 실행 후 다시 시도하세요."
        ) from error

    url = os.getenv("SUPABASE_URL")
    key = os.getenv("SUPABASE_SERVICE_ROLE_KEY") or os.getenv("SUPABASE_ANON_KEY")
    if not url or not key:
        raise RuntimeError("SUPABASE_URL and SUPABASE_SERVICE_ROLE_KEY or SUPABASE_ANON_KEY are required")
    return create_client(url, key)


def _rows(path: Path, key: str) -> list[dict[str, Any]]:
    data = read_json(path)
    if isinstance(data, list):
        return data
    return data[key]


def prepare_word(row: dict[str, Any]) -> dict[str, Any]:
    return {
        "id": row["id"],
        "word": row["word"],
        "reading": row["reading"],
        "meanings": row.get("meanings") or [],
        "jlpt_level": row.get("jlpt_level", 0),
        "source": row.get("source") or "legacy_naver",
        "external_id": row.get("external_id"),
        "source_version": row.get("source_version"),
        "quality_status": row.get("quality_status") or "reviewed",
        "meaning_source": row.get("meaning_source") or "legacy_naver",
        "is_common": bool(row.get("is_common", False)),
        "priority_rank": row.get("priority_rank"),
        "tags": row.get("tags") or [],
        "updated_at": row.get("updated_at"),
    }


def prepare_kanji(row: dict[str, Any]) -> dict[str, Any]:
    readings = row.get("readings") or {}
    return {
        "id": row["id"],
        "character": row["character"],
        "meanings": row.get("meanings") or [],
        "on_readings": readings.get("on") or [],
        "kun_readings": readings.get("kun") or [],
        "korean_on_readings": row.get("korean_on_readings") or [],
        "korean_kun_readings": row.get("korean_kun_readings") or [],
        "grade": row.get("grade", 0),
        "jlpt": row.get("jlpt", 0),
        "stroke_count": row.get("strokeCount", 0),
        "radical": row.get("radical"),
        "commentary": row.get("commentary"),
        "source": row.get("source") or "legacy_excel",
        "external_id": row.get("external_id"),
        "source_version": row.get("source_version"),
        "quality_status": row.get("quality_status") or "reviewed",
        "meaning_source": row.get("meaning_source") or "legacy_excel",
        "is_common": bool(row.get("is_common", False)),
        "priority_rank": row.get("priority_rank"),
        "tags": row.get("tags") or [],
        "updated_at": row.get("updated_at"),
    }


def batched(rows: list[dict[str, Any]], size: int):
    for index in range(0, len(rows), size):
        yield rows[index:index + size]


def upsert_rows(client, table: str, rows: list[dict[str, Any]], batch_size: int) -> int:
    total = 0
    for batch in batched(rows, batch_size):
        response = client.table(table).upsert(batch, on_conflict="id").execute()
        total += len(response.data or batch)
    return total


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--words", type=Path, help="merged_words.json")
    parser.add_argument("--kanji", type=Path, help="merged_kanji.json")
    parser.add_argument("--apply", action="store_true", help="실제로 Supabase에 upsert")
    parser.add_argument("--batch-size", type=int, default=100)
    parser.add_argument("--report", type=Path, default=DEFAULT_OUTPUT_DIR / "import_report.json")
    args = parser.parse_args()

    words = [prepare_word(row) for row in _rows(args.words, "words")] if args.words else []
    kanji = [prepare_kanji(row) for row in _rows(args.kanji, "kanji")] if args.kanji else []
    report = {
        "dry_run": not args.apply,
        "words": {"count": len(words), "first_ids": [row["id"] for row in words[:5]]},
        "kanji": {"count": len(kanji), "first_ids": [row["id"] for row in kanji[:5]]},
    }

    if args.apply:
        client = load_client()
        if words:
            report["words"]["upserted"] = upsert_rows(client, "words", words, args.batch_size)
        if kanji:
            report["kanji"]["upserted"] = upsert_rows(client, "kanji", kanji, args.batch_size)

    write_json(args.report, report)
    print(f"{'applied' if args.apply else 'dry-run'} words={len(words)} kanji={len(kanji)} -> {args.report}")


if __name__ == "__main__":
    main()
