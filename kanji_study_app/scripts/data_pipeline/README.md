# KANJI-6 Data Pipeline

오픈 라이선스 데이터만 사용해 단어/한자 데이터를 확장하는 파이프라인입니다.

## Sources

- JMdict: CC BY-SA 4.0, https://www.edrdg.org/wiki/JMdict-EDICT_Dictionary_Project.html
- KANJIDIC2: CC BY-SA 4.0, https://www.edrdg.org/kanjidic/kanjd2index_legacy.html
- Unihan: Unicode License, https://unicode.org/reports/tr38/
- Tatoeba: CC BY 2.0 FR / CC0 mixed, https://tatoeba.org/en/downloads

## Flow

```sh
python scripts/data_pipeline/fetch_sources.py
SUPABASE_URL=... SUPABASE_ANON_KEY=... python scripts/data_pipeline/export_supabase.py
python scripts/data_pipeline/normalize_jmdict.py --input ../.context/data-sources/JMdict_e.gz
python scripts/data_pipeline/normalize_kanjidic.py --input ../.context/data-sources/kanjidic2.xml.gz --unihan ../.context/data-sources/Unihan.zip
python scripts/data_pipeline/merge_dataset.py \
  --existing-words ../.context/exports/words.json \
  --existing-kanji ../.context/exports/kanji.json \
  --incoming-words ../.context/data-pipeline/normalized_jmdict_words.json \
  --incoming-kanji ../.context/data-pipeline/normalized_kanjidic_kanji.json
python scripts/data_pipeline/generate_ko_meaning_drafts.py --input ../.context/data-pipeline/merged_words.json
python scripts/data_pipeline/import_to_supabase.py --words ../.context/data-pipeline/merged_words_with_ko_drafts.json --kanji ../.context/data-pipeline/merged_kanji.json
```

`import_to_supabase.py`는 기본값이 dry-run입니다. 실제 반영은 `--apply`를 붙이고 `SUPABASE_URL`, `SUPABASE_SERVICE_ROLE_KEY`를 설정한 경우에만 수행합니다.
