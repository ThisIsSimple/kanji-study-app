#!/usr/bin/env python3

import sys
import gzip
import hashlib
import tempfile
import unittest
from pathlib import Path
import xml.etree.ElementTree as ET

sys.path.insert(0, str(Path(__file__).resolve().parent / "data_pipeline"))

from fetch_sources import SourceSpec, metadata_for
from generate_kanji_ko_meaning_drafts import (
    build_kanji_prompt,
    candidate_rows,
    preflight_report as new_kanji_preflight_report,
    split_new_kanji,
)
from generate_ko_meaning_drafts import apply_mapping_to_words, build_cli_prompt, parse_translation_payload
from merge_dataset import merge_kanji, merge_words, quality_report
from normalize_jmdict import entry_to_words
from normalize_kanjidic import character_to_kanji
from prepare_tag_backfill import backfill_kanji, backfill_word, preflight as tag_backfill_preflight
from restore_snapshot import restore_file
from apply_kanji_review_results import build_dry_run as build_kanji_review_dry_run
from select_recommended_v2 import (
    preflight as v2_preflight,
    select_kanji as select_v2_kanji,
    select_words as select_v2_words,
    tag_backfill_report,
    normalize_selected_tags,
    valid_backlog_kanji,
    valid_backlog_words,
)
from split_meanings import preflight_report, split_kanji, split_words
from tag_normalization import normalized_word_tags
from validate_kanji_reviews import annotate_rows as annotate_kanji_review_rows
from validate_kanji_reviews import target_ai_draft_rows, validation_report as kanji_validation_report


