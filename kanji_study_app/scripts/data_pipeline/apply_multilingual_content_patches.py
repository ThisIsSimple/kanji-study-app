#!/usr/bin/env python3
"""Build and optionally apply KANJI-11 multilingual content patches."""

from __future__ import annotations

import argparse
import gzip
import hashlib
import json
import os
import ssl
import urllib.parse
import urllib.request
from collections import Counter
from datetime import datetime, timezone
from pathlib import Path
from typing import Any

from common import DEFAULT_OUTPUT_DIR, ensure_dir, read_json, write_json
from generate_jp_word_meanings import has_japanese as word_has_japanese
from generate_kanji_multilang_content import has_english, has_japanese


WORD_PATCH_FIELDS = {"id", "meanings_jp", "updated_at"}
KANJI_PATCH_FIELDS = {"id", "jp_meanings", "jp_commentary", "en_commentary", "updated_at"}


def rows_from_json(path: Path, key: str) -> list[dict[str, Any]]:
    data = read_json(path)
    if isinstance(data, list):
        return data
    if isinstance(data, dict) and isinstance(data.get(key), list):
        return data[key]
    raise ValueError(f"input JSON must be a list or contain a '{key}' list")


def by_id(rows: list[dict[str, Any]]) -> dict[int, dict[str, Any]]:
    return {int(row["id"]): row for row in rows if row.get("id") is not None}


def word_meanings_jp_valid(row: dict[str, Any]) -> bool:
    meanings = row.get("meanings_jp") or []
    return bool(meanings) and any(
        word_has_japanese(meaning.get("meaning") if isinstance(meaning, dict) else meaning)
        for meaning in meanings
    )


def word_patch(row: dict[str, Any], existing: dict[int, dict[str, Any]], updated_at: str) -> tuple[dict[str, Any] | None, dict[str, Any] | None]:
    row_id = row.get("id")
    if row_id is None:
        return None, {"id": None, "reason": "missing_id"}
    current = existing.get(int(row_id))
    if not current:
        return None, {"id": row_id, "reason": "id_not_found_in_existing_words"}
    if word_meanings_jp_valid(current):
        return None, {"id": row_id, "reason": "already_has_meanings_jp"}
    if not word_meanings_jp_valid(row):
        return None, {"id": row_id, "reason": "missing_or_invalid_generated_meanings_jp"}
    return {"id": int(row_id), "meanings_jp": row["meanings_jp"], "updated_at": updated_at}, None


def kanji_patch(row: dict[str, Any], existing: dict[int, dict[str, Any]], updated_at: str) -> tuple[dict[str, Any] | None, dict[str, Any] | None]:
    row_id = row.get("id")
    if row_id is None:
        return None, {"id": None, "reason": "missing_id"}
    current = existing.get(int(row_id))
    if not current:
        return None, {"id": row_id, "reason": "id_not_found_in_existing_kanji"}
    if row.get("character") and current.get("character") and row.get("character") != current.get("character"):
        return None, {"id": row_id, "reason": "character_mismatch", "expected": current.get("character"), "actual": row.get("character")}

    patch: dict[str, Any] = {"id": int(row_id), "updated_at": updated_at}
    if not current.get("jp_meanings"):
        generated = row.get("jp_meanings") or []
        if generated and any(has_japanese(value) for value in generated):
            patch["jp_meanings"] = generated
        else:
            return None, {"id": row_id, "reason": "missing_or_invalid_generated_jp_meanings"}
    if not has_japanese(current.get("jp_commentary")):
        if has_japanese(row.get("jp_commentary")):
            patch["jp_commentary"] = row.get("jp_commentary")
        else:
            return None, {"id": row_id, "reason": "missing_or_invalid_generated_jp_commentary"}
    if not has_english(current.get("en_commentary")):
        if has_english(row.get("en_commentary")):
            patch["en_commentary"] = row.get("en_commentary")
        else:
            return None, {"id": row_id, "reason": "missing_or_invalid_generated_en_commentary"}

    if set(patch) == {"id", "updated_at"}:
        return None, {"id": row_id, "reason": "already_has_multilingual_content"}
    return patch, None


