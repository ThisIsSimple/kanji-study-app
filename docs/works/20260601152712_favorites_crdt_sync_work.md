# 즐겨찾기 CRDT 동기화 구현 내역

## 구현 요약

즐겨찾기 동기화를 항목별 Last-Write-Wins Register 방식으로 구현했다. 서버와 로컬 모두 `(user_id, type, target_id)` 조합마다 마지막 상태 1개만 저장하며, 삭제도 물리 삭제하지 않고 tombstone 상태로 보존한다.

이 변경으로 오프라인에서 여러 기기가 같은 즐겨찾기를 서로 다르게 수정해도 `operation_timestamp`, `operation_id` 기준으로 결정적인 최종 상태를 선택할 수 있다.

## 변경 파일

- `kanji_study_app/lib/models/favorite_crdt_state.dart`
- `kanji_study_app/lib/services/favorite_service.dart`
- `kanji_study_app/lib/database/app_database.dart`
- `kanji_study_app/lib/database/app_database.g.dart`
- `kanji_study_app/supabase/migrations/20260601130102_add_favorite_crdt_metadata.sql`
- `kanji_study_app/test/favorite_crdt_state_test.dart`

## 로컬 DB 구현

`FavoritesTable`에 CRDT 메타데이터를 추가했다.

| 컬럼 | 구현 내용 |
| --- | --- |
| `operation_timestamp` | 마지막 작업 시각 |
| `operation_id` | 마지막 작업 고유 ID |
| `device_id` | 마지막 작업을 만든 기기 ID |

또한 `(userId, type, targetId)` unique key를 추가해 같은 즐겨찾기 항목은 하나의 row만 갖도록 했다.

기존 삭제/삽입 중심 메서드는 사용하지 않도록 정리하고, `upsertFavoriteState`를 추가했다. 이 메서드는 기존 row가 없으면 insert하고, 있으면 같은 row의 상태와 작업 메타데이터를 update한다.

Drift schema version은 `8`에서 `9`로 올렸고, migration에서 기존 row를 다음 기준으로 백필한다.

- `operation_timestamp = created_at`
- `operation_id = legacy-{id}`
- `device_id = legacy`

중복 즐겨찾기 row가 있다면 최신 작업 기준으로 하나만 남긴 뒤 unique index를 만든다.

## Supabase 마이그레이션 구현

`favorites` 테이블에 다음 컬럼을 추가하는 마이그레이션을 만들었다.

| 컬럼 | 구현 내용 |
| --- | --- |
| `is_favorite` | 현재 즐겨찾기 상태 |
| `operation_timestamp` | 마지막 작업 시각 |
| `operation_id` | 마지막 작업 고유 ID |
| `device_id` | 마지막 작업을 만든 기기 ID |

기존 row는 즐겨찾기 등록 상태로 백필하고, 중복 row는 최신 작업 기준으로 정리한다. 이후 `(user_id, type, target_id)` unique index를 생성해 서버도 항목별 단일 상태만 유지한다.

삭제는 서버에서 row를 지우지 않고 `is_favorite=false`로 upsert한다.

## 서비스 구현

`FavoriteService`는 토글 시 서버 응답을 기다리지 않고 로컬 상태를 먼저 갱신한다.

구현 흐름:

1. 메모리 캐시에서 현재 상태를 확인한다.
2. 다음 상태를 계산한다.
3. `FavoriteCrdtState`를 만든다.
4. 메모리 캐시를 즉시 갱신한다.
5. 로컬 DB에 `isSynced=false`로 upsert한다.
6. 온라인이면 `syncWithSupabase`를 백그라운드로 실행한다.

기기 ID는 `SharedPreferences`의 `favorite_crdt_device_id`에 저장한다. 기존 값이 없으면 timestamp와 `Random.secure()` 기반 문자열을 만들어 저장한다.

## 병합 구현

병합 모델은 `FavoriteCrdtState`로 분리했다.

`isNewerThan`은 다음 순서로 비교한다.

1. `operationTimestamp`
2. `operationId`

`syncWithSupabase`는 로컬 상태와 서버 상태를 모두 읽고, `type-targetId` key 기준으로 합집합을 순회한다.

각 항목별 처리:

1. 로컬에만 있으면 로컬 상태를 선택한다.
2. 서버에만 있으면 서버 상태를 선택한다.
3. 양쪽에 있으면 `mergeFavoriteStates`로 최신 상태를 선택한다.
4. 선택된 상태가 서버보다 최신이면 서버에 upsert한다.
5. 선택된 상태를 로컬에도 upsert한다.
6. 서버 반영 실패 시 해당 로컬 상태는 `isSynced=false`로 남긴다.

동기화가 끝나면 로컬 DB에서 `isDeleted=false`인 항목만 다시 메모리 캐시에 적재한다.

## 테스트

`favorite_crdt_state_test.dart`를 추가했다.

검증한 시나리오:

- 오래된 추가보다 최신 삭제가 우선한다.
- 오래된 삭제보다 최신 추가가 우선한다.
- timestamp가 같으면 `operation_id`가 tie-break로 동작한다.

실행한 검증:

```bash
cd kanji_study_app
dart run build_runner build --delete-conflicting-outputs
dart analyze
flutter test test/favorite_crdt_state_test.dart
flutter test
```

모든 검증을 통과했다.

## 운영 참고

앱 배포 전에 Supabase 마이그레이션을 먼저 적용해야 한다. 새 앱은 `favorites` upsert 시 `is_favorite`, `operation_timestamp`, `operation_id`, `device_id` 컬럼을 사용한다.

이 구현은 전체 히스토리를 저장하지 않는다. 각 항목의 마지막 상태만 저장하므로, 감사 로그나 시간순 변경 내역이 필요해지면 별도 operation log 테이블을 추가해야 한다.
