# KANJI-14 오프라인 동기화 신뢰성 보강 계획

## 배경

즐겨찾기는 LWW 기반 CRDT 동기화를 적용했지만, 학습 기록과 플래시카드 상세 히스토리는 오프라인/서버 실패 상황에서 재시도 안정성이 부족했다. 학습 기록은 append-only 이벤트 로그 성격이라 LWW CRDT보다 이벤트 재전송과 중복 제거가 적합하고, 플래시카드 완료 세션은 서버 저장 실패 시 상세 히스토리가 유실될 수 있었다.

## 목표

- 학습 기록은 서버 insert 성공 전까지 synced로 표시하지 않는다.
- 서버 저장 실패 시 학습 기록이 다음 동기화에서 재시도되도록 한다.
- 완료된 플래시카드 상세 세션은 서버 저장 실패 시 로컬 pending queue에 남긴다.
- 재연결 시 pending 플래시카드 세션을 서버로 재전송한다.
- 플래시카드 세션 중복 전송을 막기 위한 클라이언트 생성 ID를 도입한다.
- LearningGoal은 현재 구현 범위에서는 코드 변경 대신 LWW 후보로 문서화한다.

## 구현 계획

### 학습 기록

`StudyRecordService.addRecord`에서 로컬 insert 시 항상 `isSynced=false`로 저장한다. 온라인 상태라면 서버 insert를 시도하고, 성공한 뒤에만 해당 로컬 row를 synced로 표시한다. 서버 insert 실패는 사용자 흐름을 실패시키지 않고 로그만 남기며, 로컬 row는 다음 `syncWithSupabase`에서 재시도되도록 둔다.

### 플래시카드 상세 세션

완료된 플래시카드 세션에 `sessionClientId`를 부여한다. 서버 `flashcard_sessions`에는 `session_client_id` 컬럼과 `(user_id, session_client_id)` unique index를 추가해 재시도 시 같은 세션이 중복 생성되지 않게 한다.

서버 저장 실패 시 completed session을 `SharedPreferences` pending queue에 저장한다. 앱 초기화 및 네트워크 재연결 시 pending queue를 순회하면서 서버 upsert를 재시도하고, 성공한 항목만 queue에서 제거한다.

### 문서화

LearningGoal은 단일 설정값이라 LWW Register 적용 후보지만, 사용자 영향도와 현재 범위를 고려해 이번 구현에서는 직접 변경하지 않는다. 후속 이슈로 분리할 수 있도록 구현 내역 문서에 판단을 남긴다.

## 테스트 계획

- 플래시카드 세션의 `sessionClientId`가 JSON 저장/복원과 세션 진행 중 유지되는지 검증한다.
- 기존 session JSON에는 `sessionClientId`가 없어도 복원 가능한지 검증한다.
- 기존 학습 기록 merge/filter 테스트와 전체 앱 테스트를 통과시킨다.

검증 명령:

```bash
cd kanji_study_app
dart analyze
flutter test test/flashcard_session_model_test.dart
flutter test
```
