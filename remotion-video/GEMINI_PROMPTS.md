# Gemini Structured Output 프롬프트

이 문서는 Gemini API의 structured output 기능을 사용하여 단어 데이터를 퀴즈 문제 형식으로 변환하는 프롬프트를 제공합니다.

## 공통 설정

모든 프롬프트는 다음 JSON Schema를 사용합니다:

```json
{
  "type": "object",
  "properties": {
    "id": {
      "type": "number",
      "description": "퀴즈 문제의 고유 식별자 (원본 단어의 id 사용)"
    },
    "question": {
      "type": "string",
      "description": "문제로 표시될 텍스트"
    },
    "options": {
      "type": "array",
      "items": {
        "type": "string"
      },
      "minItems": 4,
      "maxItems": 4,
      "description": "정답을 포함한 4개의 선택지"
    },
    "correct_answer": {
      "type": "string",
      "description": "정답 문자열 (options 배열의 요소 중 하나와 정확히 일치해야 함)"
    },
    "explanation": {
      "type": "string",
      "description": "정답에 대한 해설 (한자 구성, 어원, 의미 등을 설명)"
    },
    "jlpt_level": {
      "type": ["number", "null"],
      "description": "일본어능력시험 레벨 (1-5) 또는 null"
    },
    "quiz_type": {
      "type": "string",
      "enum": ["jp_to_kr", "kr_to_jp", "kanji_reading"],
      "description": "퀴즈 유형"
    }
  },
  "required": ["id", "question", "options", "correct_answer", "explanation", "quiz_type"]
}
```

---

## 1. jp_to_kr (일본어 단어의 뜻)

### 프롬프트

```
당신은 일본어 학습 퀴즈 문제를 생성하는 전문가입니다.

주어진 단어 데이터를 기반으로 "일본어 단어의 한국어 뜻을 고르는" 문제를 생성하세요.

**입력 데이터 형식:**
{
  "id": number,
  "word": string,           // 일본어 단어 (한자 포함 가능)
  "reading": string,        // 읽기 (히라가나/가타카나)
  "meanings": [
    {
      "meaning": string,    // 한국어 뜻
      "part_of_speech": string  // 품사
    }
  ],
  "jlpt_level": number | null
}

**출력 요구사항:**
1. question: 일본어 단어를 그대로 사용 (word 필드 값)
2. options: 한국어 뜻 4개 (정답 1개 + 오답 3개)
   - 정답: meanings 배열의 첫 번째 meaning 사용
   - 오답: 같은 JLPT 레벨의 다른 단어들의 뜻에서 선택하거나, 유사한 의미의 단어들로 구성
   - 오답은 정답과 구분되지만 그럴듯한 선택지여야 함
   - **중요: 정답의 위치는 1번, 2번, 3번, 4번 중 랜덤하게 배치해야 함 (항상 첫 번째 위치에 두지 말 것)**
3. correct_answer: 정답의 meaning 값
4. explanation: 한자가 있다면 한자 구성 설명, 없다면 단어의 어원이나 의미 설명
   - 형식: "({reading})\n한자(읽기 한자) + 한자(읽기 한자) = 의미" 또는 "({reading})\n단어의 의미 설명"
   - 반드시 읽기(reading 필드 값)를 포함해야 하고, 읽기 뒤에 줄바꿈(\n)을 넣어야 함
   - 줄바꿈은 실제 \n 문자로 표시해야 함
5. jlpt_level: 입력 데이터의 jlpt_level 그대로 사용
6. quiz_type: "jp_to_kr"

**예시:**
입력:
{
  "id": 2393,
  "word": "抱っこ",
  "reading": "だっこ",
  "meanings": [{"meaning": "안음; 안김.", "part_of_speech": "명사"}],
  "jlpt_level": 3
}

출력:
{
  "id": 2393,
  "question": "抱っこ",
  "options": ["안음; 안김.", "포옹", "키스", "손잡기"],
  "correct_answer": "안음; 안김.",
  "explanation": "(だっこ)\n抱(안을 포) = 안다, 안기다",
  "jlpt_level": 3,
  "quiz_type": "jp_to_kr"
}

**중요 규칙:**
- options는 반드시 정확히 4개여야 함
- correct_answer는 options 배열의 요소 중 하나와 정확히 일치해야 함
- **정답의 위치는 1번, 2번, 3번, 4번 중 랜덤하게 배치해야 함 (항상 첫 번째 위치에 두지 말 것)**
- explanation은 한자가 있으면 한자 구성 설명, 없으면 의미 설명
- 오답 선택지는 같은 JLPT 레벨의 단어들에서 선택하거나, 유사한 의미의 단어로 구성
```

