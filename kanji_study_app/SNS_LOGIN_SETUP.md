# SNS 로그인 설정 가이드

SNS 로그인 기능을 완전히 활성화하려면 아래 단계를 따라 각 플랫폼의 API 키를 설정해야 합니다.

## 1. Google 로그인 설정

### Google Cloud Console 설정
1. [Google Cloud Console](https://console.cloud.google.com/)에 접속
2. 새 프로젝트 생성 또는 기존 프로젝트 선택
3. "APIs & Services" > "Credentials" 이동
4. "Create Credentials" > "OAuth client ID" 선택
5. Application type: "iOS" 및 "Android" 각각 생성

### iOS 설정
1. Google Cloud Console에서 iOS OAuth client ID 생성
2. Bundle ID 입력: `space.cordelia273.kanjiStudyApp`
3. `GoogleService-Info.plist` 파일 다운로드
4. iOS 프로젝트의 `ios/Runner/` 폴더에 추가
5. `ios/Runner/Info.plist` 파일 수정:
   - `com.googleusercontent.apps.YOUR_REVERSED_CLIENT_ID`를 실제 reversed client ID로 변경

### Android 설정
1. Google Cloud Console에서 Android OAuth client ID 생성
2. Package name 입력: `space.cordelia273.kanji_study_app`
3. SHA-1 certificate fingerprint 입력 (debug 및 release 키 모두)
4. `google-services.json` 파일 다운로드
5. Android 프로젝트의 `android/app/` 폴더에 추가

## 2. Apple 로그인 설정

### Apple Developer 설정
1. [Apple Developer](https://developer.apple.com/)에 접속
2. "Certificates, Identifiers & Profiles" 이동
3. "Identifiers" > App ID 선택 또는 생성
4. "Sign In with Apple" capability 활성화
5. "Services IDs" 생성 및 설정

### Xcode 설정
1. Xcode에서 프로젝트 열기
2. "Signing & Capabilities" 탭
3. "+ Capability" 클릭
4. "Sign In with Apple" 추가

## 3. Kakao 로그인 설정

### Kakao Developers 설정
1. [Kakao Developers](https://developers.kakao.com/)에 접속
2. 애플리케이션 생성
3. "앱 설정" > "앱 키"에서 Native App Key 복사
4. "앱 설정" > "플랫폼"에서 iOS 및 Android 플랫폼 등록

### 코드 수정
1. `lib/services/supabase_service.dart` 파일에서:
   ```dart
   kakao.KakaoSdk.init(nativeAppKey: 'YOUR_KAKAO_NATIVE_APP_KEY');
   ```
   실제 Native App Key로 변경

2. `ios/Runner/Info.plist` 파일에서:
   ```xml
   <string>kakaoYOUR_KAKAO_NATIVE_APP_KEY</string>
   ```
   실제 Native App Key로 변경 (예: kakao1234567890abcdef)

3. `android/app/src/main/AndroidManifest.xml` 파일에서:
   ```xml
   <data android:scheme="kakaoYOUR_KAKAO_NATIVE_APP_KEY" android:host="oauth"/>
   ```
   실제 Native App Key로 변경

### Kakao 플랫폼 설정
- iOS Bundle ID 등록
- Android Package Name 및 Key Hash 등록
- Redirect URI 설정: `kakaoYOUR_KAKAO_NATIVE_APP_KEY://oauth`

## 4. Supabase 설정

### Supabase Dashboard 설정
1. [Supabase Dashboard](https://app.supabase.com/)에 접속
2. 프로젝트 선택
3. "Authentication" > "Providers" 이동

### Google Provider 설정
1. Google provider 활성화
2. Client ID 입력 (Web application OAuth 2.0 Client ID)
3. Client Secret 입력
4. Authorized redirect URIs 설정

### Apple Provider 설정
1. Apple provider 활성화
2. Service ID 입력
3. Team ID 입력
4. Key ID 및 Private Key 입력

### Kakao Provider 설정
1. Kakao provider 활성화 (Custom OAuth 사용)
2. Client ID (REST API Key) 입력
3. Client Secret 입력
4. Authorization URL: `https://kauth.kakao.com/oauth/authorize`
5. Token URL: `https://kauth.kakao.com/oauth/token`
6. User Info URL: `https://kapi.kakao.com/v2/user/me`

## 5. 환경별 설정

### Development 환경
- Debug 키와 함께 테스트
- 로컬 Supabase 인스턴스 사용 가능

### Production 환경
- Release 키 사용
- Production Supabase 프로젝트 사용
- 모든 URL scheme 및 redirect URI 확인

## 6. 테스트 체크리스트

- [ ] Google 로그인 테스트 (iOS)
- [ ] Google 로그인 테스트 (Android)
- [ ] Apple 로그인 테스트 (iOS)
- [ ] Kakao 로그인 테스트 (iOS)
- [ ] Kakao 로그인 테스트 (Android)
- [ ] 익명 사용자 → SNS 계정 전환 테스트
- [ ] 데이터 마이그레이션 확인
- [ ] 로그아웃 후 재로그인 테스트

## 주의사항

1. **보안**: API 키와 Secret은 절대 소스 코드에 직접 포함하지 마세요
2. **익명 사용자 데이터**: SNS 계정 연동 시 기존 데이터가 보존되는지 확인
3. **에러 처리**: 네트워크 오류, 인증 실패 등 다양한 시나리오 테스트
4. **사용자 경험**: 로딩 상태 표시 및 에러 메시지 확인