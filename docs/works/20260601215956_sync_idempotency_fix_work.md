# 오프라인 동기화 중복/호환성 수정 구현 내역

## 구현 요약

이미 적용된 `flashcard_sessions.session_client_id NOT NULL` 마이그레이션은 수정하지 않고, 새 보정 마이그레이션으로 서버 기본값을 추가했다. 학습 기록에는 `record_client_id`를 추가해 서버 저장 재시도 시 같은 이벤트가 중복 row로 쌓이지 않도록 했다.

## Supabase 변경

새 마이그레이션:

- `kanji_study_app/supabase/migrations/20260601215956_fix_flashcard_and_study_record_idempotency.sql`

변경 내용:

- `pgcrypto` extension 활성화
- `flashcard_sessions.session_client_id` 기본값을 `server-{uuid}` 형식으로 설정
- `study_records.record_client_id` nullable 컬럼 추가
- `(user_id, record_client_id)` unique index 추가

`record_client_id`는 기존 서버 row와 구버전 앱 insert 호환을 위해 nullable로 유지했다.

## 앱 변경

로컬 Drift `study_records_table`에 nullable `recordClientId`를 추가하고 schema version을 10으로 올렸다.

`StudyRecordService`는 새 기록 생성 시 `study-record-{timestamp}-{randomHex}` client id를 만들고, 온라인 즉시 저장과 재연결 동기화 모두 `user_id,record_client_id` 기준 upsert를 사용한다. 기존 unsynced row에 client id가 없으면 sync 직전에 새 id를 로컬에 저장한 뒤 같은 id로 서버에 전송한다.

`StudyRecord` 모델은 `recordClientId`를 JSON 직렬화/역직렬화와 create payload에 포함한다.

## 검증 항목

- `StudyRecord` JSON 변환에서 client id 보존
- `recordClientId` 기반 local/server merge 중복 제거
- legacy record composite merge key 유지
- missing legacy client id 판별 helper 검증