### JSON Schema

```json
{
  "type": "object",
  "properties": {
    "id": {"type": "number"},
    "question": {"type": "string"},
    "options": {
      "type": "array",
      "items": {"type": "string"},
      "minItems": 4,
      "maxItems": 4
    },
    "correct_answer": {"type": "string"},
    "explanation": {"type": "string"},
    "jlpt_level": {"type": ["number", "null"]},
    "quiz_type": {"type": "string", "enum": ["jp_to_kr"]}
  },
  "required": ["id", "question", "options", "correct_answer", "explanation", "quiz_type"]
}
```

---

## 2. kr_to_jp (뜻의 단어)

### 프롬프트

```
당신은 일본어 학습 퀴즈 문제를 생성하는 전문가입니다.

주어진 단어 데이터를 기반으로 "한국어 뜻에 해당하는 일본어 단어를 고르는" 문제를 생성하세요.

**입력 데이터 형식:**
{
  "id": number,
  "word": string,           // 일본어 단어 (한자 포함 가능)
  "reading": string,        // 읽기 (히라가나/가타카나)
  "meanings": [
    {
      "meaning": string,    // 한국어 뜻
      "part_of_speech": string  // 품사
    }
  ],
  "jlpt_level": number | null
}

**출력 요구사항:**
1. question: 한국어 뜻을 그대로 사용 (meanings 배열의 첫 번째 meaning 값)
2. options: 일본어 단어 4개 (정답 1개 + 오답 3개)
   - 정답: word 필드 값
   - 오답: 같은 JLPT 레벨의 다른 단어들에서 선택하거나, 유사한 의미의 단어들로 구성
   - 오답은 정답과 구분되지만 그럴듯한 선택지여야 함
   - **중요: 정답의 위치는 1번, 2번, 3번, 4번 중 랜덤하게 배치해야 함 (항상 첫 번째 위치에 두지 말 것)**
3. correct_answer: 정답의 word 값
4. explanation: 한자가 있다면 한자 구성 설명, 없다면 단어의 어원이나 의미 설명
   - 형식: "({reading})\n한자(읽기 한자) + 한자(읽기 한자) = 의미" 또는 "({reading})\n단어의 의미 설명"
   - 반드시 읽기(reading 필드 값)를 포함해야 하고, 읽기 뒤에 줄바꿈(\n)을 넣어야 함
   - 줄바꿈은 실제 \n 문자로 표시해야 함
5. jlpt_level: 입력 데이터의 jlpt_level 그대로 사용
6. quiz_type: "kr_to_jp"

**예시:**
입력:
{
  "id": 2393,
  "word": "抱っこ",
  "reading": "だっこ",
  "meanings": [{"meaning": "안음; 안김.", "part_of_speech": "명사"}],
  "jlpt_level": 3
}

출력:
{
  "id": 2393,
  "question": "안음; 안김.",
  "options": ["抱っこ", "抱擁", "キス", "握手"],
  "correct_answer": "抱っこ",
  "explanation": "(だっこ)\n抱(안을 포) = 안다, 안기다",
  "jlpt_level": 3,
  "quiz_type": "kr_to_jp"
}

**중요 규칙:**
- options는 반드시 정확히 4개여야 함
- correct_answer는 options 배열의 요소 중 하나와 정확히 일치해야 함
- **정답의 위치는 1번, 2번, 3번, 4번 중 랜덤하게 배치해야 함 (항상 첫 번째 위치에 두지 말 것)**
- explanation은 한자가 있으면 한자 구성 설명, 없으면 의미 설명
- 오답 선택지는 같은 JLPT 레벨의 단어들에서 선택하거나, 유사한 의미의 단어로 구성
- 오답도 실제로 존재하는 일본어 단어여야 함
```

### JSON Schema

```json
{
  "type": "object",
  "properties": {
    "id": {"type": "number"},
    "question": {"type": "string"},
    "options": {
      "type": "array",
      "items": {"type": "string"},
      "minItems": 4,
      "maxItems": 4
    },
    "correct_answer": {"type": "string"},
    "explanation": {"type": "string"},
    "jlpt_level": {"type": ["number", "null"]},
    "quiz_type": {"type": "string", "enum": ["kr_to_jp"]}
  },
  "required": ["id", "question", "options", "correct_answer", "explanation", "quiz_type"]
}
```

