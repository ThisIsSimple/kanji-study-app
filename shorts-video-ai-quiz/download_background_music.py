"""
배경음악 다운로드 스크립트
퀴즈 영상에 적합한 배경음악 다운로드
"""

import os
import requests
from pathlib import Path

# 효과음 저장 경로
SCRIPT_DIR = Path(__file__).parent
SOUNDS_DIR = SCRIPT_DIR / "assets" / "sounds"
SOUNDS_DIR.mkdir(parents=True, exist_ok=True)

# 배경음악 다운로드 URL (무료, 로열티 프리)
# Mixkit, Free Music Archive 등에서 직접 다운로드 가능한 링크
BACKGROUND_MUSIC_URLS = {
    "upbeat_quiz.mp3": "https://cdn.mixkit.co/music/preview/mixkit-game-show-987.mp3",
    "energetic_loop.mp3": "https://cdn.mixkit.co/music/preview/mixkit-tech-house-vibes-130.mp3",
    "fun_quiz.mp3": "https://cdn.mixkit.co/music/preview/mixkit-summer-game-show-987.mp3",
    "game_music.mp3": "https://cdn.mixkit.co/music/preview/mixkit-gaming-988.mp3",
    "upbeat_electronic.mp3": "https://cdn.mixkit.co/music/preview/mixkit-electronic-hip-hop-988.mp3",
}


def generate_background_music(output_path: Path, style: str = "upbeat", duration: float = 20.0) -> bool:
    """간단한 배경음악 생성 (numpy/scipy 사용)"""
    try:
        import numpy as np
        from scipy.io import wavfile
        
        sample_rate = 44100
        t = np.linspace(0, duration, int(sample_rate * duration))
        
        if style == "upbeat":
            # 경쾌한 스타일
            wave = (
                np.sin(2 * np.pi * 220 * t) * 0.1 +  # A3
                np.sin(2 * np.pi * 330 * t) * 0.1 +  # E4
                np.sin(2 * np.pi * 440 * t) * 0.15 +  # A4
                np.sin(2 * np.pi * 880 * t) * 0.05   # A5
            )
            beat_freq = 2.0
            volume = 0.2
        elif style == "energetic":
            # 에너지 넘치는 스타일
            wave = (
                np.sin(2 * np.pi * 262 * t) * 0.12 +  # C4
                np.sin(2 * np.pi * 392 * t) * 0.12 +  # G4
                np.sin(2 * np.pi * 523 * t) * 0.18 +  # C5
                np.sin(2 * np.pi * 659 * t) * 0.08   # E5
            )
            beat_freq = 1.5
            volume = 0.25
        elif style == "fun":
            # 재미있는 스타일
            wave = (
                np.sin(2 * np.pi * 196 * t) * 0.1 +  # G3
                np.sin(2 * np.pi * 294 * t) * 0.1 +  # D4
                np.sin(2 * np.pi * 392 * t) * 0.15 +  # G4
                np.sin(2 * np.pi * 523 * t) * 0.1   # C5
            )
            beat_freq = 2.5
            volume = 0.18
        else:  # default
            wave = (
                np.sin(2 * np.pi * 220 * t) * 0.1 +
                np.sin(2 * np.pi * 330 * t) * 0.1 +
                np.sin(2 * np.pi * 440 * t) * 0.15
            )
            beat_freq = 2.0
            volume = 0.2
        
        # 리듬 추가
        beat = np.sin(2 * np.pi * beat_freq * t) * 0.1
        wave = wave + beat
        
        # 감쇠 적용
        envelope = 0.5 + 0.5 * np.sin(2 * np.pi * 0.1 * t)
        wave = wave * envelope
        
        # 볼륨 조절 및 정규화
        wave = np.clip(wave, -1, 1)
        wave = (wave * volume * 32767).astype(np.int16)
        
        wavfile.write(str(output_path), sample_rate, wave)
        print(f"✅ 배경음악 생성 완료: {output_path.name} ({style})")
        return True
    except ImportError:
        print("❌ scipy가 설치되지 않음")
        return False
    except Exception as e:
        print(f"❌ 배경음악 생성 실패: {e}")
        return False


def download_music(filename: str, url: str, output_dir: Path) -> bool:
    """배경음악 다운로드"""
    output_path = output_dir / filename
    
    if output_path.exists():
        print(f"✓ {filename} 이미 존재")
        return True
    
    try:
        print(f"다운로드 중: {filename}")
        response = requests.get(url, timeout=30, stream=True)
        response.raise_for_status()
        
        # 파일 크기 확인
        total_size = int(response.headers.get('content-length', 0))
        if total_size < 1000:  # 1KB 미만이면 잘못된 파일
            print(f"❌ 파일 크기가 너무 작음: {total_size} bytes")
            return False
        
        with open(output_path, "wb") as f:
            for chunk in response.iter_content(chunk_size=8192):
                f.write(chunk)
        
        file_size = output_path.stat().st_size
        print(f"✅ 다운로드 완료: {filename} ({file_size / 1024:.1f} KB)")
        return True
    except Exception as e:
        print(f"❌ 다운로드 실패 {filename}: {e}")
        return False


def main():
    """메인 함수"""
    print(f"📁 배경음악 저장 경로: {SOUNDS_DIR}")
    
    # 1. 웹에서 다운로드 시도
    if BACKGROUND_MUSIC_URLS:
        print(f"📥 다운로드할 배경음악: {len(BACKGROUND_MUSIC_URLS)}개\n")
        success_count = 0
        for filename, url in BACKGROUND_MUSIC_URLS.items():
            if download_music(filename, url, SOUNDS_DIR):
                success_count += 1
            print()
        print(f"다운로드 완료: {success_count}/{len(BACKGROUND_MUSIC_URLS)}개\n")
    
    # 2. 여러 스타일의 배경음악 생성
    print("🎵 배경음악 생성 중...\n")
    music_styles = [
        ("background_music_upbeat.wav", "upbeat"),
        ("background_music_energetic.wav", "energetic"),
        ("background_music_fun.wav", "fun"),
    ]
    
    success_count = 0
    for filename, style in music_styles:
        bg_music_path = SOUNDS_DIR / filename
        if not bg_music_path.exists():
            if generate_background_music(bg_music_path, style=style, duration=20.0):
                success_count += 1
        else:
            print(f"✓ {filename} 이미 존재")
            success_count += 1
    
    print(f"\n✅ {success_count}/{len(music_styles)}개 배경음악 준비 완료\n")
    
    # 3. 안내 메시지
    print("💡 추천:")
    print("   수동으로 무료 배경음악을 다운로드하여 다음 경로에 추가하세요:")
    print(f"   {SOUNDS_DIR}")
    print("\n   추천 사이트:")
    print("   - https://mixkit.co/free-stock-music/")
    print("   - https://freemusicarchive.org/")
    print("   - https://www.bensound.com/")
    print("   - https://pixabay.com/music/")
    print("\n   추천 검색어:")
    print("   - 'upbeat quiz music'")
    print("   - 'game show background'")
    print("   - 'energetic instrumental'")
    print("   - 'fun educational music'")


if __name__ == "__main__":
    main()

