import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:google_fonts/google_fonts.dart';
import 'furigana_text.dart';

/// 예문 카드 위젯 - 한자/단어 학습 화면에서 공통으로 사용
class ExampleCard extends StatelessWidget {
  /// 일본어 텍스트
  final String japanese;

  /// 후리가나가 포함된 텍스트 (예: [漢字|かんじ])
  final String furigana;

  /// 한국어 번역
  final String korean;

  /// 추가 설명 (선택)
  final String? explanation;

  /// 출처 라벨 (예: '음독', '훈독', 'AI 생성')
  final String? sourceLabel;

  /// 일본어 폰트 크기
  final double japaneseFontSize;

  /// 후리가나 폰트 크기
  final double rubyFontSize;

  /// 한국어 폰트 크기
  final double koreanFontSize;

  const ExampleCard({
    super.key,
    required this.japanese,
    required this.furigana,
    required this.korean,
    this.explanation,
    this.sourceLabel,
    this.japaneseFontSize = 18,
    this.rubyFontSize = 10,
    this.koreanFontSize = 16,
  });

  @override
  Widget build(BuildContext context) {
    final theme = FTheme.of(context);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colors.background,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: theme.colors.border,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Source label
          if (sourceLabel != null && sourceLabel!.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: theme.colors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                sourceLabel!,
                style: theme.typography.xs.copyWith(
                  color: theme.colors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
          // Japanese text with furigana
          FuriganaText(
            text: furigana.contains('[') ? furigana : japanese,
            style: GoogleFonts.notoSerifJp(
              fontSize: japaneseFontSize,
              fontWeight: FontWeight.w500,
              color: theme.colors.foreground,
              height: 1.5,
            ),
            rubyStyle: theme.typography.sm.copyWith(
              color: theme.colors.mutedForeground,
              fontSize: rubyFontSize,
            ),
            spacing: -1.0,
          ),
          const SizedBox(height: 8),
          // Korean translation
          Text(
            korean,
            style: theme.typography.base.copyWith(
              fontWeight: FontWeight.w500,
              fontSize: koreanFontSize,
            ),
          ),
          // Explanation if exists
          if (explanation != null && explanation!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: theme.colors.mutedForeground.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                explanation!,
                style: theme.typography.sm.copyWith(
                  color: theme.colors.mutedForeground,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
