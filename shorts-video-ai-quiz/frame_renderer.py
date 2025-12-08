"""
Frame Renderer - Pillow를 사용하여 각 프레임 이미지 생성
쇼츠 영상용 1080x1920 (9:16) 프레임 렌더링
"""

import os
import logging
from PIL import Image, ImageDraw, ImageFont
from pathlib import Path

from models import QuizQuestion, QuizType

logger = logging.getLogger(__name__)


# 상수 정의
WIDTH = 1080
HEIGHT = 1920
BACKGROUND_COLOR = "#1a1a2e"  # 다크 네이비
PRIMARY_COLOR = "#e94560"  # 레드 핑크
SECONDARY_COLOR = "#16213e"  # 다크 블루
TEXT_COLOR = "#ffffff"
ACCENT_COLOR = "#0f3460"  # 미드 블루
CORRECT_COLOR = "#4ade80"  # 초록
WRONG_COLOR = "#f87171"  # 빨강

# Safe Zone 규격 (유동적 적용 - 상하단 우선, 좌우는 유동적)
SAFE_ZONE_TOP = 250
SAFE_ZONE_BOTTOM = 420
SAFE_ZONE_LEFT = 40  # 좌우 여백 완화
SAFE_ZONE_RIGHT = 120  # 우측 중앙-하단만 피하면 됨
SAFE_ZONE_WIDTH = WIDTH - SAFE_ZONE_LEFT - SAFE_ZONE_RIGHT  # 920px
SAFE_ZONE_HEIGHT = HEIGHT - SAFE_ZONE_TOP - SAFE_ZONE_BOTTOM  # 1250px

# 폰트 경로
ASSETS_DIR = Path(__file__).parent / "assets"
FONTS_DIR = ASSETS_DIR / "fonts"
EMOJIS_DIR = ASSETS_DIR / "emojis"

# 이모지 캐시
_emoji_cache = {}


