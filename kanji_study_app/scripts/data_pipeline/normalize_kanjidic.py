#!/usr/bin/env python3
"""Normalize KANJIDIC2 and optional Unihan data into the app's kanji shape."""

from __future__ import annotations

import argparse
import re
import xml.etree.ElementTree as ET
import zipfile
from pathlib import Path
from typing import Any

from common import (
    QUALITY_AI_DRAFT,
    SOURCE_KANJIDIC2,
    SOURCE_UNIHAN,
    add_common_output_args,
    dedupe,
    open_text,
    write_json,
)


def _int_or_zero(value: str | None) -> int:
    if not value:
        return 0
    try:
        return int(value)
    except ValueError:
        return 0


def load_unihan(unihan_zip: Path | None) -> dict[str, dict[str, Any]]:
    if not unihan_zip:
        return {}
    result: dict[str, dict[str, Any]] = {}
    with zipfile.ZipFile(unihan_zip) as archive:
        filenames = [name for name in archive.namelist() if name.endswith(".txt")]
        for filename in filenames:
            with archive.open(filename) as raw:
                for line_bytes in raw:
                    line = line_bytes.decode("utf-8").strip()
                    if not line or line.startswith("#"):
                        continue
                    parts = line.split("\t")
                    if len(parts) != 3:
                        continue
                    codepoint, field, value = parts
                    if field not in {"kDefinition", "kJapaneseOn", "kJapaneseKun", "kKorean", "kFrequency"}:
                        continue
                    character = chr(int(codepoint[2:], 16))
                    result.setdefault(character, {})[field] = value
    return result


def character_to_kanji(
    character: ET.Element,
    unihan: dict[str, dict[str, Any]] | None = None,
    source_version: str | None = None,
) -> dict[str, Any]:
    literal = character.findtext("literal", default="")
    misc = character.find("misc")
    reading_meaning = character.find("reading_meaning")
    rmgroup = reading_meaning.find("rmgroup") if reading_meaning is not None else None
    unihan_row = (unihan or {}).get(literal, {})

    on_readings: list[str] = []
    kun_readings: list[str] = []
    korean_on_readings: list[str] = []
    meanings: list[str] = []
    if rmgroup is not None:
        for reading in rmgroup.findall("reading"):
            value = (reading.text or "").strip()
            reading_type = reading.attrib.get("r_type")
            if reading_type == "ja_on":
                on_readings.append(value)
            elif reading_type == "ja_kun":
                kun_readings.append(value)
            elif reading_type in {"korean_r", "korean_h"}:
                korean_on_readings.append(value)
        for meaning in rmgroup.findall("meaning"):
            if meaning.attrib.get("m_lang") is None and meaning.text:
                meanings.append(meaning.text.strip())

    if not on_readings and unihan_row.get("kJapaneseOn"):
        on_readings.extend(unihan_row["kJapaneseOn"].split())
    if not kun_readings and unihan_row.get("kJapaneseKun"):
        kun_readings.extend(unihan_row["kJapaneseKun"].split())
    if unihan_row.get("kKorean"):
        korean_on_readings.extend(unihan_row["kKorean"].split())
    if not meanings and unihan_row.get("kDefinition"):
        meanings.extend(re.split(r";\s*", unihan_row["kDefinition"]))

    stroke_count = 0
    if misc is not None:
        stroke_count = _int_or_zero(misc.findtext("stroke_count"))
    jlpt = _int_or_zero(misc.findtext("jlpt") if misc is not None else None)
    grade = _int_or_zero(misc.findtext("grade") if misc is not None else None)
    priority_rank = _int_or_zero(misc.findtext("freq") if misc is not None else None) or None
    is_common = bool(grade or jlpt or priority_rank)

    radical = None
    radical_node = character.find("radical")
    if radical_node is not None:
        radical = radical_node.findtext("rad_value")

    codepoint = None
    for cp_value in character.findall("codepoint/cp_value"):
        if cp_value.attrib.get("cp_type") == "ucs" and cp_value.text:
            codepoint = f"U+{cp_value.text.upper()}"
            break

    return {
        "character": literal,
        "meanings": dedupe(meanings),
        "readings": {"on": dedupe(on_readings), "kun": dedupe(kun_readings)},
        "korean_on_readings": dedupe(korean_on_readings),
        "korean_kun_readings": [],
        "grade": grade,
        "jlpt": jlpt,
        "strokeCount": stroke_count,
        "examples": [],
        "radical": radical,
        "commentary": None,
        "source": SOURCE_KANJIDIC2,
        "external_id": f"kanjidic2:{codepoint or literal}",
        "source_version": source_version,
        "quality_status": QUALITY_AI_DRAFT,
        "meaning_source": "kanjidic2_english_meaning",
        "is_common": is_common,
        "priority_rank": priority_rank,
        "tags": dedupe([SOURCE_KANJIDIC2, SOURCE_UNIHAN if literal in (unihan or {}) else ""]),
    }


def normalize_file(
    input_path: Path,
    output_path: Path,
    unihan_zip: Path | None = None,
    limit: int | None = None,
) -> list[dict[str, Any]]:
    unihan = load_unihan(unihan_zip)
    kanji: list[dict[str, Any]] = []
    with open_text(input_path) as file:
        for _, element in ET.iterparse(file, events=("end",)):
            if element.tag != "character":
                continue
            row = character_to_kanji(element, unihan=unihan, source_version=input_path.name)
            if row["character"]:
                kanji.append(row)
            element.clear()
            if limit and len(kanji) >= limit:
                break
    write_json(output_path, {"kanji": kanji})
    return kanji


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--input", type=Path, required=True, help="kanjidic2.xml.gz 또는 XML")
    parser.add_argument("--unihan", type=Path, help="Unihan.zip")
    add_common_output_args(parser)
    parser.add_argument("--limit", type=int, help="검증용 최대 한자 수")
    args = parser.parse_args()

    output_path = args.output_dir / "normalized_kanjidic_kanji.json"
    kanji = normalize_file(args.input, output_path, args.unihan, args.limit)
    print(f"normalized_kanjidic_kanji: {len(kanji)} -> {output_path}")


if __name__ == "__main__":
    main()