class DataPipelineTest(unittest.TestCase):
    def test_jmdict_entry_normalizes_word_schema(self):
        entry = ET.fromstring(
            """
            <entry>
              <ent_seq>1000010</ent_seq>
              <k_ele><keb>学校</keb><ke_pri>ichi1</ke_pri></k_ele>
              <r_ele><reb>がっこう</reb><re_pri>ichi1</re_pri></r_ele>
              <sense><pos>n</pos><gloss>school</gloss></sense>
            </entry>
            """
        )
        rows = entry_to_words(entry, source_version="sample")

        self.assertEqual(len(rows), 1)
        self.assertEqual(rows[0]["word"], "学校")
        self.assertEqual(rows[0]["reading"], "がっこう")
        self.assertEqual(rows[0]["external_id"], "jmdict:1000010:0")
        self.assertTrue(rows[0]["is_common"])
        self.assertEqual(rows[0]["quality_status"], "ai_draft")

    def test_kanjidic_entry_normalizes_kanji_schema(self):
        character = ET.fromstring(
            """
            <character>
              <literal>学</literal>
              <codepoint><cp_value cp_type="ucs">5B66</cp_value></codepoint>
              <radical><rad_value rad_type="classical">39</rad_value></radical>
              <misc><grade>1</grade><stroke_count>8</stroke_count><jlpt>5</jlpt><freq>63</freq></misc>
              <reading_meaning><rmgroup>
                <reading r_type="ja_on">ガク</reading>
                <reading r_type="ja_kun">まな.ぶ</reading>
                <reading r_type="korean_r">학</reading>
                <meaning>study</meaning>
              </rmgroup></reading_meaning>
            </character>
            """
        )
        row = character_to_kanji(character, source_version="sample")

        self.assertEqual(row["character"], "学")
        self.assertEqual(row["readings"]["on"], ["ガク"])
        self.assertEqual(row["korean_on_readings"], ["학"])
        self.assertEqual(row["strokeCount"], 8)
        self.assertEqual(row["external_id"], "kanjidic2:U+5B66")

    def test_merge_preserves_existing_ids_and_deduplicates_words(self):
        existing = [
            {
                "id": 7,
                "word": "学校",
                "reading": "がっこう",
                "meanings": [{"part_of_speech": "명사", "meaning": "학교"}],
                "jlpt_level": 5,
            }
        ]
        incoming = [
            {
                "word": "学校",
                "reading": "がっこう",
                "meanings": [{"part_of_speech": "n", "meaning": "school"}],
                "jlpt_level": 0,
                "external_id": "jmdict:1000010:0",
            },
            {
                "word": "学問",
                "reading": "がくもん",
                "meanings": [{"part_of_speech": "n", "meaning": "learning"}],
                "jlpt_level": 0,
            },
        ]

        merged, report = merge_words(existing, incoming)

        self.assertEqual(merged[0]["id"], 7)
        self.assertEqual(merged[1]["id"], 8)
        self.assertEqual(report["merged"], 1)
        self.assertEqual(report["added"], 1)

    def test_merge_kanji_uses_character_key(self):
        merged, report = merge_kanji(
            [{"id": 1, "character": "学", "meanings": ["학문"], "readings": {"on": [], "kun": []}}],
            [{"character": "学", "meanings": ["study"], "readings": {"on": ["ガク"], "kun": []}}],
        )

        self.assertEqual(len(merged), 1)
        self.assertEqual(merged[0]["id"], 1)
        self.assertEqual(merged[0]["readings"]["on"], ["ガク"])
        self.assertEqual(report["merged"], 1)

    def test_quality_report_lists_invalid_rows(self):
        report = quality_report(
            [{"id": 1, "word": "", "reading": "", "meanings": [], "jlpt_level": 9}],
            [{"id": 2, "character": "", "meanings": []}],
            {"words": {}, "kanji": {}},
        )

        self.assertEqual(report["invalid"]["word_ids_with_invalid_jlpt"], [1])
        self.assertEqual(report["invalid"]["kanji_ids_empty_character"], [2])

    def test_fetch_metadata_records_license_and_hash(self):
        with tempfile.TemporaryDirectory() as tmp_dir:
            path = Path(tmp_dir) / "sample.txt"
            path.write_text("sample", encoding="utf-8")
            spec = SourceSpec("sample", "https://example.com", "sample.txt", "CC0", "https://example.com")
            metadata = metadata_for(spec, path, {"last-modified": "Tue, 26 May 2026 00:00:00 GMT"}, False)

        self.assertEqual(metadata["license"], "CC0")
        self.assertEqual(metadata["source_version"], "Tue, 26 May 2026 00:00:00 GMT")
        self.assertEqual(len(metadata["sha256"]), 64)

    def test_cli_prompt_and_parser_keep_translation_keys(self):
        row = {
            "external_id": "jmdict:1:0",
            "word": "学校",
            "reading": "がっこう",
            "meanings": [{"part_of_speech": "n", "meaning": "school"}],
        }

        prompt = build_cli_prompt([row])
        parsed = parse_translation_payload('{"translations":[{"key":"jmdict:1:0","meanings":["학교"]}]}')
        wrapped = parse_translation_payload(
            '{"structured_output":{"translations":[{"key":"jmdict:1:0","meanings":["학교"]}]}}'
        )

        self.assertIn("jmdict:1:0", prompt)
        self.assertEqual(parsed["jmdict:1:0"], ["학교"])
        self.assertEqual(wrapped["jmdict:1:0"], ["학교"])

    def test_apply_mapping_can_scope_to_cli_batch_keys(self):
        words = [
            {
                "external_id": "jmdict:1:0",
                "word": "学校",
                "reading": "がっこう",
                "quality_status": "ai_draft",
                "meanings": [{"part_of_speech": "n", "meaning": "school"}],
            },
            {
                "external_id": "jmdict:2:0",
                "word": "会社",
                "reading": "かいしゃ",
                "quality_status": "ai_draft",
                "meanings": [{"part_of_speech": "n", "meaning": "company"}],
            },
        ]

        updated, _, needs_translation = apply_mapping_to_words(
            words,
            {"jmdict:1:0": ["학교"]},
            None,
            {"jmdict:1:0"},
        )

        self.assertEqual(updated, 1)
        self.assertEqual(needs_translation, [])
        self.assertEqual(words[0]["meaning_source"], "ai_translation")
        self.assertEqual(words[1]["meanings"][0]["meaning"], "company")

    def test_split_words_separates_korean_display_and_english_gloss(self):
        rows = [
            {
                "id": 1,
                "word": "学校",
                "reading": "がっこう",
                "quality_status": "reviewed",
                "meanings": [
                    {"part_of_speech": "명사", "meaning": "학교"},
                    {"part_of_speech": "n", "meaning": "school", "source": "jmdict"},
                ],
            },
            {
                "id": 2,
                "external_id": "jmdict:2:0",
                "word": "会社",
                "reading": "かいしゃ",
                "quality_status": "ai_draft",
                "meanings": [{"part_of_speech": "n", "meaning": "company"}],
            },
        ]

        split, report = split_words(rows, {"jmdict:2:0": ["회사"]})

        self.assertEqual(report["excluded_no_korean"], [])
        self.assertEqual(split[0]["meanings"], [{"part_of_speech": "명사", "meaning": "학교"}])
        self.assertEqual(split[0]["meanings_en"][0]["meaning"], "school")
        self.assertEqual(split[1]["meanings"][0]["meaning"], "회사")
        self.assertEqual(split[1]["meaning_source"], "ai_translation")

    def test_split_kanji_excludes_rows_without_korean_meanings(self):
        split, report = split_kanji(
            [
                {"id": 1, "character": "学", "meanings": ["학문", "study"]},
                {"id": 2, "character": "𠮟", "meanings": ["scold"]},
            ]
        )

        self.assertEqual(len(split), 1)
        self.assertEqual(split[0]["meanings"], ["학문"])
        self.assertEqual(split[0]["meanings_en"], ["study"])
        self.assertEqual(report["excluded_no_korean"][0]["id"], 2)

    def test_new_kanji_drafts_split_korean_and_english_meanings(self):
        rows = [
            {
                "id": 2138,
                "character": "娃",
                "meanings": ["beautiful"],
                "readings": {"on": ["ア"], "kun": []},
                "korean_on_readings": ["왜"],
                "source": "kanjidic2",
                "external_id": "kanjidic2:U+5A03",
                "quality_status": "ai_draft",
            }
        ]

        prompt = build_kanji_prompt(rows)
        split, report = split_new_kanji(rows, {"kanjidic2:U+5A03": ["예쁠"]})

        self.assertIn("kanjidic2:U+5A03", prompt)
        self.assertEqual(report["excluded_no_korean"], [])
        self.assertEqual(split[0]["meanings"], ["예쁠"])
        self.assertEqual(split[0]["meanings_ko"], ["예쁠"])
        self.assertEqual(split[0]["meanings_en"], ["beautiful"])
        self.assertEqual(split[0]["meaning_source"], "ai_translation")

    def test_new_kanji_preflight_fails_duplicates_and_english_only(self):
        rows = [
            {
                "id": 1,
                "character": "娃",
                "external_id": "kanjidic2:U+5A03",
                "meanings": ["beautiful"],
                "meanings_ko": ["beautiful"],
                "meanings_en": ["beautiful"],
                "readings": {"on": [], "kun": []},
            },
            {
                "id": 1,
                "character": "娃",
                "external_id": "kanjidic2:U+5A03",
                "meanings": ["예쁠"],
                "meanings_ko": ["예쁠"],
                "meanings_en": ["beautiful"],
                "readings": {"on": [], "kun": []},
            },
        ]

        report = new_kanji_preflight_report(rows, [], required_count=2)

        self.assertTrue(report["failed"])
        self.assertIn("duplicate_kanji_ids", [error["type"] for error in report["errors"]])
        self.assertIn("kanji_korean_meanings_contain_english_only", [error["type"] for error in report["errors"]])

    def test_candidate_rows_selects_only_new_kanjidic_ai_drafts(self):
        rows = [
            {"id": 1, "source": "legacy_excel", "quality_status": "reviewed"},
            {"id": 2, "source": "kanjidic2", "quality_status": "ai_draft"},
            {"id": 3, "source": "kanjidic2", "quality_status": "reviewed"},
        ]

        candidates = candidate_rows(rows, required_count=1)

        self.assertEqual([row["id"] for row in candidates], [2])

    def test_v2_selection_excludes_imported_and_invalid_rows(self):
        words = [
            {"id": 1, "source": "jmdict", "quality_status": "ai_draft", "word": "学校", "reading": "がっこう", "meanings": [{"meaning": "school"}]},
            {"id": 2, "source": "jmdict", "quality_status": "ai_draft", "word": "MP3", "reading": "エムピースリー", "meanings": [{"meaning": "MP3"}]},
            {"id": 3, "source": "legacy_naver", "quality_status": "reviewed", "word": "山", "reading": "やま", "meanings": [{"meaning": "산"}]},
            {"id": 4, "source": "jmdict", "quality_status": "ai_draft", "word": "", "reading": "から", "meanings": [{"meaning": "empty"}]},
            {"id": 5, "source": "jmdict", "quality_status": "ai_draft", "word": "偸閑", "reading": "あからさま", "meanings": [{"meaning": "plain"}], "tags": ["word usually written using kana alone"]},
            {"id": 6, "source": "jmdict", "quality_status": "ai_draft", "word": "兌", "reading": "だ", "meanings": [{"meaning": "exchange"}]},
        ]
        kanji = [
            {"id": 10, "source": "kanjidic2", "quality_status": "ai_draft", "character": "学", "meanings": ["study"], "readings": {"on": ["ガク"], "kun": []}},
            {"id": 11, "source": "kanjidic2", "quality_status": "ai_draft", "character": "校", "meanings": [], "readings": {"on": ["コウ"], "kun": []}},
            {"id": 12, "source": "kanjidic2", "quality_status": "ai_draft", "character": "山", "meanings": ["mountain"], "readings": {"on": [], "kun": []}},
        ]

        valid_words, word_exclusions = valid_backlog_words(words, {3})
        valid_kanji, kanji_exclusions = valid_backlog_kanji(kanji, set())

        self.assertEqual([row["id"] for row in valid_words], [1])
        self.assertEqual(word_exclusions["latin_digit_only_word"], 1)
        self.assertEqual(word_exclusions["already_imported"], 1)
        self.assertEqual(word_exclusions["empty_word_or_reading"], 1)
        self.assertEqual(word_exclusions["excluded_word_tag"], 1)
        self.assertEqual(word_exclusions["single_kanji_word"], 1)
        self.assertEqual([row["id"] for row in valid_kanji], [10])
        self.assertEqual(kanji_exclusions["empty_meanings"], 1)
        self.assertEqual(kanji_exclusions["empty_readings"], 1)

    def test_v2_selection_is_deterministic_and_prefers_coverage(self):
        words = [
            {"id": 101, "source": "jmdict", "quality_status": "ai_draft", "word": "学校", "reading": "がっこう", "meanings": [{"meaning": "school"}]},
            {"id": 102, "source": "jmdict", "quality_status": "ai_draft", "word": "学者", "reading": "がくしゃ", "meanings": [{"meaning": "scholar"}]},
            {"id": 103, "source": "jmdict", "quality_status": "ai_draft", "word": "あそこ", "reading": "あそこ", "meanings": [{"meaning": "there"}]},
        ]
        imported_kanji = [{"id": 1, "character": "学"}]
        candidate_kanji = [
            {"id": 201, "character": "校", "is_common": False, "grade": 1, "strokeCount": 10},
            {"id": 202, "character": "者", "is_common": False, "grade": 3, "strokeCount": 8},
        ]

        selected_kanji = select_v2_kanji(candidate_kanji, {"校": 1, "者": 1}, 2)
        selected_words_a = select_v2_words(words, imported_kanji, selected_kanji, 3)
        selected_words_b = select_v2_words(words, imported_kanji, selected_kanji, 3)

        self.assertEqual([row["id"] for row in selected_kanji], [201, 202])
        self.assertEqual([row["id"] for row in selected_words_a], [101, 102, 103])
        self.assertEqual([row["id"] for row in selected_words_a], [row["id"] for row in selected_words_b])

    def test_v2_preflight_catches_overlap_and_duplicates(self):
        words = [
            {"id": 1, "word": "学校", "reading": "がっこう", "meanings": [{"meaning": "school"}]},
            {"id": 1, "word": "学校", "reading": "がっこう", "meanings": [{"meaning": "school"}]},
        ]
        kanji = [
            {"id": 2, "character": "学", "meanings": ["study"], "readings": {"on": ["ガク"], "kun": []}},
            {"id": 3, "character": "学", "meanings": ["study"], "readings": {"on": ["ガク"], "kun": []}},
        ]

        report = v2_preflight(words, kanji, {1}, {2}, expected_words=2, expected_kanji=2)

        self.assertTrue(report["failed"])
        error_types = [error["type"] for error in report["errors"]]
        self.assertIn("duplicate_word_ids", error_types)
        self.assertIn("duplicate_word_reading", error_types)
        self.assertIn("duplicate_kanji_characters", error_types)
        self.assertIn("v1_word_id_overlap", error_types)
        self.assertIn("v1_kanji_id_overlap", error_types)

    def test_v2_normalizes_tags_for_filtering_and_backfill(self):
        word = {
            "id": 101,
            "source": "jmdict",
            "external_id": "jmdict:1:0",
            "word": "心筋",
            "reading": "しんきん",
            "tags": ["medicine", "anatomy"],
        }
        kanji = {
            "id": 201,
            "source": "kanjidic2",
            "external_id": "kanjidic2:U+5FC3",
            "character": "心",
            "tags": ["kanjidic2", "unihan"],
        }

        self.assertEqual(
            normalized_word_tags(word, batch="kanji7_v2"),
            ["medicine", "anatomy", "domain:medicine", "domain:anatomy", "source:jmdict", "batch:kanji7_v2"],
        )

        tagged_words, tagged_kanji, derived = normalize_selected_tags([word], [kanji])
        report = tag_backfill_report([word], [kanji])

        self.assertIn("domain:medicine", tagged_words[0]["tags"])
        self.assertIn("source:kanjidic2", tagged_kanji[0]["tags"])
        self.assertEqual(derived, {})
        self.assertEqual(report["words"]["candidate_count"], 1)
        self.assertEqual(report["kanji"]["candidate_count"], 1)

    def test_prepare_tag_backfill_preserves_current_tags(self):
        word = {
            "id": 1,
            "source": "jmdict",
            "word": "心筋",
            "reading": "しんきん",
            "tags": ["medicine"],
        }
        kanji = {
            "id": 2,
            "source": "kanjidic2",
            "character": "心",
            "tags": ["kanjidic2"],
        }

        word_backfill = backfill_word(word)
        kanji_backfill = backfill_kanji(kanji)
        report = tag_backfill_preflight([word_backfill], [kanji_backfill])

        self.assertEqual(word_backfill["current_tags"], ["medicine"])
        self.assertIn("medicine", word_backfill["tags"])
        self.assertIn("domain:medicine", word_backfill["add_tags"])
        self.assertIn("source:kanjidic2", kanji_backfill["add_tags"])
        self.assertFalse(report["failed"])

    def test_preflight_allows_existing_duplicates_but_fails_new_duplicates(self):
        words = [
            {"id": 1, "word": "一杯", "reading": "いっぱい", "meanings": [{"meaning": "한 잔"}]},
            {"id": 2, "word": "一杯", "reading": "いっぱい", "meanings": [{"meaning": "가득"}]},
            {"id": 3, "word": "学校", "reading": "がっこう", "meanings": [{"meaning": "학교"}]},
            {"id": 4, "word": "学校", "reading": "がっこう", "meanings": [{"meaning": "학교"}]},
        ]
        existing_words = words[:2]

        report = preflight_report(words, [], existing_words, [])

        self.assertTrue(report["failed"])
        self.assertEqual(report["warnings"][0]["type"], "existing_word_reading_duplicate")
        self.assertEqual(report["errors"][0]["type"], "new_word_reading_duplicate")

    def test_restore_snapshot_validates_checksums_and_writes_json(self):
        with tempfile.TemporaryDirectory() as tmp_dir:
            snapshot_dir = Path(tmp_dir) / "snapshot"
            output_dir = Path(tmp_dir) / "output"
            snapshot_dir.mkdir()
            raw = b'{"words":[]}\n'
            compressed = gzip.compress(raw)
            (snapshot_dir / "words.json.gz").write_bytes(compressed)
            file_info = {
                "path": "words.json.gz",
                "restore_to": ".context/data-pipeline/words.json",
                "sha256_compressed": hashlib.sha256(compressed).hexdigest(),
                "sha256_uncompressed": hashlib.sha256(raw).hexdigest(),
            }

            restored = restore_file(snapshot_dir, file_info, output_dir)

            self.assertEqual((output_dir / "words.json").read_bytes(), raw)
            self.assertEqual(restored["bytes"], len(raw))

    def test_kanji_validation_flags_hard_errors_and_warnings(self):
        rows = [
            {
                "id": 1,
                "character": "学",
                "external_id": "kanjidic2:U+5B66",
                "quality_status": "ai_draft",
                "meaning_source": "ai_translation",
                "meanings": ["study"],
                "meanings_ko": ["study"],
                "meanings_en": [],
                "on_readings": "ガク",
                "kun_readings": [],
                "korean_on_readings": [],
                "tags": ["batch:kanji7_v2", "domain:medicine"],
            },
            {
                "id": 1,
                "character": "学",
                "external_id": "kanjidic2:U+5B66",
                "quality_status": "ai_draft",
                "meaning_source": "ai_translation",
                "meanings": ["아주 긴 한국어 뜻입니다"],
                "meanings_ko": ["아주 긴 한국어 뜻입니다"],
                "meanings_en": ["study"],
                "on_readings": ["ガク"],
                "kun_readings": [],
                "korean_on_readings": [],
                "tags": ["batch:kanji7_v2", "domain:medicine"],
            },
        ]

        candidates, _ = annotate_kanji_review_rows(rows)
        report = kanji_validation_report(rows, rows, candidates)

        self.assertTrue(report["failed"])
        self.assertIn("duplicate_ids", report["hard_errors"]["by_type"])
        self.assertIn("duplicate_characters", report["hard_errors"]["by_type"])
        self.assertIn("korean_display_meanings_contain_english_only", report["hard_errors"]["by_type"])
        self.assertIn("invalid_reading_structure", report["hard_errors"]["by_type"])
        self.assertIn("missing_meanings_en", report["hard_errors"]["by_type"])
        self.assertIn("long_korean_meanings", report["warnings"]["by_type"])
        self.assertIn("sentence_like_korean_meanings", report["warnings"]["by_type"])
        self.assertIn("missing_korean_on_readings", report["warnings"]["by_type"])
        self.assertIn("specialized_or_rare_tags", report["warnings"]["by_type"])

    def test_kanji_validation_filters_ai_draft_and_groups_batches(self):
        rows = [
            {"id": 1, "character": "学", "quality_status": "reviewed"},
            {
                "id": 2,
                "character": "娃",
                "external_id": "kanjidic2:U+5A03",
                "quality_status": "ai_draft",
                "meaning_source": "ai_translation",
                "meanings": ["예쁠"],
                "meanings_ko": ["예쁠"],
                "meanings_en": ["beautiful"],
                "on_readings": ["ア"],
                "kun_readings": [],
                "korean_on_readings": ["왜"],
                "tags": ["batch:kanji7_v2", "source:kanjidic2"],
            },
        ]

        target = target_ai_draft_rows(rows)
        candidates, _ = annotate_kanji_review_rows(target)
        report = kanji_validation_report(rows, target, candidates)

        self.assertEqual([row["id"] for row in target], [2])
        self.assertFalse(report["failed"])
        self.assertEqual(report["counts"]["by_batch"], {"batch:kanji7_v2": 1})
        self.assertEqual(report["counts"]["by_source_tag"], {"source:kanjidic2": 1})

    def test_kanji_review_dry_run_builds_patches_for_approve_only(self):
        existing = [
            {"id": 1, "character": "娃", "quality_status": "ai_draft"},
            {"id": 2, "character": "唖", "quality_status": "ai_draft"},
        ]
        reviews = [
            {"id": 1, "character": "娃", "meanings_ko": ["예쁠"], "review_decision": "approve"},
            {"id": 2, "character": "唖", "meanings_ko": ["벙어리"], "review_decision": "reject"},
            {"id": 3, "character": "校", "meanings_ko": ["학교"], "review_decision": "approve"},
        ]

        report = build_kanji_review_dry_run(reviews, existing, updated_at="2026-05-28T00:00:00+00:00")

        self.assertFalse(report["failed"])
        self.assertEqual(report["summary"]["patch_count"], 1)
        self.assertEqual(report["summary"]["skipped_count"], 2)
        self.assertEqual(report["patches"][0]["quality_status"], "reviewed")
        self.assertEqual(report["patches"][0]["meaning_source"], "human_review")


if __name__ == "__main__":
    unittest.main()
