# TODO

프로젝트 실행, 빌드, 배포, 데이터 정합성과 직접 연결되는 작업만 기록한다.

## Open

- [ ] iOS Firebase 설정을 `konnakanji` 식별자와 다시 맞추기
  문제:
  현재 iOS 앱/Xcode 설정과 Supabase OAuth scheme은 `space.cordelia273.konnakanji`를 사용하지만, [GoogleService-Info.plist](/Users/cordelia273/conductor/workspaces/kanji/tallahassee-v1/kanji_study_app/ios/Runner/GoogleService-Info.plist)의 `BUNDLE_ID`는 아직 `space.cordelia273.kanjiStudyApp`로 남아 있다.
  영향:
  Firebase/Google 로그인 연동이 실제 기기에서 꼬일 가능성이 있다.
  해결:
  Firebase 콘솔에서 iOS 앱 식별자를 `space.cordelia273.konnakanji` 기준으로 다시 등록하거나 기존 앱 설정을 수정한 뒤, 새 `GoogleService-Info.plist`를 받아 교체한다.

## Doing

- 없음

## Done

- 없음

## Item Template

- [ ] 작업 제목
  문제:
  현재 상태와 왜 이 작업이 필요한지 한두 줄로 적는다.
  영향:
  사용자 영향, 빌드 영향, 운영 위험, 데이터 위험 중 무엇이 있는지 적는다.
  해결:
  구현 또는 운영에서 실제로 해야 할 조치를 적는다.
