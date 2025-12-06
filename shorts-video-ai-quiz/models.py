"""
Pydantic models for Quiz Shorts Video Generator API
"""

from pydantic import BaseModel, Field
from enum import Enum


class QuizType(str, Enum):
    """퀴즈 유형"""
    JP_TO_KR = "jp_to_kr"  # 일본어 → 한국어
    KR_TO_JP = "kr_to_jp"  # 한국어 → 일본어
    KANJI_READING = "kanji_reading"  # 한자 읽기
    FILL_BLANK = "fill_blank"  # 빈칸 채우기


class QuizQuestion(BaseModel):
    """퀴즈 문제 요청 모델"""
    id: int = Field(..., description="문제 고유 ID")
    question: str = Field(..., description="문제 내용")
    options: list[str] = Field(..., min_length=4, max_length=4, description="4개의 선택지")
    correct_answer: str = Field(..., description="정답 (options 중 하나)")
    explanation: str = Field(..., description="정답 해설")
    jlpt_level: int | None = Field(None, ge=1, le=5, description="JLPT 레벨 (1-5)")
    quiz_type: QuizType = Field(default=QuizType.JP_TO_KR, description="퀴즈 유형")

    def get_quiz_type_display(self) -> str:
        """퀴즈 유형 표시 이름"""
        display_names = {
            QuizType.JP_TO_KR: "일→한",
            QuizType.KR_TO_JP: "한→일",
            QuizType.KANJI_READING: "한자읽기",
            QuizType.FILL_BLANK: "빈칸채우기",
        }
        return display_names.get(self.quiz_type, "퀴즈")

    def get_question_prompt(self) -> str:
        """퀴즈 유형에 따른 문제 프롬프트"""
        prompts = {
            QuizType.JP_TO_KR: "다음 단어의 뜻은?",
            QuizType.KR_TO_JP: "다음 뜻의 일본어는?",
            QuizType.KANJI_READING: "다음 한자의 읽기는?",
            QuizType.FILL_BLANK: "빈칸에 들어갈 단어는?",
        }
        return prompts.get(self.quiz_type, "정답을 고르세요")


class GenerateRequest(BaseModel):
    """영상 생성 요청"""
    question: QuizQuestion


class GenerateResponse(BaseModel):
    """영상 생성 응답 (메타데이터)"""
    success: bool
    question_id: int
    message: str
    video_url: str | None = None  # GCS 저장 시 URL
    file_size_bytes: int | None = None


class HealthResponse(BaseModel):
    """헬스체크 응답"""
    status: str = "ok"
    version: str = "1.0.0"


class ErrorResponse(BaseModel):
    """에러 응답"""
    error: str
    detail: str | None = None
