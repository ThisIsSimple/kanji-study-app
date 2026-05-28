#!/usr/bin/env python3
"""Normalize source tags into stable app/system filter tags."""

from __future__ import annotations

from collections import Counter, defaultdict
from typing import Any, Iterable

from common import SOURCE_JMDICT, SOURCE_KANJIDIC2, SOURCE_UNIHAN, dedupe


JMDICT_TAG_MAP = {
    "abbreviation": "form:abbreviation",
    "anatomy": "domain:anatomy",
    "astronomy": "domain:astronomy",
    "baseball": "domain:baseball",
    "biology": "domain:biology",
    "botany": "domain:botany",
    "Buddhism": "domain:buddhism",
    "chemistry": "domain:chemistry",
    "computing": "domain:computing",
    "economics": "domain:economics",
    "food, cooking": "domain:food",
    "geography": "domain:geography",
    "geology": "domain:geology",
    "grammar": "domain:grammar",
    "hanafuda": "domain:hanafuda",
    "law": "domain:law",
    "linguistics": "domain:linguistics",
    "mahjong": "domain:mahjong",
    "martial arts": "domain:martial_arts",
    "mathematics": "domain:mathematics",
    "medicine": "domain:medicine",
    "military": "domain:military",
    "music": "domain:music",
    "physics": "domain:physics",
    "Shinto": "domain:shinto",
    "shogi": "domain:shogi",
    "sports": "domain:sports",
    "sumo": "domain:sumo",
    "zoology": "domain:zoology",
    "archaic": "register:archaic",
    "archaism": "register:archaic",
    "colloquial": "register:colloquial",
    "dated term": "register:dated",
    "derogatory": "register:derogatory",
    "formal or literary term": "register:formal",
    "honorific or respectful (sonkeigo) language": "register:honorific",
    "humble (kenjougo) language": "register:humble",
    "Internet slang": "register:internet_slang",
    "obsolete term": "register:obsolete",
    "polite (teineigo) language": "register:polite",
    "slang": "register:slang",
    "vulgar expression or word": "register:vulgar",
    "rare term": "quality:rare",
    "word usually written using kana alone": "quality:kana_usually",
}


def source_tags(source: str | None) -> list[str]:
    if source == SOURCE_JMDICT:
        return ["source:jmdict"]
    if source == SOURCE_KANJIDIC2:
        return ["source:kanjidic2"]
    return []


def normalized_word_tags(row: dict[str, Any], batch: str | None = None) -> list[str]:
    raw_tags = [str(tag) for tag in row.get("tags") or [] if str(tag).strip()]
    normalized = [JMDICT_TAG_MAP[tag] for tag in raw_tags if tag in JMDICT_TAG_MAP]
    batch_tags = [f"batch:{batch}"] if batch else []
    return dedupe([*raw_tags, *normalized, *source_tags(row.get("source")), *batch_tags])


def normalized_kanji_tags(row: dict[str, Any], derived_tags: Iterable[str] = (), batch: str | None = None) -> list[str]:
    raw_tags = [str(tag) for tag in row.get("tags") or [] if str(tag).strip()]
    normalized = []
    if SOURCE_KANJIDIC2 in raw_tags or row.get("source") == SOURCE_KANJIDIC2:
        normalized.append("source:kanjidic2")
    if SOURCE_UNIHAN in raw_tags:
        normalized.append("source:unihan")
    batch_tags = [f"batch:{batch}"] if batch else []
    return dedupe([*raw_tags, *normalized, *derived_tags, *batch_tags])


def normalized_tag_counts(rows: Iterable[dict[str, Any]]) -> dict[str, int]:
    counter: Counter[str] = Counter()
    for row in rows:
        counter.update(tag for tag in row.get("tags") or [] if ":" in str(tag))
    return dict(sorted(counter.items()))


def derive_kanji_domain_tags(
    kanji_rows: list[dict[str, Any]],
    word_rows: list[dict[str, Any]],
    min_count: int = 2,
) -> dict[str, list[str]]:
    """Derive coarse domain/register tags for kanji from selected words that contain them."""
    tag_counts_by_char: dict[str, Counter[str]] = defaultdict(Counter)
    kanji_chars = {row.get("character") for row in kanji_rows if row.get("character")}
    for word in word_rows:
        normalized_tags = [tag for tag in normalized_word_tags(word) if tag.startswith(("domain:", "register:", "quality:"))]
        if not normalized_tags:
            continue
        for character in set(str(word.get("word") or "")):
            if character in kanji_chars:
                tag_counts_by_char[character].update(normalized_tags)

    result: dict[str, list[str]] = {}
    for character, counts in tag_counts_by_char.items():
        derived = [f"derived:{tag}" for tag, count in sorted(counts.items()) if count >= min_count]
        if derived:
            result[character] = derived
    return result