def get_font(size: int, bold: bool = False) -> ImageFont.FreeTypeFont:
    """
    폰트 로드 (한글/일본어/한자/이모지 모두 지원)
    
    우선순위:
    1. SpoqaHanSansNeo (영어/한글/일본어/이모지 모두 지원, 최우선)
    2. NotoSansKR-VariableFont_wght.ttf (한글/일본어 지원)
    3. assets/fonts 폴더의 기타 폰트
    4. 시스템 폰트 (macOS)
    5. 기본 폰트 (fallback)
    """
    # 1. SpoqaHanSansNeo 최우선 (영어/한글/일본어/이모지 모두 지원)
    spoqa_bold_path = FONTS_DIR / "SpoqaHanSansNeo-Bold.ttf"
    spoqa_regular_path = FONTS_DIR / "SpoqaHanSansNeo-Regular.ttf"
    
    if bold and spoqa_bold_path.exists():
        try:
            font = ImageFont.truetype(str(spoqa_bold_path), size)
            logger.info(f"폰트 로드 성공: {spoqa_bold_path} (SpoqaHanSansNeo Bold)")
            return font
        except Exception as e:
            logger.warning(f"SpoqaHanSansNeo Bold 로드 실패: {e}")
    elif not bold and spoqa_regular_path.exists():
        try:
            font = ImageFont.truetype(str(spoqa_regular_path), size)
            logger.info(f"폰트 로드 성공: {spoqa_regular_path} (SpoqaHanSansNeo Regular)")
            return font
        except Exception as e:
            logger.warning(f"SpoqaHanSansNeo Regular 로드 실패: {e}")
    
    # 2. NotoSansKR-VariableFont_wght.ttf (fallback - 한글/일본어 지원)
    variable_font_path = FONTS_DIR / "NotoSansKR-VariableFont_wght.ttf"
    if variable_font_path.exists():
        try:
            # Variable Font는 weight를 조절할 수 있지만, PIL에서는 기본 weight 사용
            # bold 옵션은 무시하고 기본 weight 사용 (필요시 나중에 개선 가능)
            font = ImageFont.truetype(str(variable_font_path), size)
            logger.info(f"폰트 로드 성공: {variable_font_path} (Variable Font, 한글/일본어 지원)")
            return font
        except Exception as e:
            logger.warning(f"Variable Font 로드 실패 {variable_font_path}: {e}")
    
    # 2. 프로젝트 assets/fonts 폴더의 기타 폰트
    font_candidates = [
        # Hiragino (한글/일본어 모두 지원)
        "HiraginoKakuGothic-W6.ttc",
        "HiraginoKakuGothic-W3.ttc",
        # Noto Sans 폰트들
        "NotoSansCJK-Regular.ttc" if not bold else "NotoSansCJK-Bold.ttc",
        "NotoSansCJKjp-Regular.otf" if not bold else "NotoSansCJKjp-Bold.otf",
        "NotoSansKR-Regular.otf" if not bold else "NotoSansKR-Bold.otf",
        "NotoSansKR-Regular.ttf" if not bold else "NotoSansKR-Bold.ttf",
        "NotoSansJP-Regular.ttf" if not bold else "NotoSansJP-Bold.ttf",
        "NotoSansJP-Regular.otf" if not bold else "NotoSansJP-Bold.otf",
    ]
    
    for font_name in font_candidates:
        font_path = FONTS_DIR / font_name
        if font_path.exists():
            try:
                # TTC 파일의 경우 인덱스 0 사용 (Hiragino는 인덱스 0이 한글/일본어 모두 지원)
                if font_path.suffix.lower() == ".ttc":
                    font = ImageFont.truetype(str(font_path), size, index=0)
                    logger.info(f"폰트 로드 성공: {font_path} (TTC 인덱스 0)")
                else:
                    font = ImageFont.truetype(str(font_path), size)
                    logger.info(f"폰트 로드 성공: {font_path}")
                return font
            except Exception as e:
                logger.warning(f"폰트 로드 실패 {font_path}: {e}")
                continue
    
    # 2. 시스템 폰트 경로에서 찾기 (macOS - 한글/일본어 지원)
    # Hiragino를 우선 (한글과 일본어 모두 지원)
    system_font_paths = [
        "/System/Library/Fonts/ヒラギノ角ゴシック W6.ttc",
        "/System/Library/Fonts/ヒラギノ角ゴシック W3.ttc",
        "/System/Library/Fonts/Hiragino Sans GB.ttc",
        "/Library/Fonts/ヒラギノ角ゴシック W6.ttc",
        "/Library/Fonts/ヒラギノ角ゴシック W3.ttc",
        # AppleGothic (한글 우선, 일본어는 제한적)
        "/System/Library/Fonts/AppleGothic.ttf",
        "/Library/Fonts/AppleGothic.ttf",
    ]
    
    for font_path in system_font_paths:
        if os.path.exists(font_path):
            try:
                # TTC 파일은 인덱스 0 사용, TTF는 인덱스 없이
                if font_path.endswith('.ttc'):
                    font = ImageFont.truetype(font_path, size, index=0)
                else:
                    font = ImageFont.truetype(font_path, size)
                logger.info(f"시스템 폰트 로드 성공: {font_path}")
                return font
            except Exception as e:
                logger.warning(f"시스템 폰트 로드 실패 {font_path}: {e}")
                continue
    
    # 3. 기본 폰트 (fallback - 한글/일본어 미지원)
    logger.warning("한글/일본어 폰트를 찾을 수 없습니다. 기본 폰트를 사용합니다. 한글/일본어가 깨질 수 있습니다.")
    try:
        return ImageFont.truetype("/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf", size)
    except:
        return ImageFont.load_default()


def create_gradient_background(width: int, height: int) -> Image.Image:
    """그라데이션 배경 생성"""
    img = Image.new("RGB", (width, height))
    draw = ImageDraw.Draw(img)
    
    # 세로 그라데이션 (위에서 아래로)
    start_color = (26, 26, 46)  # #1a1a2e
    end_color = (15, 52, 96)    # #0f3460
    
    for y in range(height):
        ratio = y / height
        r = int(start_color[0] + (end_color[0] - start_color[0]) * ratio)
        g = int(start_color[1] + (end_color[1] - start_color[1]) * ratio)
        b = int(start_color[2] + (end_color[2] - start_color[2]) * ratio)
        draw.line([(0, y), (width, y)], fill=(r, g, b))
    
    return img


