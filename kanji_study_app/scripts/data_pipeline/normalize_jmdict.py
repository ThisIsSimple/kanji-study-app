#!/usr/bin/env python3
"""Normalize JMdict XML into the app's word import shape."""

from __future__ import annotations

import argparse
import xml.etree.ElementTree as ET
from pathlib import Path
from typing import Any

from common import (
    QUALITY_AI_DRAFT,
    SOURCE_JMDICT,
    add_common_output_args,
    dedupe,
    dedupe_meanings,
    open_text,
    write_json,
)


PRIORITY_BUCKETS = {
    "news1": 1,
    "ichi1": 2,
    "spec1": 3,
    "gai1": 4,
    "news2": 5,
    "ichi2": 6,
    "spec2": 7,
    "gai2": 8,
}


def _texts(element: ET.Element, tag: str) -> list[str]:
    return [child.text.strip() for child in element.findall(tag) if child.text and child.text.strip()]


def _priority_rank(priorities: list[str]) -> int | None:
    ranks: list[int] = []
    for priority in priorities:
        if priority in PRIORITY_BUCKETS:
            ranks.append(PRIORITY_BUCKETS[priority])
        elif priority.startswith("nf") and priority[2:].isdigit():
            ranks.append(100 + int(priority[2:]))
    return min(ranks) if ranks else None


def entry_to_words(entry: ET.Element, source_version: str | None = None) -> list[dict[str, Any]]:
    ent_seq = entry.findtext("ent_seq")
    kanji_forms = [keb for k_ele in entry.findall("k_ele") for keb in _texts(k_ele, "keb")]
    readings = [reb for r_ele in entry.findall("r_ele") for reb in _texts(r_ele, "reb")]
    priorities = [
        *[pri for k_ele in entry.findall("k_ele") for pri in _texts(k_ele, "ke_pri")],
        *[pri for r_ele in entry.findall("r_ele") for pri in _texts(r_ele, "re_pri")],
    ]
    priority_rank = _priority_rank(priorities)
    is_common = priority_rank is not None and priority_rank <= 8

    senses: list[dict[str, str]] = []
    tags: list[str] = []
    for sense in entry.findall("sense"):
        pos = "; ".join(_texts(sense, "pos"))
        tags.extend(_texts(sense, "field"))
        tags.extend(_texts(sense, "misc"))
        for gloss in sense.findall("gloss"):
            if gloss.attrib.get("{http://www.w3.org/XML/1998/namespace}lang", "eng") != "eng":
                continue
            if gloss.text and gloss.text.strip():
                senses.append(
                    {
                        "part_of_speech": pos,
                        "meaning": gloss.text.strip(),
                        "source": SOURCE_JMDICT,
                        "quality_status": QUALITY_AI_DRAFT,
                    }
                )

    meanings = dedupe_meanings(senses)
    if not readings or not meanings:
        return []

    words: list[dict[str, Any]] = []
    surface_forms = kanji_forms or readings
    for index, surface in enumerate(dedupe(surface_forms)):
        reading = readings[0]
        words.append(
            {
                "word": surface,
                "reading": reading,
                "meanings": meanings,
                "jlpt_level": 0,
                "source": SOURCE_JMDICT,
                "external_id": f"jmdict:{ent_seq}:{index}" if ent_seq else None,
                "source_version": source_version,
                "quality_status": QUALITY_AI_DRAFT,
                "meaning_source": "jmdict_english_gloss",
                "is_common": is_common,
                "priority_rank": priority_rank,
                "tags": dedupe([*priorities, *tags]),
            }
        )
    return words


def normalize_file(input_path: Path, output_path: Path, limit: int | None = None) -> list[dict[str, Any]]:
    words: list[dict[str, Any]] = []
    with open_text(input_path) as file:
        context = ET.iterparse(file, events=("end",))
        for _, element in context:
            if element.tag != "entry":
                continue
            words.extend(entry_to_words(element, source_version=input_path.name))
            element.clear()
            if limit and len(words) >= limit:
                words = words[:limit]
                break
    write_json(output_path, {"words": words})
    return words


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--input", type=Path, required=True, help="JMdict_e.gz 또는 JMdict XML")
    add_common_output_args(parser)
    parser.add_argument("--limit", type=int, help="검증용 최대 단어 수")
    args = parser.parse_args()

    output_path = args.output_dir / "normalized_jmdict_words.json"
    words = normalize_file(args.input, output_path, args.limit)
    print(f"normalized_jmdict_words: {len(words)} -> {output_path}")


if __name__ == "__main__":
    main()
