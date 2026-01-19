# SNS Image Generator

Satori + Sharp 기반의 SNS 이미지 생성 서버입니다. 인스타그램 4:5 비율(1080x1350px)의 학습 자료 이미지를 생성합니다.

## 기술 스택

- **Fastify**: 고성능 웹 프레임워크
- **Satori**: JSX를 SVG로 렌더링
- **Sharp**: SVG를 PNG로 변환
- **TypeScript**: 타입 안전성

## 설치

```bash
npm install
```

## 실행

```bash
# 개발 모드 (핫 리로드)
npm run dev

# 프로덕션 빌드
npm run build

# 프로덕션 실행
npm start
```

## API 엔드포인트

### GET /health
헬스 체크

### GET /presets
지원하는 프리셋 목록 조회

### POST /generate
이미지 생성

## 지원 프리셋

### 1. 한자 학습 (`kanji`)

```json
{
  "type": "kanji",
  "data": {
    "cover": {
      "word": "勉強",
      "yomigana": "べんきょう",
      "meaning": "공부"
    },
    "intro": {
      "kanji": [
        { "kanji": "勉", "korean": "힘쓸 면" },
        { "kanji": "強", "korean": "강할 강" }
      ],
      "meaning": "힘써서 강해지다 → 공부하다"
    },
    "main": [
      {
        "equation": "勉(힘쓰다) + 強(강하다) = 勉強(공부)",
        "explanation": "힘을 써서 강해진다는 의미로, 노력해서 배우는 것을 뜻합니다."
      }
    ],
    "additional": [
      {
        "kanji": "勉",
        "examples": [
          { "word": "勉強", "equation": "공부", "level": "N5" },
          { "word": "勤勉", "equation": "근면", "level": "N2" }
        ]
      }
    ],
    "outro": {}
  }
}
```

### 2. 가사 해석 (`lyrics`)

```json
{
  "type": "lyrics",
  "data": {
    "cover": {
      "artist": "Vaundy",
      "korean_title": "편지",
      "title": "置き手紙"
    },
    "intro": {
      "lyrics": "君がいない朝は\n何も始まらない",
      "meaning": "네가 없는 아침은\n아무것도 시작되지 않아"
    },
    "objective": {
      "title": "~がいない 표현",
      "subtitle": "'~가 없다'를 나타내는 존재 부정 표현을 배워봅시다"
    },
    "main": [
      {
        "number": 1,
        "sentence": "君がいない朝は",
        "content": "~がいない: ~가 없다 (사람/동물)",
        "explanation": "いる의 부정형으로, 생물의 부재를 나타냅니다."
      }
    ],
    "summary": {
      "content": "~がいない는 사람이나 동물이 없음을 표현\n~がない는 사물이 없음을 표현"
    },
    "quiz": {
      "sentence": "君がいない朝は",
      "questions": [
        { "content": "'いない'의 기본형은?" },
        { "content": "'朝'의 읽는 법은?" }
      ]
    },
    "outro": {}
  }
}
```

## 출력

생성된 이미지는 `output/` 폴더에 타임스탬프 기반으로 저장됩니다.

```
output/
  kanji_1737123456789/
    01_cover.png
    02_intro.png
    03_main_01.png
    04_additional_01.png
    05_outro.png
```

## 폰트

`fonts/` 폴더에 다음 폰트가 필요합니다:
- SUITE (Regular, Medium, SemiBold, Bold, ExtraBold)
- SpoqaHanSansNeo (Regular, Bold)

## 환경 변수

| 변수 | 기본값 | 설명 |
|------|--------|------|
| PORT | 3000 | 서버 포트 |
| HOST | 0.0.0.0 | 서버 호스트 |