def validate_patch_fields(patches: list[dict[str, Any]], allowed: set[str], scope: str) -> list[dict[str, Any]]:
    return [
        {"type": f"{scope}_patch_contains_disallowed_fields", "id": patch.get("id"), "fields": sorted(set(patch) - allowed)}
        for patch in patches
        if set(patch) - allowed
    ]


def duplicate_patch_errors(patches: list[dict[str, Any]], scope: str) -> list[dict[str, Any]]:
    duplicates = [row_id for row_id, count in Counter(patch["id"] for patch in patches).items() if count > 1]
    return [{"type": f"duplicate_{scope}_patch_ids", "ids": duplicates[:50]}] if duplicates else []


def build_dry_run(
    generated_words: list[dict[str, Any]],
    generated_kanji: list[dict[str, Any]],
    existing_words: list[dict[str, Any]],
    existing_kanji: list[dict[str, Any]],
    updated_at: str | None = None,
) -> dict[str, Any]:
    updated_at = updated_at or datetime.now(timezone.utc).isoformat()
    existing_words_by_id = by_id(existing_words)
    existing_kanji_by_id = by_id(existing_kanji)
    word_patches: list[dict[str, Any]] = []
    kanji_patches: list[dict[str, Any]] = []
    skipped_words: list[dict[str, Any]] = []
    skipped_kanji: list[dict[str, Any]] = []

    for row in generated_words:
        patch, skip = word_patch(row, existing_words_by_id, updated_at)
        if patch:
            word_patches.append(patch)
        if skip:
            skipped_words.append(skip)
    for row in generated_kanji:
        patch, skip = kanji_patch(row, existing_kanji_by_id, updated_at)
        if patch:
            kanji_patches.append(patch)
        if skip:
            skipped_kanji.append(skip)

    errors = [
        *duplicate_patch_errors(word_patches, "word"),
        *duplicate_patch_errors(kanji_patches, "kanji"),
        *validate_patch_fields(word_patches, WORD_PATCH_FIELDS, "word"),
        *validate_patch_fields(kanji_patches, KANJI_PATCH_FIELDS, "kanji"),
    ]
    return {
        "dry_run": True,
        "failed": bool(errors),
        "errors": errors,
        "updated_at": updated_at,
        "words": {"patches": word_patches, "skipped": skipped_words},
        "kanji": {"patches": kanji_patches, "skipped": skipped_kanji},
        "summary": {
            "generated_words": len(generated_words),
            "generated_kanji": len(generated_kanji),
            "word_patch_count": len(word_patches),
            "kanji_patch_count": len(kanji_patches),
            "word_skipped_count": len(skipped_words),
            "kanji_skipped_count": len(skipped_kanji),
        },
    }


def backup_inputs(words_path: Path, kanji_path: Path, backup_dir: Path) -> dict[str, Any]:
    ensure_dir(backup_dir)
    files = []
    for source_path, name in [(words_path, "words.json.gz"), (kanji_path, "kanji.json.gz")]:
        raw = source_path.read_bytes()
        target = backup_dir / name
        with gzip.GzipFile(filename="", mode="wb", fileobj=target.open("wb"), mtime=0) as handle:
            handle.write(raw)
        compressed = target.read_bytes()
        files.append(
            {
                "path": name,
                "source": str(source_path),
                "bytes_compressed": len(compressed),
                "bytes_uncompressed": len(raw),
                "sha256_compressed": hashlib.sha256(compressed).hexdigest(),
                "sha256_uncompressed": hashlib.sha256(raw).hexdigest(),
            }
        )
    manifest = {"created_at": datetime.now(timezone.utc).isoformat(), "files": files}
    write_json(backup_dir / "manifest.json", manifest)
    return manifest


