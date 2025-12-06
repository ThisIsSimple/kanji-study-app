"""
Quiz Shorts Video Generator API
FastAPI 서버 - 퀴즈 데이터를 받아 쇼츠 영상 생성
"""

import os
import logging
from contextlib import asynccontextmanager

from fastapi import FastAPI, HTTPException
from fastapi.responses import Response, JSONResponse
from dotenv import load_dotenv

from models import (
    QuizQuestion,
    GenerateRequest,
    GenerateResponse,
    HealthResponse,
    ErrorResponse,
)
from video_generator import generate_quiz_video
from storage import get_storage_manager

# 환경 변수 로드
load_dotenv()

# 로깅 설정
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s - %(name)s - %(levelname)s - %(message)s",
)
logger = logging.getLogger(__name__)


@asynccontextmanager
async def lifespan(app: FastAPI):
    """앱 시작/종료 시 실행"""
    # 시작 시
    logger.info("🚀 Quiz Shorts Video Generator 시작")
    storage_manager = get_storage_manager()
    logger.info(f"📁 저장소 설정: {storage_manager.get_storage_info()}")
    yield
    # 종료 시
    logger.info("👋 Quiz Shorts Video Generator 종료")


# FastAPI 앱 생성
app = FastAPI(
    title="Quiz Shorts Video Generator",
    description="일본어 퀴즈 쇼츠 영상 생성 API",
    version="1.0.0",
    lifespan=lifespan,
)


@app.get("/", response_model=HealthResponse)
async def root():
    """루트 엔드포인트"""
    return HealthResponse(status="ok", version="1.0.0")


@app.get("/health", response_model=HealthResponse)
async def health_check():
    """헬스체크 엔드포인트"""
    return HealthResponse(status="ok", version="1.0.0")


@app.get("/storage-info")
async def storage_info():
    """저장소 정보 확인"""
    storage_manager = get_storage_manager()
    return storage_manager.get_storage_info()


@app.post(
    "/generate",
    responses={
        200: {
            "content": {"video/mp4": {}},
            "description": "생성된 MP4 영상 파일",
        },
        400: {"model": ErrorResponse},
        500: {"model": ErrorResponse},
    },
)
async def generate_video(request: GenerateRequest):
    """
    퀴즈 영상 생성
    
    퀴즈 데이터를 받아 20초 쇼츠 영상을 생성하여 MP4로 반환합니다.
    
    - 0-3초: 인트로 (퀴즈 유형, 난이도)
    - 3-13초: 문제 + 선택지 + 10초 카운트다운
    - 13-20초: 정답 + 해설
    """
    question = request.question
    logger.info(f"🎬 영상 생성 요청: question_id={question.id}, type={question.quiz_type}")
    
    try:
        # 영상 생성
        video_bytes, temp_path = generate_quiz_video(question)
        logger.info(f"✅ 영상 생성 완료: {len(video_bytes)} bytes")
        
        # 디버그 모드일 때 저장
        storage_manager = get_storage_manager()
        saved_path = storage_manager.save_video(video_bytes, question)
        if saved_path:
            logger.info(f"💾 디버그 저장: {saved_path}")
        
        # 임시 파일 삭제
        if temp_path and os.path.exists(temp_path):
            try:
                os.remove(temp_path)
                # 빈 디렉토리도 삭제
                temp_dir = os.path.dirname(temp_path)
                if os.path.isdir(temp_dir) and not os.listdir(temp_dir):
                    os.rmdir(temp_dir)
            except Exception as e:
                logger.warning(f"임시 파일 삭제 실패: {e}")
        
        # MP4 응답 반환
        return Response(
            content=video_bytes,
            media_type="video/mp4",
            headers={
                "Content-Disposition": f'attachment; filename="quiz_{question.id}.mp4"',
                "X-Question-ID": str(question.id),
                "X-Video-Size": str(len(video_bytes)),
            },
        )
        
    except Exception as e:
        logger.error(f"❌ 영상 생성 실패: {e}", exc_info=True)
        raise HTTPException(
            status_code=500,
            detail=f"영상 생성 중 오류가 발생했습니다: {str(e)}",
        )


@app.post("/generate-json", response_model=GenerateResponse)
async def generate_video_json(request: GenerateRequest):
    """
    퀴즈 영상 생성 (JSON 응답)
    
    영상을 생성하고 메타데이터를 JSON으로 반환합니다.
    DEBUG_SAVE_VIDEO=true일 때만 영상이 저장됩니다.
    """
    question = request.question
    logger.info(f"🎬 영상 생성 요청 (JSON): question_id={question.id}")
    
    try:
        # 영상 생성
        video_bytes, temp_path = generate_quiz_video(question)
        logger.info(f"✅ 영상 생성 완료: {len(video_bytes)} bytes")
        
        # 저장
        storage_manager = get_storage_manager()
        saved_path = storage_manager.save_video(video_bytes, question)
        
        # 임시 파일 삭제
        if temp_path and os.path.exists(temp_path):
            try:
                os.remove(temp_path)
                temp_dir = os.path.dirname(temp_path)
                if os.path.isdir(temp_dir) and not os.listdir(temp_dir):
                    os.rmdir(temp_dir)
            except Exception as e:
                logger.warning(f"임시 파일 삭제 실패: {e}")
        
        return GenerateResponse(
            success=True,
            question_id=question.id,
            message="영상 생성 완료",
            video_url=saved_path,
            file_size_bytes=len(video_bytes),
        )
        
    except Exception as e:
        logger.error(f"❌ 영상 생성 실패: {e}", exc_info=True)
        raise HTTPException(
            status_code=500,
            detail=f"영상 생성 중 오류가 발생했습니다: {str(e)}",
        )


# 개발 서버 실행
if __name__ == "__main__":
    import uvicorn
    
    port = int(os.getenv("PORT", 8080))
    host = os.getenv("HOST", "0.0.0.0")
    
    logger.info(f"🌐 서버 시작: http://{host}:{port}")
    uvicorn.run(
        "main:app",
        host=host,
        port=port,
        reload=True,  # 개발 모드에서 자동 리로드
    )