def draw_rounded_rectangle(
    draw: ImageDraw.Draw,
    xy: tuple[int, int, int, int],
    radius: int,
    fill: str | None = None,
    outline: str | None = None,
    width: int = 1,
):
    """둥근 모서리 사각형 그리기"""
    x1, y1, x2, y2 = xy
    
    if fill:
        # 채우기
        draw.rectangle([x1 + radius, y1, x2 - radius, y2], fill=fill)
        draw.rectangle([x1, y1 + radius, x2, y2 - radius], fill=fill)
        draw.pieslice([x1, y1, x1 + radius * 2, y1 + radius * 2], 180, 270, fill=fill)
        draw.pieslice([x2 - radius * 2, y1, x2, y1 + radius * 2], 270, 360, fill=fill)
        draw.pieslice([x1, y2 - radius * 2, x1 + radius * 2, y2], 90, 180, fill=fill)
        draw.pieslice([x2 - radius * 2, y2 - radius * 2, x2, y2], 0, 90, fill=fill)
    
    if outline:
        # 테두리
        draw.arc([x1, y1, x1 + radius * 2, y1 + radius * 2], 180, 270, fill=outline, width=width)
        draw.arc([x2 - radius * 2, y1, x2, y1 + radius * 2], 270, 360, fill=outline, width=width)
        draw.arc([x1, y2 - radius * 2, x1 + radius * 2, y2], 90, 180, fill=outline, width=width)
        draw.arc([x2 - radius * 2, y2 - radius * 2, x2, y2], 0, 90, fill=outline, width=width)
        draw.line([x1 + radius, y1, x2 - radius, y1], fill=outline, width=width)
        draw.line([x1 + radius, y2, x2 - radius, y2], fill=outline, width=width)
        draw.line([x1, y1 + radius, x1, y2 - radius], fill=outline, width=width)
        draw.line([x2, y1 + radius, x2, y2 - radius], fill=outline, width=width)


def get_text_size(draw: ImageDraw.Draw, text: str, font: ImageFont.FreeTypeFont) -> tuple[int, int]:
    """텍스트 크기 반환"""
    bbox = draw.textbbox((0, 0), text, font=font)
    return bbox[2] - bbox[0], bbox[3] - bbox[1]


def load_emoji_image(emoji_char: str, size: int) -> Image.Image | None:
    """이모지 이미지 로드 및 크기 조절"""
    # 캐시 확인
    cache_key = f"{emoji_char}_{size}"
    if cache_key in _emoji_cache:
        return _emoji_cache[cache_key]
    
    # 파일명 생성 (유니코드 코드포인트, Variation Selector 제외)
    safe_name = "".join([f"U{ord(c):04X}" for c in emoji_char if ord(c) not in [0xFE0F, 0x200D]])
    emoji_path = EMOJIS_DIR / f"{safe_name}.png"
    
    if not emoji_path.exists():
        logger.warning(f"이모지 이미지 없음: {emoji_char} ({emoji_path})")
        return None
    
    try:
        # PNG 파일 로드 (Twemoji는 PNG로 다운로드됨)
        if emoji_path.exists():
            img = Image.open(emoji_path)
            # RGBA 모드로 변환 (투명도 지원)
            if img.mode != "RGBA":
                img = img.convert("RGBA")
        else:
            logger.warning(f"이모지 이미지 파일 없음: {emoji_path}")
            return None
        
        # 크기 조절 (비율 유지)
        img.thumbnail((size, size), Image.Resampling.LANCZOS)
        
        # 캐시에 저장
        _emoji_cache[cache_key] = img
        return img
    except Exception as e:
        logger.error(f"이모지 이미지 로드 실패 {emoji_char}: {e}")
        return None


