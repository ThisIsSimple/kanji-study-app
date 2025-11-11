# 콘나칸지 (こんな漢字)

일본어 공부, 바로 이런 느낌!

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

📋 Android SHA-1 인증서 정보

  Debug 키 (개발용)

  - SHA-1: 93:8E:25:AE:EF:4F:B4:18:10:B8:50:1C:07:16:BE:C6:6B:F1:F9:D9
  - SHA-256: 10:83:0B:7A:4D:99:F9:01:01:E1:31:82:48:17:03:AE:F6:B1:5C:33:FF:
  08:71:40:AB:30:7D:1D:11:CF:4B:C3
  - 유효기간: 2053년 9월 17일까지

  Google Cloud Console 설정 단계

  1. https://console.cloud.google.com/에 접속
  2. Android OAuth 2.0 클라이언트 ID 생성:
    - APIs & Services > Credentials 이동
    - "Create Credentials" > "OAuth client ID" 선택
    - Application type: Android 선택
    - 다음 정보 입력:
        - Name: 콘나칸지 Android
      - Package name: space.cordelia273.konnakanji
      - SHA-1 certificate fingerprint:
  93:8E:25:AE:EF:4F:B4:18:10:B8:50:1C:07:16:BE:C6:6B:F1:F9:D9
  3. google-services.json 파일 다운로드:
    - OAuth 2.0 클라이언트 생성 후 다운로드
    - android/app/ 폴더에 저장

  Release 키 생성 (프로덕션용)

  나중에 앱을 출시할 때는 Release 키를 생성해야 합니다:

  # Release 키 생성 (예시)
  keytool -genkey -v -keystore ~/upload-keystore.jks -keyalg RSA -keysize
  2048 -validity 10000 -alias upload

  # Release SHA-1 확인
  keytool -list -v -keystore ~/upload-keystore.jks -alias upload

  Kakao Developers 설정

  Kakao 로그인을 위해서도 이 키 해시가 필요합니다:

  # Kakao용 키 해시 생성
  keytool -exportcert -alias AndroidDebugKey -keystore
  ~/.android/debug.keystore -storepass android -keypass android | openssl
  sha1 -binary | openssl base64