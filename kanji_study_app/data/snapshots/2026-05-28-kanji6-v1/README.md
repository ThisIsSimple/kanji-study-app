# 2026-05-28 KANJI-6 v1 Snapshot

KANJI-6 권장 v1 import 후보 스냅샷입니다. 한국어 표시 뜻과 영어 원본 gloss가 분리되어 있습니다.

## 포함 파일

- `recommended_v1_words_split_meanings.json.gz`: 단어 import 후보
- `recommended_v1_kanji_split_meanings.json.gz`: 한자 import 후보
- `split_meanings_report.json.gz`: 한국어/영어 분리 및 preflight 리포트
- `recommended_v1_split_import_dry_run.json.gz`: dry-run import 리포트
- `manifest.json`: 체크섬, row count, 복원 경로
- `COLLECTION_SUMMARY.md`: 수집/정규화/생성 요약

## 데이터 상태

- 단어: 46,308개
- 한자: 2,136개
- preflight 실패: 없음
- 기존 중복 warning: 8건
- 한국어 표시 필드의 영어-only 값: 0건

## 에이전트 작업 규칙

- 작업 시작 시 `restore_snapshot.py`로 `.context/data-pipeline/`에 압축을 풀어 사용합니다.
- 스냅샷 폴더 안에 압축 해제된 `*.json` 파일을 만들었다면 커밋하지 않습니다.
- 데이터 수정이 필요하면 `.context`에서 작업하고 검증한 뒤 새 snapshot 디렉터리를 만들어 `*.json.gz`와 `manifest.json`을 갱신합니다.
- 실제 Supabase 반영 전에는 반드시 `split_meanings_report.json`과 dry-run 결과를 확인합니다.
