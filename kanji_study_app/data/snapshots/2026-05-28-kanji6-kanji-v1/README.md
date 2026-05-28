# 2026-05-28 KANJI-6 신규 한자 v1 Snapshot

KANJI-6에서 단어 운영 반영 후 별도로 처리한 신규 KANJIDIC2 한자 966개 import 후보입니다.

## 포함 파일

- `recommended_v1_new_kanji_split_meanings.json.gz`: 신규 한자 966개 import 후보
- `new_kanji_split_meanings_report.json.gz`: 한국어 뜻 생성 및 preflight 리포트
- `recommended_v1_new_kanji_import_dry_run.json.gz`: 한자 전용 dry-run 리포트
- `new_kanji_manual_sample_100.json.gz`: 수동 검수용 100개 샘플
- `manifest.json`: 체크섬, row count, 복원 경로

## 데이터 상태

- 신규 한자: 966개
- 상태: `ai_draft`
- `meanings`/`meanings_ko`: 한국어 뜻만 포함
- `meanings_en`: KANJIDIC2/Unihan 영어 gloss 보존
- preflight 실패: 없음
- 기존 중복 warning: 2건 (`席`, `船`)

## 에이전트 작업 규칙

- 작업 시작 시 `restore_snapshot.py`로 `.context/data-pipeline/`에 압축을 풀어 사용합니다.
- 실제 운영 반영 전에는 `new_kanji_split_meanings_report.json`과 dry-run 결과를 확인합니다.
- 스냅샷 폴더 안에 압축 해제된 `*.json` 파일을 만들었다면 커밋하지 않습니다.