def is_emoji(char: str) -> bool:
    """문자가 이모지인지 확인"""
    # 유니코드 범위로 이모지 판단
    code = ord(char)
    return (
        (0x1F300 <= code <= 0x1F9FF) or  # Miscellaneous Symbols and Pictographs
        (0x1F600 <= code <= 0x1F64F) or  # Emoticons
        (0x1F680 <= code <= 0x1F6FF) or  # Transport and Map Symbols
        (0x2600 <= code <= 0x26FF) or     # Miscellaneous Symbols
        (0x2700 <= code <= 0x27BF) or     # Dingbats
        (0x1F900 <= code <= 0x1F9FF) or  # Supplemental Symbols and Pictographs
        (0x1F1E0 <= code <= 0x1F1FF) or  # Regional Indicator Symbols (국기)
        (0x2300 <= code <= 0x23FF)        # Miscellaneous Technical (⏱️ 등)
    )


def split_text_and_emojis(text: str) -> list[tuple[str, bool]]:
    """텍스트를 일반 텍스트와 이모지로 분리"""
    result = []
    current_text = ""
    
    i = 0
    while i < len(text):
        char = text[i]
        
        # Variation Selector (FE0F) 또는 Zero Width Joiner (200D) 체크
        is_variation_selector = ord(char) == 0xFE0F
        is_zwj = ord(char) == 0x200D
        
        # 국기 이모지 체크 (2글자 조합)
        if i + 1 < len(text) and is_emoji(char) and is_emoji(text[i + 1]):
            if current_text:
                result.append((current_text, False))
                current_text = ""
            result.append((char + text[i + 1], True))
            i += 2
        elif is_emoji(char):
            # 이모지 + Variation Selector 체크
            emoji_chars = char
            j = i + 1
            # 다음 문자가 Variation Selector나 ZWJ인 경우 포함
            while j < len(text) and (ord(text[j]) == 0xFE0F or ord(text[j]) == 0x200D):
                emoji_chars += text[j]
                j += 1
            
            if current_text:
                result.append((current_text, False))
                current_text = ""
            result.append((emoji_chars, True))
            i = j
        else:
            current_text += char
            i += 1
    
    if current_text:
        result.append((current_text, False))
    
    return result


def draw_centered_text(
    draw: ImageDraw.Draw,
    text: str,
    y: int,
    font: ImageFont.FreeTypeFont,
    fill: str = TEXT_COLOR,
    width: int = WIDTH,
    img: Image.Image | None = None,
):
    """
    중앙 정렬 텍스트 그리기 (이모지 지원, 유동적 Safe Zone 적용)
    
    Args:
        draw: ImageDraw 객체
        text: 텍스트 (이모지 포함 가능)
        y: Y 좌표
        font: 폰트
        fill: 텍스트 색상
        width: 전체 너비 (기본값: 전체 화면 너비, 필요시 SAFE_ZONE_WIDTH 사용 가능)
        img: 배경 이미지 (이모지 삽입용)
    """
    # 이모지와 텍스트 분리
    parts = split_text_and_emojis(text)
    
    # 전체 너비 계산
    total_width = 0
    emoji_size = int(font.size * 1.2)  # 이모지 크기 (폰트보다 약간 크게)
    
    for part_text, is_emoji in parts:
        if is_emoji:
            total_width += emoji_size
        else:
            part_width, _ = get_text_size(draw, part_text, font)
            total_width += part_width
    
    # 시작 X 좌표 (중앙 정렬)
    # width가 WIDTH인 경우 전체 화면 기준, SAFE_ZONE_WIDTH인 경우 Safe Zone 기준
    if width == WIDTH:
        x = (width - total_width) // 2
    else:
        x = SAFE_ZONE_LEFT + (width - total_width) // 2
    
    # 각 부분 그리기
    for part_text, is_emoji in parts:
        if is_emoji:
            # 이모지 이미지 삽입
            emoji_img = load_emoji_image(part_text, emoji_size)
            if emoji_img and img:
                # 이미지에 이모지 삽입 (투명도 처리)
                emoji_x = x
                emoji_y = y + (font.size - emoji_size) // 2  # 수직 정렬
                # RGBA 모드인 경우 alpha 채널을 마스크로 사용
                if emoji_img.mode == "RGBA":
                    img.paste(emoji_img, (emoji_x, emoji_y), emoji_img.split()[3])  # alpha 채널을 마스크로
                else:
                    img.paste(emoji_img, (emoji_x, emoji_y))
                x += emoji_size
            else:
                # 이모지 이미지가 없으면 텍스트로 대체
                draw.text((x, y), part_text, font=font, fill=fill)
                part_width, _ = get_text_size(draw, part_text, font)
                x += part_width
        else:
            # 일반 텍스트
            draw.text((x, y), part_text, font=font, fill=fill)
            part_width, _ = get_text_size(draw, part_text, font)
            x += part_width


