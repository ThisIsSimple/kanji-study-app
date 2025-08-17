# Supabase Google OAuth 설정 가이드

## 현재 상황
Google Sign-In이 성공적으로 Google 계정 인증을 받았지만, Supabase에서 "Unacceptable audience in id_token" 오류가 발생합니다. 이는 Supabase 프로젝트에 Google OAuth provider 설정이 필요하기 때문입니다.

## 설정 단계

### 1. Supabase Dashboard 접속
1. https://supabase.com/dashboard 로 이동
2. 해당 프로젝트 선택

### 2. Google Provider 활성화
1. 왼쪽 메뉴에서 **Authentication** 클릭
2. **Providers** 탭 선택
3. **Google** 찾아서 **Enable** 토글 ON

### 3. Google OAuth 정보 입력

#### Client ID와 Secret 설정
- **Client ID (for Web)**: 
  ```
  276747789159-ghmuf8ndkr8sse0i2n53jalj30ig99rk.apps.googleusercontent.com
  ```
  
- **Client Secret**: 
  Firebase Console에서 확인 필요 (아래 참조)

#### Authorized Client IDs 추가
iOS 클라이언트 ID를 추가해야 합니다:
```
276747789159-1anmlunhqqjhr57fsp0s31m633rvuc5s.apps.googleusercontent.com
```

### 4. Firebase Console에서 Client Secret 확인
1. https://console.firebase.google.com 접속
2. **kanji-study-app-469316** 프로젝트 선택
3. **Authentication** → **Sign-in method** → **Google** 클릭
4. **Web SDK configuration** 섹션 확장
5. **Web client secret** 복사

### 5. Supabase Redirect URL 설정
Supabase에서 제공하는 Redirect URL을 Firebase에 추가:
1. Supabase Dashboard에서 Google provider 설정 페이지 하단의 **Redirect URL** 복사
   (형식: `https://[PROJECT_ID].supabase.co/auth/v1/callback`)
2. Firebase Console → Authentication → Sign-in method → Google
3. **Authorized redirect URIs**에 추가

## 현재 프로젝트 정보

### Firebase Project
- **Project ID**: kanji-study-app-469316
- **Project Number**: 276747789159

### OAuth 2.0 Client IDs
- **Web Client**: 276747789159-ghmuf8ndkr8sse0i2n53jalj30ig99rk.apps.googleusercontent.com
- **iOS Client**: 276747789159-1anmlunhqqjhr57fsp0s31m633rvuc5s.apps.googleusercontent.com

### Bundle ID
- **iOS**: space.cordelia273.kanjiStudyApp

## 테스트 확인사항
설정 완료 후 다음을 확인:
1. Supabase Dashboard에서 Google provider가 활성화됨
2. Client ID와 Secret이 올바르게 입력됨
3. Authorized Client IDs에 iOS 클라이언트 ID가 추가됨
4. 앱에서 Google Sign-In 재시도

## 디버그 로그 확인
현재 로그에서 확인된 내용:
- ✅ Google Sign-In 성공: cordelia2731@gmail.com
- ✅ Access token 및 ID token 획득
- ❌ Supabase 인증 실패: Unacceptable audience in id_token

이는 Supabase가 Google OAuth token을 검증할 수 없기 때문이며, 위 설정을 완료하면 해결됩니다.