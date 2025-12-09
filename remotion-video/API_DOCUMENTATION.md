# Remotion Quiz Video API 문서

## 개요

이 API는 일본어 퀴즈 문제 데이터를 받아서 Remotion을 사용하여 동영상(MP4)을 생성하고 반환하는 서버입니다. 생성된 영상은 인트로, 문제 화면, 정답 화면, 계정 정보 화면으로 구성되어 있습니다.

## 기본 정보

- **Base URL**: `http://localhost:8080` (로컬 개발) 또는 Cloud Run 배포 URL
- **Content-Type**: `application/json` (요청), `video/mp4` (응답)
- **타임아웃**: 60초 (렌더링 시간 고려)

## 엔드포인트

### 1. 헬스 체크

**GET** `/health`

서버 상태를 확인하는 엔드포인트입니다.

#### 응답

```json
{
  "status": "ok",
  "timestamp": "2024-12-06T10:30:00.000Z"
}
```

---

### 2. 영상 렌더링

**POST** `/render`

퀴즈 문제 데이터를 받아서 영상을 생성하고 반환합니다.

#### 요청 본문 (Request Body)

요청 본문은 JSON 형식이며, `QuizQuestion` 타입의 객체를 전달해야 합니다.

```json
{
  "id": 1,
  "question": "勉強",
  "options": ["운동", "독서", "공부", "여행"],
  "correct_answer": "공부",
  "explanation": "勉(힘쓸 면) + 強(강할 강) = 공부하다",
  "jlpt_level": 3,
  "quiz_type": "jp_to_kr"
}
```

#### 필드 상세 설명

| 필드명 | 타입 | 필수 | 설명 |
|--------|------|------|------|
| `id` | `number` | 선택 | 퀴즈 문제의 고유 식별자. 응답 파일명에 사용됩니다. 제공하지 않으면 타임스탬프가 사용됩니다. |
| `question` | `string` | **필수** | 문제로 표시될 텍스트. 일본어 단어, 한자, 또는 문제 문장이 올 수 있습니다. 예: `"勉強"`, `"次の単語の意味は？"` |
| `options` | `[string, string, string, string]` | **필수** | 정답을 포함한 4개의 선택지 배열. 정확히 4개의 요소가 있어야 합니다. 각 선택지는 화면에 ①, ②, ③, ④ 라벨과 함께 표시됩니다. |
| `correct_answer` | `string` | **필수** | 정답 문자열. `options` 배열의 요소 중 하나와 정확히 일치해야 합니다. |
| `explanation` | `string` | 필수 | 정답에 대한 해설. 한자 구성, 어원, 의미 등을 설명합니다. 예: `"勉(힘쓸 면) + 強(강할 강) = 공부하다"` |
| `jlpt_level` | `number \| null` | 선택 | 일본어능력시험 레벨 (1-5). `null`이면 JLPT 레벨 표시가 생략됩니다. |
| `quiz_type` | `QuizType` | 필수 | 퀴즈 유형. 다음 중 하나여야 합니다: `"jp_to_kr"`, `"kr_to_jp"`, `"kanji_reading"`, `"fill_blank"` |

#### QuizType 상세

| 값 | 표시명 | 설명 |
|----|--------|------|
| `"jp_to_kr"` | 단어의 뜻 | 일본어 단어의 한국어 뜻을 묻는 문제 |
| `"kr_to_jp"` | 뜻의 단어 | 한국어 뜻에 해당하는 일본어 단어를 묻는 문제 |
| `"kanji_reading"` | 한자읽기 | 한자의 읽기(음독/훈독)를 묻는 문제 |
| `"fill_blank"` | 빈칸채우기 | 빈칸에 들어갈 단어를 묻는 문제 |

#### 요청 예제

```bash
curl -X POST http://localhost:8080/render \
  -H "Content-Type: application/json" \
  -d '{
    "id": 1,
    "question": "勉強",
    "options": ["운동", "독서", "공부", "여행"],
    "correct_answer": "공부",
    "explanation": "勉(힘쓸 면) + 強(강할 강) = 공부하다",
    "jlpt_level": 3,
    "quiz_type": "jp_to_kr"
  }' \
  --output quiz-video.mp4
```

#### 성공 응답

- **Status Code**: `200 OK`
- **Content-Type**: `video/mp4`
- **Content-Disposition**: `attachment; filename="quiz-video-{id}.mp4"`
- **Body**: MP4 비디오 파일 (바이너리 스트림)

응답은 생성된 영상 파일의 바이너리 데이터입니다. 파일을 저장하거나 직접 재생할 수 있습니다.

#### 에러 응답

##### 400 Bad Request - 잘못된 요청 데이터

```json
{
  "error": "Invalid request body",
  "message": "Missing required fields: question, options, correct_answer"
}
```

또는

```json
{
  "error": "Invalid request body",
  "message": "options must be an array with exactly 4 elements"
}
```

**발생 조건**:
- 필수 필드(`question`, `options`, `correct_answer`)가 누락된 경우
- `options`가 배열이 아니거나 정확히 4개의 요소를 가지지 않는 경우

##### 500 Internal Server Error - 렌더링 실패

```json
{
  "error": "Rendering failed",
  "message": "Error message details"
}
```

**발생 조건**:
- Remotion 렌더링 과정에서 오류가 발생한 경우
- 파일 시스템 오류
- 메모리 부족 등

##### 504 Gateway Timeout - 타임아웃

