# 즐겨찾기 CRDT 동기화

## 목적

즐겨찾기는 오프라인 상태에서도 즉시 동작해야 하고, 여러 기기에서 같은 한자나 단어를 서로 다른 상태로 수정한 뒤 다시 온라인이 되어도 하나의 결정적인 상태로 수렴해야 한다.

이번 구현은 즐겨찾기 항목을 작업 로그 전체가 아니라 **항목별 Last-Write-Wins Register**로 모델링한다. 즉 `(user_id, type, target_id)` 조합마다 마지막 작업 상태 1개만 저장하고, 병합 시 더 최신 작업을 최종 상태로 선택한다.

## 데이터 모델

### 로컬 Drift DB

로컬 `favorites_table`은 `(user_id, type, target_id)`마다 하나의 row만 유지한다. 같은 항목을 여러 번 추가/삭제해도 row가 쌓이지 않고 마지막 상태로 갱신된다.

주요 컬럼은 다음과 같다.

| 컬럼 | 의미 |
| --- | --- |
| `user_id` | 사용자 ID |
| `type` | `kanji` 또는 `word` |
| `target_id` | 한자 또는 단어 ID |
| `note` | 즐겨찾기 메모 |
| `is_synced` | 현재 로컬 상태가 서버 반영까지 완료됐는지 |
| `is_deleted` | `false`면 즐겨찾기 등록, `true`면 즐겨찾기 해제 tombstone |
| `operation_timestamp` | 마지막 작업 시각 |
| `operation_id` | 마지막 작업 고유 ID |
| `device_id` | 마지막 작업을 만든 기기 ID |
| `created_at` | row 생성 또는 작업 기준 시각 |

삭제 상태도 row를 물리 삭제하지 않고 `is_deleted=true`로 남긴다. 이 tombstone이 있어야 늦게 도착한 오래된 추가 작업이 최신 삭제 작업을 덮어쓰지 못한다.

### 서버 Supabase DB

서버 `favorites` 테이블도 항목별 하나의 row를 유지한다. 서버에서는 삭제 상태를 `is_favorite=false`로 표현한다.

주요 CRDT 메타데이터는 다음과 같다.

| 컬럼 | 의미 |
| --- | --- |
| `is_favorite` | 현재 즐겨찾기 상태 |
| `operation_timestamp` | 마지막 작업 시각 |
| `operation_id` | 마지막 작업 고유 ID |
| `device_id` | 마지막 작업을 만든 기기 ID |

`(user_id, type, target_id)` unique 제약을 두고 upsert로 갱신한다. 서버에도 전체 히스토리는 쌓지 않는다.

## 로컬 저장 흐름

사용자가 즐겨찾기를 토글하면 앱은 서버 응답을 기다리지 않고 로컬 상태를 먼저 갱신한다.

1. 메모리 캐시에서 현재 즐겨찾기 여부를 확인한다.
2. 다음 상태를 계산한다.
   - 현재 등록 상태면 `isFavorite=false`
   - 현재 해제 상태면 `isFavorite=true`
3. 새 작업 메타데이터를 만든다.
   - `operationTimestamp`: 현재 UTC 시각
   - `operationId`: timestamp와 랜덤값을 포함한 고유 문자열
   - `deviceId`: `SharedPreferences`에 저장된 기기별 고유 ID
4. 메모리 캐시를 즉시 바꿔 UI에 반영한다.
5. 로컬 DB에 `isSynced=false`로 upsert한다.
6. 온라인이면 백그라운드에서 서버 동기화를 시도한다.

앱 입장에서는 토글 직후 로컬 상태가 source of truth다. 서버 실패가 발생해도 `isSynced=false` row가 남기 때문에 다음 재연결 시 다시 동기화할 수 있다.

## 병합 알고리즘

동기화는 로컬 상태와 서버 상태를 모두 읽은 뒤 같은 key끼리 비교한다. key는 `type-targetId`이다.

1. 로컬의 모든 즐겨찾기 상태를 읽는다. tombstone도 포함한다.
2. 서버의 모든 즐겨찾기 상태를 읽는다. `is_favorite=false` row도 포함한다.
3. 로컬과 서버 key의 합집합을 만든다.
4. 각 key마다 다음 규칙으로 최신 상태를 고른다.
   - 한쪽에만 있으면 그 상태를 선택한다.
   - 양쪽에 있으면 `operation_timestamp`가 더 늦은 상태를 선택한다.
   - timestamp가 같으면 `operation_id`가 더 큰 상태를 선택한다.
5. 선택된 상태가 서버보다 최신이면 서버에 upsert한다.
6. 선택된 상태를 로컬 DB에도 upsert한다.
7. 마지막으로 `is_deleted=false`인 row만 메모리 캐시에 올려 화면에 표시한다.

이 방식은 모든 기기가 같은 비교 규칙을 사용하므로 같은 입력 집합에 대해 같은 결과를 만든다.

## 예시

### 삭제가 최신인 경우

1. A 기기가 오프라인에서 한자 10을 즐겨찾기 추가한다.
2. B 기기가 나중에 오프라인에서 한자 10을 즐겨찾기 해제한다.
3. 두 기기가 온라인이 되면 서버와 로컬 상태를 비교한다.
4. B의 `operation_timestamp`가 더 늦으므로 최종 상태는 해제다.
5. 서버에는 `is_favorite=false` tombstone이 남고, 앱 화면에서는 보이지 않는다.

### 추가가 최신인 경우

1. A 기기가 한자 10을 즐겨찾기 해제한다.
2. B 기기가 나중에 한자 10을 즐겨찾기 추가한다.
3. B의 작업이 더 최신이므로 최종 상태는 등록이다.
4. 서버와 로컬 모두 등록 상태로 수렴한다.

### 같은 시각인 경우

드물게 두 작업의 timestamp가 같으면 `operation_id` 문자열 비교로 승자를 정한다. 이 tie-break는 의미적 우선순위가 아니라 모든 기기에서 같은 결과를 내기 위한 결정성 확보 장치다.

## 설계상 선택

- 전체 작업 로그를 저장하지 않는다. 항목별 마지막 상태만 저장해 저장소 크기와 동기화 비용을 낮춘다.
- 삭제도 물리 삭제하지 않는다. tombstone을 남겨야 오래된 추가 작업과 최신 삭제 작업을 비교할 수 있다.
- 서버 응답 전에는 synced로 표시하지 않는다. 온라인이어도 네트워크나 서버 실패가 가능하므로 성공한 동기화 이후에만 `is_synced=true`가 된다.
- `note`는 즐겨찾기 상태와 함께 보존하지만, 충돌 해결 기준은 즐겨찾기 상태의 마지막 작업 메타데이터다.

## 관련 파일

- `kanji_study_app/lib/services/favorite_service.dart`
- `kanji_study_app/lib/models/favorite_crdt_state.dart`
- `kanji_study_app/lib/database/app_database.dart`
- `kanji_study_app/supabase/migrations/20260601130102_add_favorite_crdt_metadata.sql`
- `kanji_study_app/test/favorite_crdt_state_test.dart`

## 검증

관련 테스트는 `favorite_crdt_state_test.dart`에 있다.

검증 명령:

```bash
cd kanji_study_app
dart analyze
flutter test test/favorite_crdt_state_test.dart
flutter test
```
