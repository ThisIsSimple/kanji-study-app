# OAuth 리다이렉션 설정 가이드

## 문제 상황
프로덕션 환경에서 SNS 로그인(Google, Apple, Kakao) 시 localhost로 리다이렉션되어 로그인이 실패하는 문제

## 해결 방법

### 1. Supabase 콘솔 설정 (필수)

#### 1.1 Supabase 대시보드 접속
1. [Supabase Dashboard](https://app.supabase.com) 접속
2. 프로젝트 선택

#### 1.2 리다이렉션 URL 추가
1. 좌측 메뉴에서 **Authentication** 클릭
2. **URL Configuration** 탭 선택
3. **Redirect URLs** 섹션에서 다음 URL들을 추가:

```
개발 환경 (선택사항):
http://localhost:3000/auth/callback

프로덕션 환경 (필수):
io.supabase.kanji://login-callback
```

4. **Save** 버튼 클릭

#### 1.3 OAuth 제공자별 설정 확인

**Google**:
- Authentication → Providers → Google
- Authorized redirect URIs에 `io.supabase.kanji://login-callback` 포함 확인

**Apple**:
- Authentication → Providers → Apple
- Return URLs에 `io.supabase.kanji://login-callback` 포함 확인

**Kakao**:
- Authentication → Providers → Kakao
- Redirect URL에 `io.supabase.kanji://login-callback` 포함 확인

### 2. 코드 레벨 수정 (완료됨)

#### 2.1 환경별 리다이렉션 URL 자동 감지
`lib/services/supabase_service.dart`에 추가됨:
- 개발 환경(Debug 모드): 플랫폼에 따라 localhost 또는 앱 스키마 사용
- 프로덕션 환경(Release 모드): 항상 앱 스키마 사용 (`io.supabase.kanji://login-callback`)

#### 2.2 Kakao OAuth에 명시적 리다이렉션 URL 설정
`signInWithOAuth` 호출 시 `redirectTo` 파라미터 추가

### 3. 플랫폼별 설정 (이미 완료됨)

#### iOS (Info.plist)
```xml
<key>CFBundleURLTypes</key>
<array>
  <dict>
    <key>CFBundleURLSchemes</key>
    <array>
      <string>io.supabase.kanji</string>
    </array>
  </dict>
</array>
```

#### Android (AndroidManifest.xml)
```xml
<intent-filter android:autoVerify="true">
  <action android:name="android.intent.action.VIEW" />
  <category android:name="android.intent.category.DEFAULT" />
  <category android:name="android.intent.category.BROWSABLE" />
  <data
      android:scheme="io.supabase.kanji"
      android:host="login-callback" />
</intent-filter>
```

## 테스트 방법

### 로컬 개발 환경
1. Debug 모드로 앱 실행: `flutter run`
2. SNS 로그인 시도
3. 정상적으로 로그인되는지 확인

### 프로덕션 환경
1. Release 빌드 생성:
   - iOS: `flutter build ios --release`
   - Android: `flutter build apk --release`
2. TestFlight 또는 실제 디바이스에 설치
3. SNS 로그인 시도
4. 앱 스키마로 리다이렉션되어 정상 로그인되는지 확인

## 문제 해결

### 여전히 localhost로 리다이렉션되는 경우
1. Supabase 콘솔의 Redirect URLs 설정 재확인
2. 앱 재빌드 및 재설치
3. Supabase 캐시 클리어 (앱 삭제 후 재설치)

### OAuth 제공자 오류
1. 각 제공자(Google, Apple, Kakao) 콘솔에서 리다이렉션 URL 확인
2. 앱 번들 ID/패키지명이 일치하는지 확인
3. API 키 및 설정이 올바른지 확인

## 참고사항

### 환경 감지 로직
- `kDebugMode`: Flutter의 Debug/Release 모드 감지
- `kIsWeb`: 웹 플랫폼 여부 감지
- 개발 환경에서는 웹과 모바일을 구분하여 적절한 URL 사용
- 프로덕션에서는 항상 앱 스키마 사용

### SNS 로그인별 특징
- **Google/Apple**: 네이티브 SDK 사용, `signInWithIdToken`으로 토큰 직접 전달
  - OAuth 리다이렉션 URL에 덜 의존적
  - 대부분 정상 작동
- **Kakao**: OAuth 표준 사용, `signInWithOAuth` 사용
  - Supabase 리다이렉션 URL 설정에 완전히 의존
  - 가장 문제가 발생하기 쉬움
  - 이번 수정으로 명시적 URL 설정 추가됨
