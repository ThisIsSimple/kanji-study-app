# 오프라인 동기화 중복/호환성 수정 계획

## 배경

이전 마이그레이션에서 `flashcard_sessions.session_client_id`가 `NOT NULL`이 되었지만 서버 기본값은 없었다. 이미 적용된 마이그레이션을 수정하지 않고 보정 마이그레이션으로 구버전 앱의 insert 호환성을 복구한다.

`study_records`는 온라인 insert 성공 후 로컬 synced 표시 전에 앱이 종료되면 다음 동기화에서 같은 기록을 다시 insert할 수 있었다. 재시도 중복을 막기 위해 클라이언트 생성 idempotency key를 도입한다.

## 구현 계획

- 새 Supabase 마이그레이션을 추가해 `flashcard_sessions.session_client_id`에 서버 기본값을 설정한다.
- `study_records.record_client_id`를 nullable 컬럼으로 추가하고 `(user_id, record_client_id)` unique index를 만든다.
- Drift 로컬 `study_records_table`에도 nullable `recordClientId`를 추가하고 schema version을 올린다.
- 새 학습 기록은 로컬 저장 전에 `study-record-{timestamp}-{randomHex}` id를 생성한다.
- 즉시 원격 저장과 재연결 동기화는 같은 `recordClientId`로 upsert한다.
- 기존 unsynced 로컬 row에 id가 없으면 sync 직전에 id를 생성해 로컬에 저장한 뒤 원격 upsert한다.

## 테스트 계획

- `StudyRecord` JSON 변환에서 `recordClientId`가 보존되는지 검증한다.
- `StudyRecordService` 병합이 `recordClientId` 기반으로 중복을 제거하는지 검증한다.
- legacy record는 기존 composite key fallback을 유지하는지 검증한다.
- legacy id 판별 helper가 null/empty 값을 missing으로 취급하는지 검증한다.