```json
{
  "error": "Rendering failed",
  "message": "Rendering timeout after 60000ms"
}
```

**발생 조건**:
- 렌더링이 60초 내에 완료되지 않은 경우

## 영상 구성

생성된 영상은 다음과 같은 구조로 구성됩니다:

1. **인트로 화면** (0-3초)
   - 퀴즈 제목: "🇯🇵 일본어 퀴즈"
   - 문제 텍스트 (큰 글씨)
   - JLPT 레벨 (있는 경우)
   - 퀴즈 유형 뱃지

2. **문제 화면** (3-13초)
   - 문제 텍스트
   - 4개의 선택지 (①, ②, ③, ④)
   - 카운트다운 타이머 (10초부터 1초까지)
   - 각 초마다 tick 사운드 재생

3. **정답 화면** (13-18초)
   - 정답 표시 (라벨 + 정답 텍스트)
   - 해설 영역 (배경이 있는 박스)
   - correct 사운드 재생

4. **계정 정보 화면** (18-23초)
   - 앱 계정 정보 표시

**전체 길이**: 23초  
**해상도**: 1080x1920 (세로형, 모바일 최적화)  
**FPS**: 30  
**배경음악**: ukulele.mp3 (전체 재생, 볼륨 30%)

## 타입 정의 (TypeScript)

```typescript
type QuizType = 'jp_to_kr' | 'kr_to_jp' | 'kanji_reading' | 'fill_blank';

interface QuizQuestion {
  id: number;
  question: string;
  options: [string, string, string, string]; // 정확히 4개
  correct_answer: string;
  explanation: string;
  jlpt_level: number | null; // 1-5 또는 null
  quiz_type: QuizType;
}
```

## 사용 예제

### JavaScript/TypeScript

```typescript
async function generateQuizVideo(questionData: QuizQuestion): Promise<Blob> {
  const response = await fetch('http://localhost:8080/render', {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
    },
    body: JSON.stringify(questionData),
  });

  if (!response.ok) {
    const error = await response.json();
    throw new Error(`Rendering failed: ${error.message}`);
  }

  return await response.blob();
}

// 사용 예제
const question: QuizQuestion = {
  id: 1,
  question: '勉強',
  options: ['운동', '독서', '공부', '여행'],
  correct_answer: '공부',
  explanation: '勉(힘쓸 면) + 強(강할 강) = 공부하다',
  jlpt_level: 3,
  quiz_type: 'jp_to_kr',
};

const videoBlob = await generateQuizVideo(question);
const videoUrl = URL.createObjectURL(videoBlob);
// videoUrl을 사용하여 비디오 재생 또는 다운로드
```

### Python

```python
import requests

def generate_quiz_video(question_data):
    url = "http://localhost:8080/render"
    response = requests.post(url, json=question_data, stream=True)
    
    if response.status_code != 200:
        error = response.json()
        raise Exception(f"Rendering failed: {error['message']}")
    
    return response.content

# 사용 예제
question = {
    "id": 1,
    "question": "勉強",
    "options": ["운동", "독서", "공부", "여행"],
    "correct_answer": "공부",
    "explanation": "勉(힘쓸 면) + 強(강할 강) = 공부하다",
    "jlpt_level": 3,
    "quiz_type": "jp_to_kr"
}

video_data = generate_quiz_video(question)

# 파일로 저장
with open("quiz-video.mp4", "wb") as f:
    f.write(video_data)
```

## 주의사항

1. **타임아웃**: 렌더링은 최대 60초까지 소요될 수 있습니다. 클라이언트에서 충분한 타임아웃을 설정하세요.

2. **파일 크기**: 생성된 영상 파일은 일반적으로 5-20MB 정도입니다. 네트워크 대역폭을 고려하세요.

3. **동시 요청**: 여러 요청을 동시에 보낼 수 있지만, 각 요청은 독립적으로 처리되며 서버 리소스에 따라 처리 시간이 달라질 수 있습니다.

4. **데이터 검증**: 
   - `correct_answer`는 반드시 `options` 배열의 요소 중 하나와 정확히 일치해야 합니다.
   - `options`는 정확히 4개의 요소를 가져야 합니다.
   - `question`과 `explanation`은 빈 문자열이 아니어야 합니다.

5. **JLPT 레벨**: `jlpt_level`은 1-5 사이의 정수이거나 `null`이어야 합니다. 다른 값이 전달되면 예상치 못한 동작이 발생할 수 있습니다.

## 에러 처리 권장사항

클라이언트에서는 다음과 같이 에러를 처리하는 것을 권장합니다:

```typescript
try {
  const response = await fetch('/render', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(questionData),
  });

  if (!response.ok) {
    if (response.status === 400) {
      // 잘못된 요청 데이터
      const error = await response.json();
      console.error('Validation error:', error.message);
    } else if (response.status === 504) {
      // 타임아웃
      console.error('Rendering timeout');
    } else {
      // 기타 서버 오류
      const error = await response.json();
      console.error('Server error:', error.message);
    }
    return;
  }

  // 성공: 비디오 데이터 처리
  const blob = await response.blob();
  // blob 처리...
} catch (error) {
  console.error('Network error:', error);
}
```

## 추가 정보

- 서버는 Cloud Run에 배포되어 실행됩니다.
- 로컬 개발 환경에서는 `http://localhost:8080`에서 접근 가능합니다.
- 프로덕션 환경에서는 Cloud Run이 제공하는 URL을 사용합니다.

