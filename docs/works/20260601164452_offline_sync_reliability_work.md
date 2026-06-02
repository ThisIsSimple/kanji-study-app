# KANJI-14 오프라인 동기화 신뢰성 보강 구현 내역

## 구현 요약

학습 기록은 서버 저장 성공 전까지 unsynced 상태를 유지하도록 수정했고, 플래시카드 완료 세션은 서버 저장 실패 시 로컬 pending queue에 남긴 뒤 재연결 시 재전송하도록 구현했다. 플래시카드 상세 히스토리의 중복 전송을 막기 위해 클라이언트 생성 세션 ID도 추가했다.

## 학습 기록 변경

`StudyRecordService.addRecord`에서 로컬 row를 항상 `isSynced=false`로 생성하도록 변경했다. 온라인 상태에서 서버 insert가 성공하면 그때 `markRecordAsSynced`를 호출한다.

서버 insert 실패는 로컬 기록 생성을 실패시키지 않는다. 실패한 row는 unsynced로 남아 기존 `syncWithSupabase` 재연결 동기화 경로에서 다시 서버 insert를 시도한다.

## 플래시카드 세션 변경

`FlashcardSession`에 `sessionClientId`를 추가했다.

- 새 세션 생성 시 `flashcard-{timestamp}-{random}` 형식의 ID를 만든다.
- 세션 진행, 결과 추가, JSON 저장/복원 과정에서 ID를 유지한다.
- 기존 저장 데이터에는 ID가 없을 수 있으므로 nullable로 두고, 로드 또는 서버 저장 시 없으면 새 ID를 부여한다.

`FlashcardService`에는 completed session pending queue를 추가했다.

- 저장 위치: `SharedPreferences`
- key: `pending_flashcard_sessions`
- 저장 내용: `userId`와 `FlashcardSession` JSON
- 같은 `sessionClientId`가 이미 pending에 있으면 새 값으로 교체한다.

앱 초기화와 네트워크 재연결 시 `syncPendingFlashcardSessions`가 실행된다. 현재 로그인 사용자에 해당하는 pending 세션만 서버로 재전송하고, 성공한 항목은 queue에서 제거한다.

## Supabase 변경

`flashcard_sessions`에 `session_client_id`를 추가하는 마이그레이션을 작성했다.

파일:

- `kanji_study_app/supabase/migrations/20260601164452_add_flashcard_session_client_id.sql`

마이그레이션 내용:

- `session_client_id text` 추가
- 기존 row는 `legacy-{id}`로 백필
- `session_client_id`를 not null로 변경
- `(user_id, session_client_id)` unique index 생성

서버 저장은 `flashcard_sessions` upsert를 사용한다. 기존 세션 row가 있으면 같은 id를 재사용하고, `flashcard_results`는 해당 session id 기준으로 삭제 후 다시 insert해 부분 저장 실패 후 재시도해도 최종 결과가 일관되도록 했다.

## LearningGoal 판단

LearningGoal은 여러 기기에서 오프라인 수정될 경우 LWW Register 후보가 맞다. 다만 이번 작업의 우선순위는 데이터 유실 가능성이 있는 학습 기록과 플래시카드 상세 히스토리였으므로 코드 변경 대상에서 제외했다. 필요하면 별도 이슈에서 `operation_timestamp`, `operation_id`, `device_id` 기반 LWW 메타데이터를 추가한다.

## 테스트

추가 테스트:

- `test/flashcard_session_model_test.dart`
- `test/flashcard_service_pending_queue_test.dart`

검증 시나리오:

- `sessionClientId`가 JSON 저장/복원 후 유지된다.
- 결과 추가와 다음 카드 이동 후에도 `sessionClientId`가 유지된다.
- legacy JSON처럼 `sessionClientId`가 없는 데이터도 복원된다.
- pending queue에서 같은 `sessionClientId`는 중복 추가 대신 교체된다.
- 현재 사용자 sync 성공 항목만 제거되고 다른 사용자/실패 항목은 남는다.
- sync snapshot 이후 추가된 pending 세션은 성공 항목 제거 과정에서 유실되지 않는다.
- 동시 enqueue가 직렬화되어 서로의 SharedPreferences 저장을 덮어쓰지 않는다.

## 2026-06-01 16:54 보완

리뷰에서 `syncPendingFlashcardSessions`가 오래된 pending queue snapshot으로 전체 저장소를 덮어써, 동기화 중 새로 enqueue된 완료 세션을 삭제할 수 있는 문제가 확인되었다.

보완 내용:

- `FlashcardService`에 pending queue 전용 Future-tail lock을 추가했다.
- enqueue와 sync 성공 항목 제거 같은 read-modify-write 작업을 lock 안에서 수행하도록 변경했다.
- sync 업로드는 lock 밖에서 수행하고, 성공한 `sessionClientId`만 최신 queue에서 다시 제거하도록 변경했다.
- 중복 sync 실행을 막는 `_isSyncingPendingSessions` guard를 추가했다.

검증 명령:

```bash
cd kanji_study_app
dart analyze
flutter test test/flashcard_session_model_test.dart
flutter test
```
