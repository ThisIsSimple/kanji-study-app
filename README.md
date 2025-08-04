# 한자 학습 앱 (Kanji Study App)

일본어 한자를 체계적으로 학습할 수 있는 Flutter 앱입니다.

## 주요 기능

### 📚 2136개 한자 데이터베이스
- 상용한자 2136자 전체 수록
- 음독/훈독 구분
- JLPT 레벨별 분류 (N1~N5)
- 학년별 분류 (1~7학년)
- 빈도순 정렬

### 🔔 매일 학습 알림
- 설정한 시간에 매일 알림
- 학습하지 않은 한자 우선 추천
- 빈도가 높은 한자부터 학습

### 📊 학습 진도 관리
- 학습한 한자 기록
- 마스터한 한자 표시
- 전체 진도율 확인

### 🎨 미니멀한 디자인
- Forui UI 라이브러리 사용
- 깔끔하고 직관적인 인터페이스
- 다크/라이트 테마 지원 (zinc 테마)
- Noto Serif Japanese 폰트로 한자 표시

### 🤖 AI 기능
- Gemini API를 통한 예문 자동 생성
- 일본어/히라가나/한국어 번역 제공
- 향후 시험 문제 생성 기능 추가 예정

### ☁️ 클라우드 동기화
- Supabase를 통한 학습 진도 동기화
- 여러 기기에서 학습 이어하기
- 안전한 사용자 인증

## 기술 스택

- **Frontend**: Flutter 3.8.1+
- **UI Library**: Forui 0.14.1
- **State Management**: SharedPreferences
- **Notifications**: flutter_local_notifications
- **Data Source**: Excel → JSON 변환
- **Backend**: Supabase (Authentication, Database, Storage)
- **AI Integration**: Google Gemini API (예문 생성)
- **Fonts**: Google Fonts (Noto Serif Japanese)

## 설치 및 실행

### 요구사항
- Flutter 3.8.1 이상
- Dart 3.0 이상
- iOS 12.0+ / Android 6.0 (API 23)+

### 실행 방법

```bash
# 프로젝트 클론
git clone [repository-url]
cd kanji/kanji_study_app

# 의존성 설치
flutter pub get

# 앱 실행
flutter run
```

## 프로젝트 구조

```
kanji_study_app/
├── lib/
│   ├── main.dart              # 앱 진입점
│   ├── models/                # 데이터 모델
│   │   ├── kanji_model.dart   # 한자 데이터 모델
│   │   └── user_progress.dart # 사용자 진도 모델
│   ├── screens/               # 화면
│   │   ├── home_screen.dart   # 홈 화면
│   │   ├── study_screen.dart  # 학습 화면
│   │   ├── settings_screen.dart # 설정 화면
│   │   ├── main_screen.dart     # 바텀 네비게이션
│   │   ├── words_screen.dart    # 단어 목록 화면
│   │   ├── profile_screen.dart  # 프로필 화면
│   │   └── auth_screen.dart     # 로그인/회원가입 화면
│   ├── services/              # 서비스
│   │   ├── kanji_repository.dart    # 한자 데이터 저장소
│   │   ├── kanji_service.dart       # 한자 비즈니스 로직
│   │   ├── notification_service.dart # 알림 서비스
│   │   ├── gemini_service.dart      # AI 예문 생성 서비스
│   │   └── supabase_service.dart    # 클라우드 동기화 서비스
│   └── config/                # 설정
│       └── supabase_config.dart # Supabase 설정
├── assets/
│   └── data/
│       └── kanji_data.json    # 한자 데이터 (2136자)
└── pubspec.yaml               # 프로젝트 설정

```

## 데이터 변환

Excel 파일에서 JSON으로 한자 데이터를 변환하는 Python 스크립트가 포함되어 있습니다.

```bash
# Python 의존성 설치
pip install pandas openpyxl

# Excel → JSON 변환
python convert_kanji_excel_to_json.py
```

## 라이선스

이 프로젝트는 개인 학습 목적으로 제작되었습니다.

## 기여

버그 리포트, 기능 제안, Pull Request를 환영합니다!