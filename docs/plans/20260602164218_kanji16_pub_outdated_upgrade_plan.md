# KANJI-16 Flutter Pub Outdated 업그레이드 계획

## 요약

`kanji_study_app`의 직접 의존성과 dev 의존성을 `flutter pub outdated`의 resolvable 최신 버전으로 올린다. 전이 의존성은 Flutter SDK와 각 패키지의 제약이 허용하는 범위까지만 갱신하고, 임의 `dependency_overrides`는 추가하지 않는다.

## 변경 대상

- `pubspec.yaml`의 직접 의존성 제약을 갱신한다.
- `flutter pub upgrade`로 `pubspec.lock`을 재생성한다.
- `flutter_local_notifications` 21.x에서 변경된 named-parameter API 호출부를 보정한다.
- `flutter_lints` 6.x에서 새로 잡히는 lint만 최소 수정한다.
- `phosphor_flutter` 로컬 override는 유지한다.

## 제외 범위

- DB/Supabase 마이그레이션은 생성하지 않는다.
- 전이 의존성 최신화를 위한 강제 override는 추가하지 않는다.
- Flutter 3.44에서 출력되는 `google_mlkit_*` iOS Swift Package Manager 미지원 경고는 기존 플러그인 경고로 보고 이번 범위에서 수정하지 않는다.

## 검증

- `flutter pub get`
- `flutter analyze`
- `flutter test`
- `flutter pub outdated`

