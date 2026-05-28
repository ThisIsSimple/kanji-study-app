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

`import_to_supabase.py`는 기본값이 dry-run입니다. 실제 반영은 `--apply`를 붙이고 `SUPABASE_URL`, `SUPABASE_SECRET_KEY` 또는 기존 `SUPABASE_SERVICE_ROLE_KEY`를 설정한 경우에만 수행합니다.

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

## New Kanji Korean Draft Generation

단어 운영 반영 후 별도로 처리하는 신규 KANJIDIC2 한자는 `generate_kanji_ko_meaning_drafts.py`를 사용합니다. 이 스크립트는 `recommended_v1_kanji.json`에서 `source=kanjidic2`, `quality_status=ai_draft` 후보 966개만 골라 한국어 뜻 초안을 만들고, `meanings`/`meanings_ko`와 `meanings_en`을 분리한 import 후보 및 dry-run 리포트를 생성합니다.

```sh
# 프롬프트만 생성해서 후보와 배치 내용을 확인
python scripts/data_pipeline/generate_kanji_ko_meaning_drafts.py \
  --input ../.context/data-pipeline/recommended_v1_kanji.json \
  --provider codex-cli \
  --batch-size 50 \
  --prompts-only

# Codex CLI로 신규 한자 966개 한국어 뜻 초안 생성
python scripts/data_pipeline/generate_kanji_ko_meaning_drafts.py \
  --input ../.context/data-pipeline/recommended_v1_kanji.json \
  --provider codex-cli \
  --batch-size 50

# 한자만 dry-run import
python scripts/data_pipeline/import_to_supabase.py \
  --kanji ../.context/data-pipeline/recommended_v1_new_kanji_split_meanings.json \
  --preflight-report ../.context/data-pipeline/new_kanji_split_meanings_report.json \
  --report ../.context/data-pipeline/recommended_v1_new_kanji_import_dry_run.json
```

한자 체크포인트는 `.context/data-pipeline/ko-draft-cli-kanji/<provider>/`에 저장됩니다. 운영 반영 전에는 `new_kanji_split_meanings_report.json`의 `preflight.failed == false`, 후보 수 966개, 한국어 표시 필드 영어-only 0건을 확인해야 합니다.

## KANJI-7 v2 Candidate Selection

KANJI-7의 첫 단계는 남은 전체 병합본에서 다음 import 후보만 결정적으로 고르는 것입니다. 이 단계에서는 AI 한국어 뜻 생성, snapshot 생성, Supabase upsert를 하지 않습니다.

```sh
python scripts/data_pipeline/select_recommended_v2.py \
  --merged-words ../.context/data-pipeline/merged_words.json \
  --merged-kanji ../.context/data-pipeline/merged_kanji.json \
  --imported-words ../.context/data-pipeline/recommended_v1_words_split_meanings.json \
  --imported-kanji ../.context/data-pipeline/recommended_v1_kanji_split_meanings.json \
  --imported-kanji ../.context/data-pipeline/recommended_v1_new_kanji_split_meanings.json
```

기본 출력은 `.context/data-pipeline/recommended_v2_words.json`, `recommended_v2_kanji.json`, `recommended_v2_selection_report.json`, `recommended_v2_tag_backfill_report.json`입니다. 기본 후보 수는 단어 10,000개와 한자 1,000개이며, 이미 v1에서 반영된 id, 빈 값, Latin/digit-only 단어, 단일 한자 표제어, 고어/희귀 표기 태그는 제외합니다.

v2 후보의 `tags`에는 원본 JMdict/KANJIDIC2 태그를 보존하면서 앱/운영 필터용 정규화 태그를 추가합니다. 예를 들어 `medicine`은 `domain:medicine`, `formal or literary term`은 `register:formal`, KANJIDIC2 출처는 `source:kanjidic2`, 이번 후보 배치는 `batch:kanji7_v2`로 저장됩니다. 이미 운영에 들어간 v1 데이터는 삭제하거나 덮어쓰지 않고, `recommended_v2_tag_backfill_report.json`에서 `id`/`external_id` 기준 태그 보강 후보로만 추적합니다.
