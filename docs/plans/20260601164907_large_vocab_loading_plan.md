# KANJI-15 대용량 단어 로딩 구조 개선 계획

## 배경

단어 데이터가 약 6만 건 규모로 확장되면서, 앱이 Supabase `words` 테이블 전체를 한 번에 내려받고 전체 단어를 메모리에 유지하는 구조가 병목이 되었다. 네트워크 응답 크기, 타임아웃, JSON 디코딩 비용, 화면 필터링 비용이 모두 커져 초기 캐시 생성과 단어 목록 진입이 불안정해질 수 있다.

## 목표

- Supabase 단어 다운로드를 페이지 단위로 나눠 안정화한다.
- 다운로드 실패 시 기존 로컬 캐시가 삭제되지 않게 한다.
- 단어 목록, 검색, 필터링을 로컬 Drift DB query 기반으로 전환한다.
- 단어 화면은 필요한 만큼만 페이지 단위로 로딩한다.
- 기존 즐겨찾기, 학습 상태, JLPT 필터, 플래시카드 흐름을 유지한다.

## 설계

단어 마스터 데이터는 로컬 Drift DB를 기준 저장소로 사용한다. 앱 시작 또는 단어 화면 진입 시 전체 단어 모델을 메모리에 올리지 않고, 화면 상태에 맞는 조건으로 DB를 조회한다.

다운로드는 Supabase `range(start, end)`를 사용해 1000건 단위로 반복한다. 각 페이지는 즉시 로컬 DB에 upsert하며, 다운로드 시작 전에 기존 단어를 삭제하지 않는다. 중간 실패가 발생해도 이전 캐시 또는 이미 성공한 페이지는 보존된다.

검색은 v1에서 SQLite `LIKE` 기반으로 처리한다. FTS5 검색 인덱스는 별도 후속 작업으로 남긴다.

## 로컬 DB 조회 계획

`AppDatabase`에 다음 단어 조회 API를 추가한다.

| API | 용도 |
| --- | --- |
| `queryWords` | 검색어, JLPT, 즐겨찾기 ID, 학습 상태, limit/offset 조건으로 단어 목록 조회 |
| `countWords` | 같은 조건의 전체 결과 수 조회 |
| `getWordsByIds` | 플래시카드 이어하기처럼 특정 ID 목록의 단어 조회 |
| `getWordIdsForSession` | 현재 필터 조건에서 플래시카드 후보 ID 조회 |

`WordsTable`에는 `word`, `reading`, `jlpt_level`, `priority_rank`, `updated_at` 기준 인덱스를 추가한다. Drift schema version을 올리고 기존 DB에는 migration에서 인덱스를 생성한다.

## 서비스 변경 계획

`WordRepository`와 `WordService`는 전체 단어 `List<Word>`와 `Map<int, Word>`를 상시 보관하지 않는다. 대신 로컬 DB query API를 호출하고, 최근 조회한 단어만 작은 메모리 캐시에 저장해 동기 API가 필요한 기존 플래시카드 렌더링을 지원한다.

홈의 오늘 단어 추천과 플래시카드 이어하기는 전체 단어 목록이 아니라 필요한 후보 또는 세션 ID를 DB에서 조회하도록 변경한다.

## 화면 변경 계획

`WordsScreen`은 초기 50건을 로딩하고, 스크롤 하단에 가까워지면 다음 50건을 추가 조회한다. 검색 입력은 debounce 후 첫 페이지부터 다시 조회한다.

즐겨찾기, JLPT, 학습 상태 필터 변경 시 메모리 필터링 대신 DB query를 다시 실행한다. 필터 결과가 없으면 기존 빈 상태 UI를 유지한다.

## 테스트 계획

- 페이지 다운로드가 여러 페이지를 모두 upsert하는지 검증한다.
- 다운로드 실패 시 기존 단어 캐시가 삭제되지 않는지 검증한다.
- `queryWords`가 검색어, JLPT, 즐겨찾기, 학습 상태 조건을 조합해 올바른 결과를 반환하는지 검증한다.
- `limit/offset` 페이지네이션이 중복과 누락 없이 동작하는지 검증한다.
- `WordsScreen`에서 첫 페이지 로딩, 검색 결과 교체, 하단 스크롤 추가 로딩을 확인한다.

검증 명령:

```bash
cd kanji_study_app
dart run build_runner build --delete-conflicting-outputs
dart analyze
flutter test
```
