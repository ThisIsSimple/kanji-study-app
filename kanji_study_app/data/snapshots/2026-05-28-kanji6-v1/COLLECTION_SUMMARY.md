# 데이터 수집 결과 요약

## 원본 수집
- jmdict: `JMdict_e.gz` (10,445,641 bytes, sha256 `f8d715f890c7`)
- kanjidic2: `kanjidic2.xml.gz` (1,488,565 bytes, sha256 `612d13c9a12f`)
- tatoeba_links: `links.tar.bz2` (147,904,582 bytes, sha256 `95a110c7a068`)
- tatoeba_sentences: `sentences.tar.bz2` (216,048,440 bytes, sha256 `0c00f695e16d`)
- unihan: `Unihan.zip` (8,518,517 bytes, sha256 `f7a48b2b545a`)

## 현재 Supabase Export
- 단어: 8,570개
- 한자: 2,136개

## 전체 병합 결과
- 단어: 296,611개 (신규 288,041개, 병합 11,102개)
- 한자: 13,110개 (신규 10,974개, 병합 2,134개)
- AI 초안 상태: 단어 288,041개, 한자 10,974개

## 권장 v1 후보
- 단어: 46,310개 (AI 초안 37,741개)
- 한자: 3,102개 (AI 초안 966개)

## Codex CLI 한국어 뜻 초안 생성
- 대상: 권장 v1 단어 중 한국어 뜻이 없는 AI 초안 37,741개
- provider: `codex-cli`
- 최종 결과: 37,741개 생성, 미번역 0개
- 품질 검증: 빈 단어 0개, 빈 읽기 0개, 빈 뜻 0개, AI 초안 중 한글 없는 뜻 0개
- dry-run import: 단어 46,310개, 한자 3,102개
- 체크포인트: `.context/data-pipeline/ko-draft-cli/codex-cli/default/`

## 한국어/영어 뜻 분리 import 후보
- 단어: 46,308개
- 한자: 2,136개
- `meanings`/`meanings_ko` 영어-only 값: 단어 0개, 한자 0개
- `meanings_en` 보존: 단어 44,050개, 한자 2,134개
- 제외: 한국어 뜻 없는 단어 2개, 한국어 뜻 없는 신규 한자 966개
- preflight: 실패 0개, 기존 중복 warning 8개

## Tatoeba 예문 후보
- 일본어 문장: 248,664개
- 한국어 문장: 15,806개
- 일본어-한국어 링크 쌍: 2,259개

## 주요 산출물
- `.context/data-pipeline/merged_words.json`
- `.context/data-pipeline/merged_kanji.json`
- `.context/data-pipeline/merge_report.json`
- `.context/data-pipeline/recommended_v1_words.json`
- `.context/data-pipeline/recommended_v1_words_with_ko_drafts.json`
- `.context/data-pipeline/recommended_v1_words_split_meanings.json`
- `.context/data-pipeline/recommended_v1_kanji.json`
- `.context/data-pipeline/recommended_v1_kanji_split_meanings.json`
- `.context/data-pipeline/recommended_v1_with_ko_import_dry_run.json`
- `.context/data-pipeline/recommended_v1_split_import_dry_run.json`
- `.context/data-pipeline/split_meanings_report.json`
- `.context/data-pipeline/tatoeba_jpn_kor_pairs.jsonl`