---

## 3. kanji_reading (한자 읽기)

### 프롬프트

```
당신은 일본어 학습 퀴즈 문제를 생성하는 전문가입니다.

주어진 단어 데이터를 기반으로 "한자의 읽기를 고르는" 문제를 생성하세요.

**입력 데이터 형식:**
{
  "id": number,
  "word": string,           // 일본어 단어 (한자 포함 가능)
  "reading": string,        // 읽기 (히라가나/가타카나)
  "meanings": [
    {
      "meaning": string,    // 한국어 뜻
      "part_of_speech": string  // 품사
    }
  ],
  "jlpt_level": number | null
}

**출력 요구사항:**
1. question: 한자가 포함된 단어를 그대로 사용 (word 필드 값)
   - 한자가 없는 경우(히라가나/가타카나만) 이 문제 타입은 생성하지 않음
2. options: 읽기 4개 (정답 1개 + 오답 3개)
   - 정답: reading 필드 값
   - 오답: 같은 한자를 사용하는 다른 읽기나, 유사한 발음의 읽기로 구성
   - 오답은 실제로 존재할 수 있는 읽기여야 함
   - **중요: 정답의 위치는 1번, 2번, 3번, 4번 중 랜덤하게 배치해야 함 (항상 첫 번째 위치에 두지 말 것)**
3. correct_answer: 정답의 reading 값
4. explanation: 한자 구성 설명
   - 형식: "({reading})\n한자(읽기 한자) + 한자(읽기 한자) = 의미"
   - 반드시 읽기(reading 필드 값)를 포함해야 하고, 읽기 뒤에 줄바꿈(\n)을 넣어야 함
   - 각 한자의 음독/훈독을 설명
5. jlpt_level: 입력 데이터의 jlpt_level 그대로 사용
6. quiz_type: "kanji_reading"

**예시:**
입력:
{
  "id": 2393,
  "word": "抱っこ",
  "reading": "だっこ",
  "meanings": [{"meaning": "안음; 안김.", "part_of_speech": "명사"}],
  "jlpt_level": 3
}

출력:
{
  "id": 2393,
  "question": "抱っこ",
  "options": ["だっこ", "ほうこ", "だくこ", "ほうっこ"],
  "correct_answer": "だっこ",
  "explanation": "(だっこ)\n抱(안을 포, だく/ほう) = 안다, 안기다",
  "jlpt_level": 3,
  "quiz_type": "kanji_reading"
}

**중요 규칙:**
- word에 한자가 포함되어 있지 않으면 이 문제 타입은 생성하지 않음
- options는 반드시 정확히 4개여야 함
- correct_answer는 options 배열의 요소 중 하나와 정확히 일치해야 함
- **정답의 위치는 1번, 2번, 3번, 4번 중 랜덤하게 배치해야 함 (항상 첫 번째 위치에 두지 말 것)**
- explanation은 한자의 음독과 훈독을 모두 설명
- 오답 선택지는 같은 한자의 다른 읽기나 유사한 발음으로 구성
- 오답도 실제로 존재할 수 있는 읽기여야 함
```

### JSON Schema

```json
{
  "type": "object",
  "properties": {
    "id": {"type": "number"},
    "question": {"type": "string"},
    "options": {
      "type": "array",
      "items": {"type": "string"},
      "minItems": 4,
      "maxItems": 4
    },
    "correct_answer": {"type": "string"},
    "explanation": {"type": "string"},
    "jlpt_level": {"type": ["number", "null"]},
    "quiz_type": {"type": "string", "enum": ["kanji_reading"]}
  },
  "required": ["id", "question", "options", "correct_answer", "explanation", "quiz_type"]
}
```

---

## Gemini API 사용 예제

### Python 예제

