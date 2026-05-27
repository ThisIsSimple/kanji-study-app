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
python scripts/data_pipeline/split_meanings.py \
  --words ../.context/data-pipeline/recommended_v1_words.json \
  --kanji ../.context/data-pipeline/recommended_v1_kanji.json \
  --existing-words ../.context/data-pipeline/exports/words.json \
  --existing-kanji ../.context/data-pipeline/exports/kanji_app_shape.json
python scripts/data_pipeline/import_to_supabase.py \
  --words ../.context/data-pipeline/recommended_v1_words_split_meanings.json \
  --kanji ../.context/data-pipeline/recommended_v1_kanji_split_meanings.json
```

`import_to_supabase.py`는 기본값이 dry-run입니다. 실제 반영은 `--apply`를 붙이고 `SUPABASE_URL`, `SUPABASE_SERVICE_ROLE_KEY`를 설정한 경우에만 수행합니다.

`split_meanings.py`는 실제 import 후보를 만들 때 사용합니다. `meanings`와 `meanings_ko`에는 한국어 뜻만 남기고, JMdict/KANJIDIC 영어 gloss는 `meanings_en`에 보존합니다. 신규 중복이나 영어-only 뜻이 한국어 표시 필드에 남으면 `split_meanings_report.json`에서 실패로 표시합니다.

## Korean Draft Generation With CLI

API 비용 없이 구독 중인 Claude Code 또는 Codex CLI를 사용해 한국어 뜻 초안을 생성할 수 있습니다.
결과는 배치별로 `.context/data-pipeline/ko-draft-cli/<provider>/`에 저장되며, 이미 성공한 배치는 재실행 시 재사용합니다.

```sh
# 프롬프트와 JSON 스키마만 생성해서 배치 내용을 확인
python scripts/data_pipeline/generate_ko_meaning_drafts.py \
  --input ../.context/data-pipeline/recommended_v1_words.json \
  --provider claude-cli \
  --batch-size 50 \
  --max-batches 1 \
  --prompts-only

# Claude Code CLI로 첫 50개 생성
python scripts/data_pipeline/generate_ko_meaning_drafts.py \
  --input ../.context/data-pipeline/recommended_v1_words.json \
  --provider claude-cli \
  --model sonnet \
  --batch-size 50 \
  --max-batches 1

# Codex CLI로 실행하려면 provider만 바꿉니다.
python scripts/data_pipeline/generate_ko_meaning_drafts.py \
  --input ../.context/data-pipeline/recommended_v1_words.json \
  --provider codex-cli \
  --batch-size 50 \
  --max-batches 1
```

전체 권장 v1은 약 38,000개 초안 대상이므로 처음에는 `--max-batches`로 샘플 품질을 확인한 뒤 범위를 늘리는 것을 권장합니다.
