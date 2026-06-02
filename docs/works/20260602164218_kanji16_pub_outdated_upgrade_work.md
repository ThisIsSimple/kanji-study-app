# KANJI-16 Flutter Pub Outdated 업그레이드 작업 내역

## 구현 요약

`kanji_study_app`의 직접 의존성과 dev 의존성을 `flutter pub outdated`의 resolvable 최신 버전으로 갱신했다. `phosphor_flutter`는 로컬 override 상태를 유지했다.

## 변경 내용

- `pubspec.yaml`에서 `app_links`, `confetti`, `connectivity_plus`, `cupertino_icons`, `fl_chart`, `flutter_local_notifications`, `flutter_timezone`, `forui`, `google_fonts`, `package_info_plus`, `shared_preferences`, `sqlite3_flutter_libs`, `supabase_flutter`, `timezone`, `flutter_lints` 제약을 상향했다.
- `flutter pub upgrade`로 `pubspec.lock`을 갱신했고, lockfile 기준 60개 패키지가 변경됐다.
- `flutter_local_notifications` 21.x의 새 named-parameter API에 맞춰 `initialize`와 `zonedSchedule` 호출을 수정했다.
- `flutter_lints` 6.x에서 잡힌 `unnecessary_underscores` info를 정리했다.

## 검증 결과

- `flutter pub get`: 통과
- `flutter analyze`: 통과, `No issues found!`
- `flutter test`: 통과, `All tests passed!`
- `flutter pub outdated`: direct/dev 의존성은 최신 resolvable 상태

## 잔여 사항

- `flutter pub outdated` direct dependencies에는 `phosphor_flutter 2.1.0`이 overridden으로 표시된다. 로컬 `third_party/phosphor_flutter` override를 유지하는 의도된 상태이며 pub.dev 최신도 2.1.0이다.
- 전이 의존성 일부(`analyzer`, `dart_style`, `flutter_hooks`, `meta`, `vector_math`, `xml`, `test_api` 등)는 현재 제약에서 resolvable 최신을 사용 중이며, 더 최신 버전은 상호 제약상 호환되지 않는 것으로 표시된다.
- Flutter 3.44는 `google_mlkit_digital_ink_recognition`, `google_mlkit_commons`의 iOS Swift Package Manager 미지원 경고를 출력한다. 이번 이슈 범위 밖의 기존 플러그인 경고로 기록만 남겼다.