```python
import google.generativeai as genai
import json

# API 키 설정
genai.configure(api_key="YOUR_API_KEY")

# 모델 설정 (structured output 사용)
model = genai.GenerativeModel(
    model_name="gemini-1.5-pro",
    generation_config={
        "response_mime_type": "application/json",
        "response_schema": {
            "type": "object",
            "properties": {
                "id": {"type": "number"},
                "question": {"type": "string"},
                "options": {
                    "type": "array",
                    "items": {"type": "string"},
                    "minItems": 4,
                    "maxItems": 4
                },
                "correct_answer": {"type": "string"},
                "explanation": {"type": "string"},
                "jlpt_level": {"type": ["number", "null"]},
                "quiz_type": {"type": "string", "enum": ["jp_to_kr", "kr_to_jp", "kanji_reading"]}
            },
            "required": ["id", "question", "options", "correct_answer", "explanation", "quiz_type"]
        }
    }
)

# 입력 데이터
word_data = {
    "id": 2393,
    "word": "抱っこ",
    "reading": "だっこ",
    "meanings": [{"meaning": "안음; 안김.", "part_of_speech": "명사"}],
    "jlpt_level": 3
}

# 프롬프트 구성 (jp_to_kr 예시)
prompt = f"""
당신은 일본어 학습 퀴즈 문제를 생성하는 전문가입니다.

주어진 단어 데이터를 기반으로 "일본어 단어의 한국어 뜻을 고르는" 문제를 생성하세요.

입력 데이터:
{json.dumps(word_data, ensure_ascii=False, indent=2)}

출력 요구사항:
1. question: 일본어 단어를 그대로 사용 (word 필드 값)
2. options: 한국어 뜻 4개 (정답 1개 + 오답 3개)
3. correct_answer: 정답의 meaning 값
4. explanation: 한자 구성 설명 또는 의미 설명
5. jlpt_level: 입력 데이터의 jlpt_level 그대로 사용
6. quiz_type: "jp_to_kr"
"""

# API 호출
response = model.generate_content(prompt)
quiz_question = json.loads(response.text)

print(json.dumps(quiz_question, ensure_ascii=False, indent=2))
```

### JavaScript/TypeScript 예제

```typescript
import { GoogleGenerativeAI } from "@google/generative-ai";

const genAI = new GoogleGenerativeAI("YOUR_API_KEY");

const model = genAI.getGenerativeModel({
  model: "gemini-1.5-pro",
  generationConfig: {
    responseMimeType: "application/json",
    responseSchema: {
      type: "object",
      properties: {
        id: { type: "number" },
        question: { type: "string" },
        options: {
          type: "array",
          items: { type: "string" },
          minItems: 4,
          maxItems: 4,
        },
        correct_answer: { type: "string" },
        explanation: { type: "string" },
        jlpt_level: { type: ["number", "null"] },
        quiz_type: {
          type: "string",
          enum: ["jp_to_kr", "kr_to_jp", "kanji_reading"],
        },
      },
      required: [
        "id",
        "question",
        "options",
        "correct_answer",
        "explanation",
        "quiz_type",
      ],
    },
  },
});

const wordData = {
  id: 2393,
  word: "抱っこ",
  reading: "だっこ",
  meanings: [{ meaning: "안음; 안김.", part_of_speech: "명사" }],
  jlpt_level: 3,
};

const prompt = `
당신은 일본어 학습 퀴즈 문제를 생성하는 전문가입니다.

주어진 단어 데이터를 기반으로 "일본어 단어의 한국어 뜻을 고르는" 문제를 생성하세요.

입력 데이터:
${JSON.stringify(wordData, null, 2)}

출력 요구사항:
1. question: 일본어 단어를 그대로 사용 (word 필드 값)
2. options: 한국어 뜻 4개 (정답 1개 + 오답 3개)
3. correct_answer: 정답의 meaning 값
4. explanation: 한자 구성 설명 또는 의미 설명
5. jlpt_level: 입력 데이터의 jlpt_level 그대로 사용
6. quiz_type: "jp_to_kr"
`;

const result = await model.generateContent(prompt);
const quizQuestion = JSON.parse(result.response.text());

console.log(JSON.stringify(quizQuestion, null, 2));
```

---

## 주의사항

1. **오답 생성**: 오답 선택지는 같은 JLPT 레벨의 단어 데이터베이스에서 가져오거나, Gemini에게 유사한 의미의 단어를 생성하도록 요청해야 합니다.

2. **한자 검증**: `kanji_reading` 타입의 경우, word에 한자가 포함되어 있는지 확인해야 합니다.

3. **정답 매칭**: `correct_answer`는 반드시 `options` 배열의 요소 중 하나와 정확히 일치해야 합니다.

4. **explanation 형식**: 한자가 있는 경우 "한자(읽기 한자) + 한자(읽기 한자) = 의미" 형식을 사용하고, 한자가 없는 경우 의미 설명을 제공합니다.