def render_intro_frame(question: QuizQuestion) -> Image.Image:
    """
    인트로 프레임 렌더링 (0-3초)
    - 퀴즈 유형과 난이도 표시
    """
    img = create_gradient_background(WIDTH, HEIGHT)
    draw = ImageDraw.Draw(img)
    
    # 타이틀 폰트
    title_font = get_font(80, bold=True)
    subtitle_font = get_font(48)
    level_font = get_font(56, bold=True)
    
    # 🇯🇵 일본어 퀴즈 (이모지 이미지로 표시) - Safe Zone 내부
    draw_centered_text(draw, "🇯🇵 일본어 퀴즈", SAFE_ZONE_TOP + 100, title_font, img=img)
    
    # 퀴즈 유형 프롬프트
    prompt = question.get_question_prompt()
    draw_centered_text(draw, f"「{prompt}」", SAFE_ZONE_TOP + 250, subtitle_font, fill="#cccccc", img=img)
    
    # 퀴즈 유형 뱃지 - Safe Zone 기준 중앙 정렬
    quiz_type_display = question.get_quiz_type_display()
    badge_width = 200
    badge_height = 60
    badge_x = SAFE_ZONE_LEFT + (SAFE_ZONE_WIDTH - badge_width) // 2
    badge_y = SAFE_ZONE_TOP + 380
    draw_rounded_rectangle(
        draw,
        (badge_x, badge_y, badge_x + badge_width, badge_y + badge_height),
        radius=30,
        fill=PRIMARY_COLOR,
    )
    draw_centered_text(draw, quiz_type_display, badge_y + 8, get_font(36, bold=True), img=img)
    
    # JLPT 레벨 (있는 경우) - Safe Zone 내부
    if question.jlpt_level:
        level_text = f"JLPT N{question.jlpt_level}"
        draw_centered_text(draw, level_text, SAFE_ZONE_TOP + 500, level_font, fill=CORRECT_COLOR, img=img)
    
    # 하단 안내 - 하단에서 420px 위
    draw_centered_text(draw, "10초 안에 정답을 맞춰보세요!", HEIGHT - SAFE_ZONE_BOTTOM - 50, get_font(36), fill="#888888", img=img)
    
    return img


