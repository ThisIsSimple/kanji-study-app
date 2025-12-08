"""
Video Generator - MoviePy를 사용하여 23초 쇼츠 영상 생성
"""

import os
import tempfile
from pathlib import Path

from moviepy.editor import (
    ImageClip,
    concatenate_videoclips,
    concatenate_audioclips,
    CompositeVideoClip,
    AudioFileClip,
    CompositeAudioClip,
)
import numpy as np
from PIL import Image

from models import QuizQuestion
from frame_renderer import (
    render_intro_frame,
    render_question_frame,
    render_answer_frame,
    render_account_frame,
    WIDTH,
    HEIGHT,
)

# Assets 경로
ASSETS_DIR = Path(__file__).parent / "assets"
SOUNDS_DIR = ASSETS_DIR / "sounds"

# 배경음악 파일 (우선순위 순)
BACKGROUND_MUSIC_FILES = ["ukulele.mp3"]


# 영상 설정
FPS = 30
INTRO_DURATION = 3  # 0-3초: 인트로
QUESTION_DURATION = 10  # 3-13초: 문제 (10초 카운트다운)
ANSWER_DURATION = 5  # 13-18초: 정답
ACCOUNT_DURATION = 5  # 18-23초: 계정 정보
TOTAL_DURATION = INTRO_DURATION + QUESTION_DURATION + ANSWER_DURATION + ACCOUNT_DURATION  # 23초


def pil_to_numpy(pil_image: Image.Image) -> np.ndarray:
    """PIL 이미지를 numpy 배열로 변환"""
    return np.array(pil_image)


def create_intro_clip(question: QuizQuestion) -> ImageClip:
    """인트로 클립 생성 (3초)"""
    frame = render_intro_frame(question)
    frame_array = pil_to_numpy(frame)
    clip = ImageClip(frame_array).set_duration(INTRO_DURATION)
    return clip


def create_question_clip(question: QuizQuestion) -> CompositeVideoClip:
    """
    문제 클립 생성 (10초)
    매 초마다 카운트다운이 바뀌는 프레임 생성 + 효과음 추가
    """
    clips = []

    # 효과음 로드
    tick_sound_path = SOUNDS_DIR / "tick.wav"
    tick_audio = None
    if tick_sound_path.exists():
        try:
            tick_audio = AudioFileClip(str(tick_sound_path))
            # 효과음 길이 조절 (0.15초 정도로 짧게)
            if tick_audio.duration > 0.2:
                tick_audio = tick_audio.subclip(0, 0.2)
        except Exception as e:
            print(f"⚠️  효과음 로드 실패: {e}")
            tick_audio = None

    for countdown in range(10, 0, -1):
        frame = render_question_frame(question, countdown)
        frame_array = pil_to_numpy(frame)
        clip = ImageClip(frame_array).set_duration(1)

        # 효과음 추가 (각 초마다)
        if tick_audio:
            try:
                # 각 클립마다 오디오를 새로 로드 (MoviePy 버그 회피)
                clip_audio = AudioFileClip(str(tick_sound_path))
                if clip_audio.duration > 0.2:
                    clip_audio = clip_audio.subclip(0, 0.2)
                clip = clip.set_audio(clip_audio)
            except Exception as e:
                print(f"⚠️  효과음 추가 실패: {e}")

        clips.append(clip)

    # 클립들을 순차적으로 연결
    final_clip = concatenate_videoclips(clips, method="compose")

    # 효과음 정리
    if tick_audio:
        tick_audio.close()

    return final_clip


def create_answer_clip(question: QuizQuestion) -> ImageClip:
    """정답 클립 생성 (5초)"""
    frame = render_answer_frame(question)
    frame_array = pil_to_numpy(frame)
    clip = ImageClip(frame_array).set_duration(ANSWER_DURATION)
    return clip


def create_account_clip() -> ImageClip:
    """계정 정보 클립 생성 (5초)"""
    frame = render_account_frame()
    frame_array = pil_to_numpy(frame)
    clip = ImageClip(frame_array).set_duration(ACCOUNT_DURATION)
    return clip


