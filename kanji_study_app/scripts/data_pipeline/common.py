#!/usr/bin/env python3
"""Shared helpers for the KANJI-6 data pipeline."""

from __future__ import annotations

import argparse
import gzip
import hashlib
import json
import re
import unicodedata
from pathlib import Path
from typing import Any, Iterable


WORKSPACE_ROOT = Path(__file__).resolve().parents[3]
APP_ROOT = WORKSPACE_ROOT / "kanji_study_app"
DEFAULT_SOURCE_DIR = WORKSPACE_ROOT / ".context" / "data-sources"
DEFAULT_OUTPUT_DIR = WORKSPACE_ROOT / ".context" / "data-pipeline"

QUALITY_REVIEWED = "reviewed"
QUALITY_AI_DRAFT = "ai_draft"
SOURCE_JMDICT = "jmdict"
SOURCE_KANJIDIC2 = "kanjidic2"
SOURCE_UNIHAN = "unihan"
SOURCE_TATOEBA = "tatoeba"
SOURCE_LEGACY_NAVER = "legacy_naver"
SOURCE_LEGACY_EXCEL = "legacy_excel"


def ensure_dir(path: Path) -> Path:
    path.mkdir(parents=True, exist_ok=True)
    return path


def read_json(path: Path) -> Any:
    with path.open("r", encoding="utf-8") as file:
        return json.load(file)


def write_json(path: Path, data: Any) -> None:
    ensure_dir(path.parent)
    with path.open("w", encoding="utf-8") as file:
        json.dump(data, file, ensure_ascii=False, indent=2, sort_keys=True)
        file.write("\n")


def sha256_file(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as file:
        for chunk in iter(lambda: file.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def open_text(path: Path):
    if path.suffix == ".gz":
        return gzip.open(path, "rt", encoding="utf-8")
    return path.open("r", encoding="utf-8")


def normalize_text(value: Any) -> str:
    return unicodedata.normalize("NFKC", str(value or "")).strip()


def dedupe(values: Iterable[Any]) -> list[str]:
    seen: set[str] = set()
    result: list[str] = []
    for value in values:
        item = normalize_text(value)
        if item and item not in seen:
            seen.add(item)
            result.append(item)
    return result


def dedupe_meanings(meanings: Iterable[dict[str, Any]]) -> list[dict[str, str]]:
    seen: set[tuple[str, str]] = set()
    result: list[dict[str, str]] = []
    for meaning in meanings:
        text = normalize_text(meaning.get("meaning"))
        pos = normalize_text(meaning.get("part_of_speech"))
        if not text:
            continue
        key = (pos.lower(), text.lower())
        if key in seen:
            continue
        seen.add(key)
        row = {"part_of_speech": pos, "meaning": text}
        if meaning.get("source"):
            row["source"] = normalize_text(meaning["source"])
        if meaning.get("quality_status"):
            row["quality_status"] = normalize_text(meaning["quality_status"])
        result.append(row)
    return result


def japanese_contains_kanji(value: str) -> bool:
    return any("\u4e00" <= char <= "\u9fff" for char in value)


def meaning_tokens(meanings: Iterable[dict[str, Any]]) -> set[str]:
    tokens: set[str] = set()
    for meaning in meanings:
        text = normalize_text(meaning.get("meaning")).lower()
        tokens.update(token for token in re.split(r"[^a-z0-9가-힣ぁ-んァ-ン一-龯]+", text) if token)
    return tokens


def parse_json_arg(value: str | None) -> Any:
    if not value:
        return None
    path = Path(value)
    if path.exists():
        return read_json(path)
    return json.loads(value)


def add_common_output_args(parser: argparse.ArgumentParser) -> None:
    parser.add_argument(
        "--output-dir",
        type=Path,
        default=DEFAULT_OUTPUT_DIR,
        help="출력 JSON 파일을 저장할 디렉터리",
    )
