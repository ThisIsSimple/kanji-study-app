#!/usr/bin/env python3

import sys
import tempfile
import unittest
from pathlib import Path
import xml.etree.ElementTree as ET

sys.path.insert(0, str(Path(__file__).resolve().parent / "data_pipeline"))

from fetch_sources import SourceSpec, metadata_for
from generate_ko_meaning_drafts import apply_mapping_to_words, build_cli_prompt, parse_translation_payload
from merge_dataset import merge_kanji, merge_words, quality_report
from normalize_jmdict import entry_to_words
from normalize_kanjidic import character_to_kanji


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


if __name__ == "__main__":
    unittest.main()
