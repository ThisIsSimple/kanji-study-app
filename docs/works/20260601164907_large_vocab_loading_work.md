# KANJI-15 대용량 단어 로딩 구조 개선 구현 내역

## 구현 요약

단어 마스터 데이터를 전체 다운로드/전체 메모리 필터링 방식에서 페이지 다운로드/로컬 DB query 방식으로 전환했다. 단어 화면은 최초 50건만 로딩하고, 스크롤 하단 접근 시 다음 페이지를 추가 조회한다.

Supabase 단어 다운로드는 1000건 단위 `range` 호출로 변경했고, 각 페이지를 즉시 Drift에 upsert한다. 다운로드 시작 시 기존 단어 캐시를 삭제하지 않으므로 중간 실패가 발생해도 기존 로컬 캐시는 유지된다.

## 변경 파일

- `kanji_study_app/lib/database/app_database.dart`
- `kanji_study_app/lib/services/local_database_service.dart`
- `kanji_study_app/lib/repositories/word_repository.dart`
- `kanji_study_app/lib/services/word_service.dart`
- `kanji_study_app/lib/screens/words_screen.dart`
- `kanji_study_app/lib/screens/home_screen.dart`
- `kanji_study_app/lib/screens/kanji_detail_screen.dart`
- `kanji_study_app/lib/screens/flashcard_screen.dart`
- `kanji_study_app/lib/utils/study_session_launcher.dart`
- `kanji_study_app/lib/services/today_word_recommendation_service.dart`
- `kanji_study_app/test/app_database_word_query_test.dart`
- `docs/plans/20260601164907_large_vocab_loading_plan.md`

## 로컬 DB 구현

Drift schema version을 `10`으로 올리고 `words_table`에 다음 인덱스를 추가했다.

| 인덱스 대상 | 목적 |
| --- | --- |
| `word` | 단어 검색 |
| `reading` | 읽기 검색 |
| `jlpt_level` | JLPT 필터 |
| `priority_rank` | 기본 정렬 |
| `updated_at` | 향후 증분 동기화 기반 |

`AppDatabase`에는 단어 목록 조회용 API를 추가했다.

- `queryWords`
- `countWords`
- `getWordsByIds`
- `getAllWordTexts`
- `getWordIdsForSession`

검색은 v1 범위에 맞춰 `LIKE` 기반으로 구현했다. `word`, `reading`, `meanings_ko`, `meanings_en`, `meanings_jp`를 검색한다.

## 다운로드/캐시 구현

`LocalDatabaseService.downloadAndCacheWordsData`는 1000건 페이지 단위로 Supabase를 조회한다.

구현 흐름:

1. `range(start, end)`로 단어 페이지를 조회한다.
2. 응답이 비어 있으면 종료한다.
3. 페이지 데이터를 `WordsTableCompanion`으로 변환한다.
4. `insertAllOnConflictUpdate`로 로컬 DB에 upsert한다.
5. 응답 개수가 페이지 크기보다 작으면 마지막 페이지로 판단하고 종료한다.

기존 `clearWords()` 선삭제는 제거했다.

## 서비스/화면 구현

`WordRepository`와 `WordService`는 전체 단어 목록을 상시 보관하지 않는다. 초기화 시 로컬 단어 count만 확인하고, 비어 있을 때만 페이지 다운로드를 수행한다.

`WordsScreen` 변경:

- 최초 50건만 조회한다.
- 스크롤 하단에 가까워지면 다음 50건을 조회한다.
- 검색 입력은 300ms debounce 후 DB query를 다시 실행한다.
- 즐겨찾기, JLPT, 학습 상태 필터는 DB query 조건으로 반영한다.
- 플래시카드 시작 시 전체 필터 결과를 메모리에 올리지 않고, 선택 개수만큼 DB에서 랜덤 후보를 조회한다.

홈의 오늘 단어 추천은 전체 단어 목록 대신 JLPT 그룹별 제한된 후보를 조회한다. 한자 상세 화면의 관련 단어도 전체 단어를 읽지 않고 현재 한자 문자 검색 query로 제한했다.

## 테스트

추가한 테스트:

- `test/app_database_word_query_test.dart`

검증한 시나리오:

- `limit/offset` 페이지네이션이 중복 없이 동작한다.
- 검색어, JLPT, include/exclude ID 조건이 함께 적용된다.
- `insertWordsBatch`가 같은 primary key를 upsert한다.

실행한 검증:

```bash
cd kanji_study_app
dart run build_runner build --delete-conflicting-outputs
dart analyze
flutter test test/app_database_word_query_test.dart
flutter test
```

결과:

- `dart analyze`: 통과
- `flutter test test/app_database_word_query_test.dart`: 통과
- `flutter test`: 통과

## 운영 참고

Supabase 스키마 변경은 없다. 앱 업데이트 후 로컬 Drift DB가 schema version `10`으로 올라가면서 인덱스만 생성한다.

서버 삭제 동기화와 FTS5 검색은 이번 KANJI-15 v1 범위에서 제외했다. 삭제 대응은 tombstone/deleted flag 또는 데이터 manifest 도입 후 별도 작업으로 진행하는 것이 안전하다.
