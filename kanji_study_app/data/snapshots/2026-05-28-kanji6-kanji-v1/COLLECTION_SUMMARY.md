# 신규 한자 수집 결과 요약

## 입력
- 기준 데이터: `.context/data-pipeline/recommended_v1_kanji.json`
- 대상: `source=kanjidic2`, `quality_status=ai_draft` 신규 한자 966개
- 기존 한자 2,136개는 이번 import 대상에서 제외

## 한국어 뜻 초안 생성
- provider: `codex-cli`
- batch size: 50
- 완료 batch: 20개
- 생성 결과: 966개
- 미번역/제외: 0개

## 분리 결과
- `meanings`/`meanings_ko`: 한국어 표시 뜻
- `meanings_en`: KANJIDIC2/Unihan 영어 gloss
- `quality_status`: `ai_draft`
- `meaning_source`: `ai_translation`

## 검증 결과
- 후보 count: 966개
- `id`, `character`, `external_id` 중복: 0건
- 영어-only 표시 뜻: 0건
- `meanings_en` 누락: 0건
- 기존 한자 중복 warning: 2건 (`席`, `船`)