def generate_quiz_video(
    question: QuizQuestion,
    output_path: str | None = None,
) -> tuple[bytes, str]:
    """
    퀴즈 영상 생성

    Args:
        question: 퀴즈 문제 데이터
        output_path: 저장할 경로 (None이면 임시 파일 사용)

    Returns:
        tuple[bytes, str]: (영상 바이트 데이터, 파일 경로)
    """
    # 클립 생성
    intro_clip = create_intro_clip(question)
    question_clip = create_question_clip(question)
    answer_clip = create_answer_clip(question)
    account_clip = create_account_clip()

    # 클립 연결
    final_clip = concatenate_videoclips(
        [intro_clip, question_clip, answer_clip, account_clip],
        method="compose",
    )

    # 배경음악 추가
    bg_music = None
    for music_file in BACKGROUND_MUSIC_FILES:
        music_path = SOUNDS_DIR / music_file
        if music_path.exists():
            try:
                bg_music = AudioFileClip(str(music_path))
                # 영상 길이에 맞춰 조절
                if bg_music.duration > TOTAL_DURATION:
                    bg_music = bg_music.subclip(0, TOTAL_DURATION)
                elif bg_music.duration < TOTAL_DURATION:
                    # 루프 (간단하게 처음부터 반복)
                    loops_needed = int(TOTAL_DURATION / bg_music.duration) + 1
                    bg_music = concatenate_audioclips(
                        [bg_music] * loops_needed
                    ).subclip(0, TOTAL_DURATION)

                # 볼륨 조절 (배경음악은 낮게)
                bg_music = bg_music.volumex(0.3)  # 30% 볼륨
                break
            except Exception as e:
                print(f"⚠️  배경음악 로드 실패 {music_file}: {e}")
                if bg_music:
                    bg_music.close()
                bg_music = None
                continue

    # 배경음악과 효과음 결합
    if bg_music and final_clip.audio:
        # CompositeAudioClip으로 배경음악과 효과음 결합
        final_audio = CompositeAudioClip([bg_music, final_clip.audio])
        final_clip = final_clip.set_audio(final_audio)
    elif bg_music:
        # 배경음악만 있는 경우
        final_clip = final_clip.set_audio(bg_music)

    # 출력 경로 결정
    if output_path is None:
        # 임시 파일 사용
        temp_dir = tempfile.mkdtemp()
        output_path = os.path.join(temp_dir, f"quiz_{question.id}.mp4")
    else:
        # 디렉토리 생성
        Path(output_path).parent.mkdir(parents=True, exist_ok=True)

    # 영상 렌더링
    # 오디오가 있는 경우 audio=True, 없으면 audio=False
    has_audio = final_clip.audio is not None
    final_clip.write_videofile(
        output_path,
        fps=FPS,
        codec="libx264",
        audio=has_audio,  # 오디오가 있으면 포함
        audio_codec="aac" if has_audio else None,
        preset="medium",  # 인코딩 속도 vs 품질
        threads=4,
        logger=None,  # 로그 비활성화
    )

    # 클립 정리
    final_clip.close()
    intro_clip.close()
    question_clip.close()
    answer_clip.close()
    account_clip.close()

    # 배경음악 정리
    if bg_music:
        bg_music.close()

    # 파일 읽기
    with open(output_path, "rb") as f:
        video_bytes = f.read()

    return video_bytes, output_path


def generate_quiz_video_to_file(
    question: QuizQuestion,
    output_dir: str = "./output",
) -> str:
    """
    퀴즈 영상 생성 후 파일로 저장

    Args:
        question: 퀴즈 문제 데이터
        output_dir: 출력 디렉토리

    Returns:
        str: 저장된 파일 경로
    """
    output_path = os.path.join(output_dir, f"quiz_{question.id}.mp4")
    _, saved_path = generate_quiz_video(question, output_path)
    return saved_path


# 테스트용
if __name__ == "__main__":
    from models import QuizType

    # 테스트 퀴즈 생성
    test_question = QuizQuestion(
        id=1,
        question="勉強",
        options=["공부", "운동", "독서", "여행"],
        correct_answer="공부",
        explanation="勉(힘쓸 면) + 強(강할 강) = 힘써서 배우다, 공부하다",
        jlpt_level=3,
        quiz_type=QuizType.JP_TO_KR,
    )

    print("🎬 영상 생성 시작...")
    video_bytes, output_path = generate_quiz_video(
        test_question, "./output/test_quiz.mp4"
    )
    print(f"✅ 영상 생성 완료: {output_path}")
    print(f"📦 파일 크기: {len(video_bytes) / 1024 / 1024:.2f} MB")
