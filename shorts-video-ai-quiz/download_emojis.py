"""
이모지 이미지 다운로드 스크립트
OpenMoji를 사용하여 이모지를 PNG 이미지로 다운로드
"""

import os
import requests
from pathlib import Path
from urllib.parse import quote

# 사용 중인 이모지 목록
EMOJIS = {
    "🇯🇵": "1f1ef-1f1f5",  # 일본 국기
    "⏱️": "23f1-fe0f",     # 타이머
    "✅": "2705",          # 체크마크
    "💡": "1f4a1",         # 전구
    "👆": "1f446",         # 위쪽 손가락
}

# Emoji API 사용 (더 안정적)
# emoji-api.com 또는 다른 서비스 사용
EMOJI_API_BASE_URL = "https://emojiapi.dev/api/emojis"
# 또는 Google Noto Emoji 사용
NOTO_EMOJI_BASE_URL = "https://fonts.gstatic.com/s/notoemoji/v2"
# 또는 직접 Twemoji GitHub 사용
TWEMOJI_GITHUB_BASE_URL = "https://raw.githubusercontent.com/twitter/twemoji/main/assets/72x72"


def get_emoji_unicode(emoji: str) -> str:
    """이모지를 유니코드 코드포인트로 변환 (Twemoji 형식)"""
    # Variation Selector 제거 (FE0F 등)
    codes = [f"{ord(c):x}" for c in emoji if ord(c) not in [0xFE0F, 0x200D]]
    # 소문자로 변환
    return "-".join(codes).lower()


def download_emoji(emoji: str, output_dir: Path) -> bool:
    """이모지 이미지 다운로드"""
    # 유니코드 코드포인트로 변환
    unicode_str = get_emoji_unicode(emoji)
    
    # 파일명 생성 (이모지 문자를 파일명으로 사용)
    safe_name = "".join([f"U{ord(c):04X}" for c in emoji if ord(c) not in [0xFE0F, 0x200D]])
    output_path = output_dir / f"{safe_name}.png"
    
    # 여러 소스 시도
    urls = [
        f"{TWEMOJI_GITHUB_BASE_URL}/{unicode_str}.png",
        f"https://cdn.jsdelivr.net/gh/twitter/twemoji@latest/assets/72x72/{unicode_str}.png",
    ]
    
    for url in urls:
        try:
            print(f"다운로드 시도: {emoji} ({unicode_str}) - {url.split('/')[-2]}")
            response = requests.get(url, timeout=10)
            response.raise_for_status()
            
            # PNG 이미지인지 확인
            if response.headers.get('content-type', '').startswith('image/'):
                with open(output_path, "wb") as f:
                    f.write(response.content)
                
                print(f"✅ 저장됨: {output_path}")
                return True
        except Exception as e:
            continue
    
    print(f"❌ 모든 소스에서 다운로드 실패: {emoji}")
    return False


def main():
    """메인 함수"""
    # 출력 디렉토리 생성
    script_dir = Path(__file__).parent
    emojis_dir = script_dir / "assets" / "emojis"
    emojis_dir.mkdir(parents=True, exist_ok=True)
    
    print(f"📁 이모지 저장 경로: {emojis_dir}")
    print(f"📥 다운로드할 이모지: {len(EMOJIS)}개\n")
    
    success_count = 0
    for emoji in EMOJIS.keys():
        if download_emoji(emoji, emojis_dir):
            success_count += 1
        print()
    
    print(f"🎉 완료: {success_count}/{len(EMOJIS)}개 이모지 다운로드됨")
    
    if success_count < len(EMOJIS):
        print("\n⚠️  일부 이모지 다운로드 실패. 수동으로 다운로드하거나 다른 소스를 사용하세요.")
        print("   - Twemoji: https://twemoji.twitter.com/")
        print("   - OpenMoji: https://openmoji.org/")


if __name__ == "__main__":
    main()

