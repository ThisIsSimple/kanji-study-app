# 즐겨찾기 CRDT 동기화 구현 계획

## 배경

오프라인 상태에서 여러 기기가 같은 즐겨찾기 항목을 수정하면 기존 구현은 추가/삭제 의도를 결정적으로 병합하기 어려웠다. 특히 삭제를 물리 삭제로 처리하면 늦게 도착한 오래된 추가 작업이 최신 삭제 의도를 다시 덮어쓸 수 있었다.

## 목표

- 즐겨찾기 토글은 오프라인에서도 즉시 로컬에 반영한다.
- 여러 기기에서 오프라인으로 수정된 즐겨찾기 상태가 다시 온라인이 되었을 때 하나의 결정적인 최종 상태로 수렴하게 한다.
- 서버와 로컬 모두 전체 작업 로그가 아니라 항목별 마지막 상태 1개만 저장한다.
- 삭제 상태도 tombstone으로 보존해 오래된 작업과 최신 작업을 비교할 수 있게 한다.

## 설계

즐겨찾기는 `(user_id, type, target_id)` 조합별 Last-Write-Wins Register로 모델링한다. 각 항목은 현재 상태와 마지막 작업 메타데이터만 가진다.

최신 작업 판단 기준은 다음 순서다.

1. `operation_timestamp`가 더 늦은 상태가 이긴다.
2. timestamp가 같으면 `operation_id`가 더 큰 상태가 이긴다.

이 규칙은 모든 기기에서 같은 입력에 대해 같은 결과를 내기 위한 결정성 확보 장치다.

## 로컬 저장 계획

로컬 Drift `favorites_table`은 항목별 하나의 row만 유지한다.

필요한 컬럼:

| 컬럼 | 의미 |
| --- | --- |
| `user_id` | 사용자 ID |
| `type` | `kanji` 또는 `word` |
| `target_id` | 한자 또는 단어 ID |
| `note` | 즐겨찾기 메모 |
| `is_synced` | 현재 로컬 상태의 서버 반영 여부 |
| `is_deleted` | `false`면 등록, `true`면 해제 tombstone |
| `operation_timestamp` | 마지막 작업 시각 |
| `operation_id` | 마지막 작업 고유 ID |
| `device_id` | 마지막 작업을 만든 기기 ID |
| `created_at` | row 생성 또는 작업 기준 시각 |

`(user_id, type, target_id)` unique 제약을 두고 insert 대신 upsert로 갱신한다.

## 서버 저장 계획

Supabase `favorites` 테이블도 항목별 하나의 row만 유지한다. 서버 삭제 상태는 물리 삭제가 아니라 `is_favorite=false`로 표현한다.

추가할 컬럼:

| 컬럼 | 의미 |
| --- | --- |
| `is_favorite` | 현재 즐겨찾기 상태 |
| `operation_timestamp` | 마지막 작업 시각 |
| `operation_id` | 마지막 작업 고유 ID |
| `device_id` | 마지막 작업을 만든 기기 ID |

기존 row는 `is_favorite=true`, `operation_timestamp=created_at`, `operation_id=legacy-{id}`, `device_id=legacy` 기준으로 백필한다. 중복 row가 있으면 최신 작업 기준으로 하나만 남긴 뒤 `(user_id, type, target_id)` unique index를 만든다.

## 동기화 계획

토글 시:

1. 현재 메모리 캐시 기준으로 다음 상태를 계산한다.
2. `operation_timestamp`, `operation_id`, `device_id`를 만든다.
3. 메모리 캐시를 즉시 갱신한다.
4. 로컬 DB에 `is_synced=false`로 upsert한다.
5. 온라인이면 백그라운드에서 동기화를 시도한다.

동기화 시:

1. 로컬의 모든 상태를 읽는다. tombstone도 포함한다.
2. 서버의 모든 상태를 읽는다. `is_favorite=false`도 포함한다.
3. `type-targetId` key 기준으로 로컬/서버 상태를 매칭한다.
4. LWW 규칙으로 최신 상태를 고른다.
5. 선택된 상태가 서버보다 최신이면 서버에 upsert한다.
6. 선택된 상태를 로컬에도 upsert하고 동기화 성공 여부를 `is_synced`에 반영한다.
7. `is_deleted=false`인 row만 메모리 캐시에 올려 화면에 표시한다.

## 테스트 계획

- 최신 삭제가 오래된 추가보다 우선하는지 검증한다.
- 최신 추가가 오래된 삭제보다 우선하는지 검증한다.
- timestamp가 같을 때 `operation_id`로 결정적으로 tie-break 되는지 검증한다.
- 전체 앱 테스트와 정적 분석을 통과시킨다.

검증 명령:

```bash
cd kanji_study_app
dart analyze
flutter test test/favorite_crdt_state_test.dart
flutter test
```