def load_key() -> tuple[str, str]:
    url = os.getenv("SUPABASE_URL")
    key = os.getenv("SUPABASE_SECRET_KEY") or os.getenv("SUPABASE_SERVICE_ROLE_KEY")
    if not url or not key:
        raise RuntimeError("SUPABASE_URL and SUPABASE_SECRET_KEY or SUPABASE_SERVICE_ROLE_KEY are required for --apply")
    return url.rstrip("/"), key


def patch_row(url: str, key: str, table: str, patch: dict[str, Any]) -> None:
    row_id = patch["id"]
    body = json.dumps({field: value for field, value in patch.items() if field != "id"}).encode("utf-8")
    query = urllib.parse.urlencode({"id": f"eq.{row_id}"})
    request = urllib.request.Request(
        f"{url}/rest/v1/{table}?{query}",
        data=body,
        method="PATCH",
        headers={
            "apikey": key,
            "Authorization": f"Bearer {key}",
            "Content-Type": "application/json",
            "Prefer": "return=minimal",
        },
    )
    with urllib.request.urlopen(request, timeout=60, context=ssl_context()):
        return


def ssl_context():
    if os.getenv("SUPABASE_INSECURE_SKIP_TLS_VERIFY") == "1":
        return ssl._create_unverified_context()
    try:
        import certifi

        return ssl.create_default_context(cafile=certifi.where())
    except ModuleNotFoundError:
        return ssl.create_default_context()


def apply_patches(report: dict[str, Any]) -> dict[str, Any]:
    url, key = load_key()
    applied = {"words": 0, "kanji": 0, "failed": []}
    for table, scope in [("words", "words"), ("kanji", "kanji")]:
        for patch in report[scope]["patches"]:
            try:
                patch_row(url, key, table, patch)
                applied[scope] += 1
            except Exception as error:  # noqa: BLE001 - report and stop on first remote failure.
                applied["failed"].append({"table": table, "id": patch.get("id"), "error": str(error)})
                return applied
    return applied


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--generated-words", type=Path, required=True)
    parser.add_argument("--generated-kanji", type=Path, required=True)
    parser.add_argument("--existing-words", type=Path, required=True)
    parser.add_argument("--existing-kanji", type=Path, required=True)
    parser.add_argument("--output-dir", type=Path, default=DEFAULT_OUTPUT_DIR / "kanji11-full")
    parser.add_argument("--backup-dir", type=Path)
    parser.add_argument("--apply", action="store_true")
    args = parser.parse_args()

    generated_words = rows_from_json(args.generated_words, "words")
    generated_kanji = rows_from_json(args.generated_kanji, "kanji")
    existing_words = rows_from_json(args.existing_words, "words")
    existing_kanji = rows_from_json(args.existing_kanji, "kanji")
    report = build_dry_run(generated_words, generated_kanji, existing_words, existing_kanji)

    backup_manifest = None
    if args.apply:
        if report["failed"]:
            raise RuntimeError("preflight failed; refusing to apply multilingual patches")
        backup_manifest = backup_inputs(
            args.existing_words,
            args.existing_kanji,
            args.backup_dir or args.output_dir / "backups" / datetime.now(timezone.utc).strftime("%Y%m%dT%H%M%SZ"),
        )
        apply_result = apply_patches(report)
        report["apply"] = apply_result
        report["dry_run"] = False
        if apply_result["failed"]:
            report["failed"] = True
    if backup_manifest:
        report["backup"] = backup_manifest

    output_name = "multilingual_content_apply_report.json" if args.apply else "multilingual_content_patch_dry_run.json"
    write_json(args.output_dir / output_name, report)
    print(
        f"{'apply' if args.apply else 'dry-run'} word_patches={report['summary']['word_patch_count']} "
        f"kanji_patches={report['summary']['kanji_patch_count']} failed={report['failed']} -> {args.output_dir / output_name}"
    )
    if report["failed"]:
        raise SystemExit(1)


if __name__ == "__main__":
    main()
