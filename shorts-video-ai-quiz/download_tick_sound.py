"""
카운트다운 효과음 다운로드 스크립트
째깍째깍 소리 (tick/click sound) 다운로드
"""

import os
import requests
from pathlib import Path

# 효과음 저장 경로
SCRIPT_DIR = Path(__file__).parent
SOUNDS_DIR = SCRIPT_DIR / "assets" / "sounds"
SOUNDS_DIR.mkdir(parents=True, exist_ok=True)

# 효과음 다운로드 URL (무료 효과음)
# 간단한 tick 소리를 다운로드하거나, numpy로 생성
TICK_SOUND_URLS = [
    # 무료 효과음 사이트 (직접 URL이 있는 경우)
    # 또는 간단한 beep 소리를 생성
]


def generate_tick_sound(output_path: Path) -> bool:
    """numpy를 사용하여 간단한 tick 소리 생성"""
    try:
        import numpy as np
        from scipy.io import wavfile
        
        # 샘플링 레이트
        sample_rate = 44100
        duration = 0.15  # 0.15초 짧은 tick 소리
        
        # 주파수 (높은 주파수로 tick 소리)
        frequency = 2000  # 2kHz
        
        # 사인파 생성
        t = np.linspace(0, duration, int(sample_rate * duration))
        # 감쇠 적용 (자연스러운 소리)
        envelope = np.exp(-t * 10)
        wave = np.sin(2 * np.pi * frequency * t) * envelope
        
        # 볼륨 조절
        wave = (wave * 0.3 * 32767).astype(np.int16)
        
        # WAV 파일로 저장
        wavfile.write(str(output_path), sample_rate, wave)
        print(f"✅ Tick 소리 생성 완료: {output_path}")
        return True
    except ImportError:
        print("❌ scipy가 설치되지 않음. pip install scipy 실행 필요")
        return False
    except Exception as e:
        print(f"❌ Tick 소리 생성 실패: {e}")
        return False


def download_tick_sound(output_path: Path) -> bool:
    """웹에서 tick 소리 다운로드 시도"""
    for url in TICK_SOUND_URLS:
        try:
            print(f"다운로드 시도: {url}")
            response = requests.get(url, timeout=10)
            response.raise_for_status()
            
            with open(output_path, "wb") as f:
                f.write(response.content)
            
            print(f"✅ 다운로드 완료: {output_path}")
            return True
        except Exception as e:
            print(f"다운로드 실패: {e}")
            continue
    
    return False


def main():
    """메인 함수"""
    tick_sound_path = SOUNDS_DIR / "tick.wav"
    
    print(f"📁 효과음 저장 경로: {SOUNDS_DIR}")
    
    if tick_sound_path.exists():
        print(f"✓ Tick 소리 이미 존재: {tick_sound_path}")
        return
    
    print("🔊 Tick 소리 생성 중...")
    
    # 먼저 numpy로 생성 시도
    if generate_tick_sound(tick_sound_path):
        return
    
    # 생성 실패 시 다운로드 시도
    print("🌐 웹에서 다운로드 시도...")
    if download_tick_sound(tick_sound_path):
        return
    
    print("\n⚠️  효과음 생성/다운로드 실패")
    print("수동으로 효과음 파일을 다음 경로에 추가하세요:")
    print(f"   {tick_sound_path}")
    print("\n추천 사이트:")
    print("   - https://freesound.org/")
    print("   - https://mixkit.co/free-sound-effects/click/")


if __name__ == "__main__":
    main()

