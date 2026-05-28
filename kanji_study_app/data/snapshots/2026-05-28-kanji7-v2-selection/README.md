# 2026-05-28 KANJI-7 v2 Selection Snapshot

KANJI-7의 v2 후보 선정 결과입니다. 이 snapshot은 AI 한국어 뜻 생성 전 단계이며, 운영 import 후보가 아닙니다.

## 포함 파일

- `recommended_v2_words.json.gz`: v2 단어 후보 10,000개
- `recommended_v2_kanji.json.gz`: v2 한자 후보 1,000개
- `recommended_v2_selection_report.json.gz`: 후보 선정/품질 리포트
- `recommended_v2_tag_backfill_report.json.gz`: 기존 v1 운영 데이터 태그 보강 후보
- `manifest.json`: 체크섬, row count, 복원 경로

## 데이터 상태

- 단어 후보: 10,000개
- 한자 후보: 1,000개
- preflight 실패: 없음
- 한국어 뜻 초안: 아직 생성하지 않음
- 운영 DB 반영: 아직 하지 않음

## 작업 규칙

- 작업 시작 시 `restore_snapshot.py`로 `.context/data-pipeline/`에 복원할 수 있습니다.
- 다음 단계는 Codex CLI 한국어 뜻 생성과 split import 후보 생성입니다.
- 기존 v1 데이터는 삭제/덮어쓰기 없이 `tags` 병합 backfill 후보로만 추적합니다.
