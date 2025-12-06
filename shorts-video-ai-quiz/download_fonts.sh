#!/bin/bash
# Noto Sans CJK 폰트 다운로드 스크립트

set -e

FONTS_DIR="assets/fonts"
mkdir -p "$FONTS_DIR"

echo "📥 Noto Sans CJK 폰트 다운로드 중..."

# Noto Sans CJK 다운로드 (Google Fonts GitHub)
# 한글/일본어/중국어 모두 지원하는 버전
NOTO_CJK_URL="https://github.com/google/fonts/raw/main/ofl/notosanscjksc/NotoSansCJK-Regular.ttc"
NOTO_CJK_BOLD_URL="https://github.com/google/fonts/raw/main/ofl/notosanscjksc/NotoSansCJK-Bold.ttc"

# Noto Sans KR (한글 전용, 더 확실한 한글 지원)
NOTO_KR_REGULAR_URL="https://github.com/google/fonts/raw/main/ofl/notosanskr/NotoSansKR-Regular.otf"
NOTO_KR_BOLD_URL="https://github.com/google/fonts/raw/main/ofl/notosanskr/NotoSansKR-Bold.otf"

# Regular 폰트 다운로드
if [ ! -f "$FONTS_DIR/NotoSansCJK-Regular.ttc" ]; then
    echo "다운로드 중: NotoSansCJK-Regular.ttc"
    curl -L -o "$FONTS_DIR/NotoSansCJK-Regular.ttc" "$NOTO_CJK_URL" || {
        echo "❌ 다운로드 실패. 수동으로 다운로드해주세요:"
        echo "   https://fonts.google.com/noto/specimen/Noto+Sans+JP"
        exit 1
    }
    echo "✅ NotoSansCJK-Regular.ttc 다운로드 완료"
else
    echo "✓ NotoSansCJK-Regular.ttc 이미 존재"
fi

# Bold 폰트 다운로드
if [ ! -f "$FONTS_DIR/NotoSansCJK-Bold.ttc" ]; then
    echo "다운로드 중: NotoSansCJK-Bold.ttc"
    curl -L -o "$FONTS_DIR/NotoSansCJK-Bold.ttc" "$NOTO_CJK_BOLD_URL" || {
        echo "⚠️  Bold 폰트 다운로드 실패 (선택사항)"
    }
    echo "✅ NotoSansCJK-Bold.ttc 다운로드 완료"
else
    echo "✓ NotoSansCJK-Bold.ttc 이미 존재"
fi

# Noto Sans KR 다운로드 (한글 지원 강화)
echo ""
echo "📥 Noto Sans KR 폰트 다운로드 중 (한글 지원)..."
if [ ! -f "$FONTS_DIR/NotoSansKR-Regular.otf" ]; then
    echo "다운로드 중: NotoSansKR-Regular.otf"
    curl -L -o "$FONTS_DIR/NotoSansKR-Regular.otf" "$NOTO_KR_REGULAR_URL" || {
        echo "⚠️  Noto Sans KR Regular 다운로드 실패"
    }
    echo "✅ NotoSansKR-Regular.otf 다운로드 완료"
else
    echo "✓ NotoSansKR-Regular.otf 이미 존재"
fi

if [ ! -f "$FONTS_DIR/NotoSansKR-Bold.otf" ]; then
    echo "다운로드 중: NotoSansKR-Bold.otf"
    curl -L -o "$FONTS_DIR/NotoSansKR-Bold.otf" "$NOTO_KR_BOLD_URL" || {
        echo "⚠️  Noto Sans KR Bold 다운로드 실패"
    }
    echo "✅ NotoSansKR-Bold.otf 다운로드 완료"
else
    echo "✓ NotoSansKR-Bold.otf 이미 존재"
fi

echo ""
echo "🎉 폰트 다운로드 완료!"
echo "📁 폰트 위치: $FONTS_DIR"
echo ""
echo "다음 단계:"
echo "1. 서버를 재시작하세요"
echo "2. 테스트 영상을 생성해보세요"

