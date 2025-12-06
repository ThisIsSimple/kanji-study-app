# Quiz Shorts Video Generator

일본어 퀴즈 쇼츠 영상 생성 API

## 개요

n8n 워크플로우에서 퀴즈 데이터를 받아 YouTube Shorts용 23초 영상을 생성합니다.

### 영상 구성

- **0-3초**: 인트로 (퀴즈 유형, JLPT 레벨)
- **3-13초**: 문제 + 4개 선택지 + 10초 카운트다운
- **13-20초**: 정답 공개 + 해설

### 영상 스펙

- 해상도: 1080x1920 (9:16 세로형)
- 길이: 20초
- FPS: 30
- 코덱: H.264 (libx264)
- 포맷: MP4

## 설치 및 실행

### 로컬 개발

```bash
# 가상 환경 생성
python -m venv venv
source venv/bin/activate  # Windows: venv\Scripts\activate

# 의존성 설치
pip install -r requirements.txt

# 환경 변수 설정
cp .env.example .env
# .env 파일 편집

# 서버 실행
python main.py
```

### Docker

```bash
# 이미지 빌드
docker build -t quiz-shorts-generator .

# 컨테이너 실행
docker run -p 8080:8080 \
  -e DEBUG_SAVE_VIDEO=true \
  -e STORAGE_TYPE=local \
  -v $(pwd)/output:/app/output \
  quiz-shorts-generator
```

### Cloud Run 배포

```bash
# 이미지 빌드 및 푸시
gcloud builds submit --tag gcr.io/YOUR_PROJECT/quiz-shorts-generator

# Cloud Run 배포
gcloud run deploy quiz-shorts-generator \
  --image gcr.io/YOUR_PROJECT/quiz-shorts-generator \
  --platform managed \
  --region asia-northeast3 \
  --allow-unauthenticated \
  --memory 2Gi \
  --cpu 2 \
  --timeout 300 \
  --set-env-vars "DEBUG_SAVE_VIDEO=false"
```

## API 엔드포인트

### `GET /health`

헬스체크

```bash
curl http://localhost:8080/health
```

### `POST /generate`

영상 생성 (MP4 바이너리 반환)

```bash
curl -X POST http://localhost:8080/generate \
  -H "Content-Type: application/json" \
  -d '{
    "question": {
      "id": 1,
      "question": "勉強",
      "options": ["공부", "운동", "독서", "여행"],
      "correct_answer": "공부",
      "explanation": "勉(힘쓸 면) + 強(강할 강) = 공부하다",
      "jlpt_level": 3,
      "quiz_type": "jp_to_kr"
    }
  }' \
  --output quiz_1.mp4
```

### `POST /generate-json`

영상 생성 (JSON 메타데이터 반환)

```bash
curl -X POST http://localhost:8080/generate-json \
  -H "Content-Type: application/json" \
  -d '{
    "question": {
      "id": 1,
      "question": "勉強",
      "options": ["공부", "운동", "독서", "여행"],
      "correct_answer": "공부",
      "explanation": "勉(힘쓸 면) + 強(강할 강) = 공부하다",
      "jlpt_level": 3,
      "quiz_type": "jp_to_kr"
    }
  }'
```

### `GET /storage-info`

저장소 설정 확인

```bash
curl http://localhost:8080/storage-info
```

## 환경 변수

| 변수 | 설명 | 기본값 |
|------|------|--------|
| `HOST` | 서버 호스트 | `0.0.0.0` |
| `PORT` | 서버 포트 | `8080` |
| `DEBUG_SAVE_VIDEO` | 디버깅용 영상 저장 | `false` |
| `STORAGE_TYPE` | 저장소 유형 (`local`/`gcs`) | `local` |
| `OUTPUT_DIR` | 로컬 저장 경로 | `./output` |
| `GCS_BUCKET` | GCS 버킷 이름 | - |

## 퀴즈 유형

| 유형 | 값 | 설명 |
|------|-----|------|
| 일→한 | `jp_to_kr` | 일본어 단어의 한국어 뜻 맞추기 |
| 한→일 | `kr_to_jp` | 한국어 뜻의 일본어 단어 맞추기 |
| 한자읽기 | `kanji_reading` | 한자의 후리가나 맞추기 |
| 빈칸채우기 | `fill_blank` | 문장의 빈칸에 들어갈 단어 맞추기 |

## n8n 연동

### HTTP Request 노드 설정

1. **Method**: POST
2. **URL**: `https://your-cloud-run-url/generate`
3. **Body Content Type**: JSON
4. **Body**:
```json
{
  "question": {
    "id": {{ $json.id }},
    "question": "{{ $json.question }}",
    "options": {{ $json.options }},
    "correct_answer": "{{ $json.correct_answer }}",
    "explanation": "{{ $json.explanation }}",
    "jlpt_level": {{ $json.jlpt_level }},
    "quiz_type": "{{ $json.quiz_type }}"
  }
}
```
5. **Response Format**: File

### 전체 워크플로우

```
Supabase (퀴즈 조회)
    ↓
HTTP Request (영상 생성)
    ↓
Google Drive (업로드)
    ↓
YouTube Shorts (게시)
```

## 폰트

일본어/한자 표시를 위해 **Noto Sans CJK** 폰트를 사용하는 것을 권장합니다.

### 폰트 설치 방법

#### 방법 1: Noto Sans CJK 다운로드 (권장)

1. **Google Fonts에서 다운로드:**
   - https://fonts.google.com/noto/specimen/Noto+Sans+JP
   - 또는 직접 다운로드: https://github.com/google/fonts/tree/main/ofl/notosanscjksc

2. **프로젝트에 폰트 추가:**
   ```bash
   # assets/fonts 폴더에 폰트 파일 복사
   cp ~/Downloads/NotoSansCJK-*.ttc assets/fonts/
   ```

3. **지원되는 폰트 파일명:**
   - `NotoSansCJK-Regular.ttc` / `NotoSansCJK-Bold.ttc`
   - `NotoSansCJKjp-Regular.otf` / `NotoSansCJKjp-Bold.otf`
   - `NotoSansJP-Regular.ttf` / `NotoSansJP-Bold.ttf`

#### 방법 2: 시스템 폰트 사용 (macOS)

macOS의 경우 Hiragino 폰트가 자동으로 사용됩니다. 하지만 배포 시 일관성을 위해 프로젝트에 폰트를 포함하는 것을 권장합니다.

### 폰트 우선순위

1. `assets/fonts/` 폴더의 Noto Sans CJK
2. `assets/fonts/` 폴더의 기타 일본어 폰트
3. 시스템 폰트 (macOS Hiragino 등)
4. 기본 폰트 (일본어 미지원, 글자가 깨질 수 있음)

## 라이선스

MIT License