def render_question_frame(question: QuizQuestion, countdown: int) -> Image.Image:
    """
    문제 프레임 렌더링 (3-13초)
    - 문제와 4개의 선택지
    - 카운트다운 타이머
    """
    img = create_gradient_background(WIDTH, HEIGHT)
    draw = ImageDraw.Draw(img)
    
    # 폰트
    timer_font = get_font(72, bold=True)
    question_font = get_font(64, bold=True)
    option_font = get_font(52, bold=True)  # 크기 키우고 bold
    level_font = get_font(48, bold=True)  # 크기 키우고 bold
    
    # JLPT 레벨 (상단 중앙) - 상단 바 제거로 인해 상단 중앙 배치
    if question.jlpt_level:
        level_text = f"N{question.jlpt_level}"
        draw_centered_text(draw, level_text, SAFE_ZONE_TOP - 50, level_font, fill=CORRECT_COLOR, img=img)
    
    # 문제 영역 - Safe Zone 내부
    question_y = SAFE_ZONE_TOP + 50  # 상단에서 300px 아래
    prompt = question.get_question_prompt()
    draw_centered_text(draw, prompt, question_y, get_font(40), fill="#aaaaaa", img=img)  # 조금 키우기
    
    # 문제 텍스트 (큰 글씨)
    question_text = question.question
    # 긴 텍스트 처리
    if len(question_text) > 15:
        question_font = get_font(52, bold=True)
    if len(question_text) > 25:
        question_font = get_font(40, bold=True)
    
    draw_centered_text(draw, f"「 {question_text} 」", question_y + 100, question_font, img=img)
    
    # 선택지 영역 - Safe Zone 기준
    options_start_y = SAFE_ZONE_TOP + 350  # Safe Zone 내부
    option_height = 140
    option_margin = 30
    option_padding = SAFE_ZONE_LEFT  # 좌측 여백 40px
    option_width = SAFE_ZONE_WIDTH  # Safe Zone 너비 920px
    
    option_labels = ["①", "②", "③", "④"]
    
    for i, option in enumerate(question.options):
        y = options_start_y + i * (option_height + option_margin)
        
        # 선택지 배경 - Safe Zone 기준
        draw_rounded_rectangle(
            draw,
            (option_padding, y, option_padding + option_width, y + option_height),
            radius=20,
            fill=ACCENT_COLOR,
        )
        
        # 선택지 번호
        draw.text((option_padding + 30, y + 40), option_labels[i], font=option_font, fill=PRIMARY_COLOR)
        
        # 선택지 텍스트 (bold 적용)
        option_text = option
        if len(option_text) > 20:
            option_font_size = get_font(44, bold=True)  # 긴 텍스트도 bold
        else:
            option_font_size = option_font  # 이미 bold 적용됨
        
        draw.text((option_padding + 100, y + 45), option_text, font=option_font_size, fill=TEXT_COLOR)
    
    # 카운트다운 타이머 (하단 중앙) - 기존 "정답을 생각해보세요..." 위치로 이동
    timer_color = WRONG_COLOR if countdown <= 3 else TEXT_COLOR
    timer_text = f"⏱️ {countdown}"
    # 이모지가 포함된 텍스트는 draw_centered_text 대신 수동 처리
    timer_parts = split_text_and_emojis(timer_text)
    timer_y = HEIGHT - SAFE_ZONE_BOTTOM - 50
    # 전체 너비 계산
    total_timer_width = 0
    emoji_size = int(timer_font.size * 1.2)
    for part_text, is_emoji in timer_parts:
        if is_emoji:
            total_timer_width += emoji_size
        else:
            part_width, _ = get_text_size(draw, part_text, timer_font)
            total_timer_width += part_width
    
    timer_x = (WIDTH - total_timer_width) // 2
    for part_text, is_emoji in timer_parts:
        if is_emoji:
            emoji_img = load_emoji_image(part_text, emoji_size)
            if emoji_img:
                # RGBA 모드인 경우 alpha 채널을 마스크로 사용
                if emoji_img.mode == "RGBA":
                    img.paste(emoji_img, (timer_x, timer_y + (timer_font.size - emoji_size) // 2), emoji_img.split()[3])
                else:
                    img.paste(emoji_img, (timer_x, timer_y + (timer_font.size - emoji_size) // 2))
                timer_x += emoji_size
            else:
                draw.text((timer_x, timer_y), part_text, font=timer_font, fill=timer_color)
                part_width, _ = get_text_size(draw, part_text, timer_font)
                timer_x += part_width
        else:
            draw.text((timer_x, timer_y), part_text, font=timer_font, fill=timer_color)
            part_width, _ = get_text_size(draw, part_text, timer_font)
            timer_x += part_width
    
    return img


def render_answer_frame(question: QuizQuestion) -> Image.Image:
    """
    정답 프레임 렌더링 (13-18초, 5초)
    - 문제 표시
    - 정답 표시
    - 해설
    """
    img = create_gradient_background(WIDTH, HEIGHT)
    draw = ImageDraw.Draw(img)
    
    # 폰트
    answer_font = get_font(72, bold=True)
    explain_font = get_font(42)  # 해설 글자 크기 키우기
    
    # 정답 찾기
    correct_index = -1
    for i, opt in enumerate(question.options):
        if opt == question.correct_answer:
            correct_index = i
            break
    
    option_labels = ["①", "②", "③", "④"]
    
    # 문제 표시 - Safe Zone 내부 (상단 여백 250px 적용)
    question_y = SAFE_ZONE_TOP + 50  # y=300
    draw_centered_text(draw, question.get_question_prompt(), question_y, get_font(32), fill="#aaaaaa", img=img)
    draw_centered_text(draw, f"「 {question.question} 」", question_y + 100, get_font(48, bold=True), img=img)  # y=400
    
    # 정답 표시 - 문제 바로 아래에 배치
    answer_y = question_y + 200  # y=500 (문제 아래 100px 간격)
    draw_centered_text(draw, f"정답 {option_labels[correct_index]} {question.correct_answer}", answer_y, answer_font, fill=CORRECT_COLOR, img=img)
    
    # 해설 영역 - 정답과 해설 사이 간격 증가 (더 아래로 이동)
    explain_y = answer_y + 200  # y=700 (정답 아래 200px 간격)
    explain_left = SAFE_ZONE_LEFT
    explain_right = WIDTH - SAFE_ZONE_RIGHT
    draw.rectangle([explain_left, explain_y, explain_right, explain_y + 250], fill=SECONDARY_COLOR)
    draw_rounded_rectangle(
        draw,
        (explain_left, explain_y, explain_right, explain_y + 250),
        radius=20,
        fill=SECONDARY_COLOR,
    )
    
    draw_centered_text(draw, "💡 해설", explain_y + 20, get_font(36, bold=True), fill=PRIMARY_COLOR, img=img)
    
    # 해설 텍스트 (줄바꿈 처리)
    explanation = question.explanation
    max_chars_per_line = 25
    lines = []
    
    while len(explanation) > max_chars_per_line:
        lines.append(explanation[:max_chars_per_line])
        explanation = explanation[max_chars_per_line:]
    if explanation:
        lines.append(explanation)
    
    for i, line in enumerate(lines[:4]):  # 최대 4줄
        draw_centered_text(draw, line, explain_y + 80 + i * 45, explain_font, fill="#cccccc", img=img)
    
    return img


def render_account_frame() -> Image.Image:
    """
    계정 정보 프레임 렌더링 (18-23초, 5초)
    - 팔로우 유도 메시지
    - 인스타그램 계정 정보
    """
    img = create_gradient_background(WIDTH, HEIGHT)
    draw = ImageDraw.Draw(img)
    
    # 폰트
    main_font = get_font(56, bold=True)
    account_font = get_font(64, bold=True)
    
    # 메인 메시지 - 중앙에 배치
    main_y = HEIGHT // 2 - 80  # 화면 중앙에서 약간 위
    draw_centered_text(draw, "팔로우하고 더 많은 퀴즈를 풀어보세요!", main_y, main_font, fill=TEXT_COLOR, img=img)
    
    # 인스타그램 계정 - 메인 메시지 아래에 강조
    account_y = HEIGHT // 2 + 40  # 화면 중앙에서 약간 아래
    draw_centered_text(draw, "@jlpt.everyday", account_y, account_font, fill=PRIMARY_COLOR, img=img)
    
    return img


# 테스트용
if __name__ == "__main__":
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
    
    # 프레임 생성 테스트
    intro = render_intro_frame(test_question)
    intro.save("test_intro.png")
    print("✅ test_intro.png 저장됨")
    
    question_frame = render_question_frame(test_question, 10)
    question_frame.save("test_question.png")
    print("✅ test_question.png 저장됨")
    
    answer = render_answer_frame(test_question)
    answer.save("test_answer.png")
    print("✅ test_answer.png 저장됨")
