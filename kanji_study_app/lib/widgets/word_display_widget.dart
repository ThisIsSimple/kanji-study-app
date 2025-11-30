import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/kanji_model.dart';
import '../services/kanji_repository.dart';
import 'kanji_info_card.dart';

/// 단어 표시 위젯
///
/// 단어를 표시하며, 다양한 옵션을 통해 후리가나, 획순, 한자 힌트 등을 제공합니다.
///
/// 예시:
/// ```dart
/// WordDisplayWidget(
///   word: '食べる',
///   reading: 'たべる',
///   size: 32,
///   showFurigana: true,
///   showKanjiHint: true,
/// )
/// ```
class WordDisplayWidget extends StatelessWidget {
  /// 표시할 단어
  final String word;

  /// 후리가나 (읽기)
  final String? reading;

  /// 폰트 크기 (기본: 24)
  final double size;

  /// 획순 폰트 표시 여부
  final bool showStrokeOrder;

  /// 한자 힌트 밑줄 표시 여부 (탭하면 한자 정보 바텀시트)
  final bool showKanjiHint;

  /// 후리가나 표시 여부
  final bool showFurigana;

  /// 커스텀 텍스트 색상
  final Color? textColor;

  /// 전체 위젯 탭 콜백
  final VoidCallback? onTap;

  /// 텍스트 정렬
  final TextAlign textAlign;

  const WordDisplayWidget({
    super.key,
    required this.word,
    this.reading,
    this.size = 24,
    this.showStrokeOrder = false,
    this.showKanjiHint = false,
    this.showFurigana = false,
    this.textColor,
    this.onTap,
    this.textAlign = TextAlign.center,
  });

  /// 한자 유니코드 범위 체크
  static bool isKanji(String char) {
    if (char.isEmpty) return false;
    final codeUnit = char.codeUnitAt(0);
    // CJK Unified Ideographs: U+4E00 - U+9FFF
    return codeUnit >= 0x4E00 && codeUnit <= 0x9FFF;
  }

  /// 단어에서 한자를 추출하고 캐시된 데이터와 매칭
  Map<String, Kanji?> _extractKanjiWithData() {
    final Map<String, Kanji?> kanjiMap = {};
    final repository = KanjiRepository.instance;

    for (int i = 0; i < word.length; i++) {
      final char = word[i];
      if (isKanji(char) && !kanjiMap.containsKey(char)) {
        kanjiMap[char] = repository.getKanjiByCharacter(char);
      }
    }

    return kanjiMap;
  }

  @override
  Widget build(BuildContext context) {
    final theme = FTheme.of(context);
    final effectiveColor = textColor ?? theme.colors.foreground;

    // 획순 모드일 때 폰트 크기 조정 (최소 80)
    final effectiveSize = showStrokeOrder ? math.max(80.0, size) : size;

    // 한자 데이터 추출
    final kanjiMap = showKanjiHint ? _extractKanjiWithData() : <String, Kanji?>{};

    Widget content;

    if (showFurigana && reading != null && reading!.isNotEmpty) {
      // 후리가나 + 본문 표시
      content = _buildWithFurigana(
        context: context,
        theme: theme,
        effectiveColor: effectiveColor,
        effectiveSize: effectiveSize,
        kanjiMap: kanjiMap,
      );
    } else {
      // 본문만 표시
      content = _buildPlainText(
        context: context,
        theme: theme,
        effectiveColor: effectiveColor,
        effectiveSize: effectiveSize,
        kanjiMap: kanjiMap,
      );
    }

    // onTap이 있으면 전체를 탭 가능하게
    if (onTap != null) {
      return GestureDetector(
        onTap: onTap,
        child: content,
      );
    }

    return content;
  }

  /// 후리가나와 함께 표시
  Widget _buildWithFurigana({
    required BuildContext context,
    required FThemeData theme,
    required Color effectiveColor,
    required double effectiveSize,
    required Map<String, Kanji?> kanjiMap,
  }) {
    // 후리가나 스타일 (본문의 35% 크기로 축소)
    final rubySize = effectiveSize * 0.35;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: _textAlignToCrossAxisAlignment(textAlign),
      children: [
        // 후리가나
        Text(
          reading!,
          style: GoogleFonts.notoSansJp(
            fontSize: rubySize,
            color: effectiveColor.withValues(alpha: 0.6),
            fontWeight: FontWeight.normal,
          ),
          textAlign: textAlign,
        ),
        SizedBox(height: effectiveSize * 0.02), // 간격 축소
        // 본문
        _buildRichText(
          context: context,
          theme: theme,
          effectiveColor: effectiveColor,
          effectiveSize: effectiveSize,
          kanjiMap: kanjiMap,
        ),
      ],
    );
  }

  /// 본문만 표시
  Widget _buildPlainText({
    required BuildContext context,
    required FThemeData theme,
    required Color effectiveColor,
    required double effectiveSize,
    required Map<String, Kanji?> kanjiMap,
  }) {
    return _buildRichText(
      context: context,
      theme: theme,
      effectiveColor: effectiveColor,
      effectiveSize: effectiveSize,
      kanjiMap: kanjiMap,
    );
  }

  /// Row로 글자별 스타일링 (정렬 문제 해결)
  Widget _buildRichText({
    required BuildContext context,
    required FThemeData theme,
    required Color effectiveColor,
    required double effectiveSize,
    required Map<String, Kanji?> kanjiMap,
  }) {
    // 기본 텍스트 스타일
    TextStyle baseStyle;
    if (showStrokeOrder) {
      baseStyle = TextStyle(
        fontFamily: 'KanjiStrokeOrders',
        fontSize: effectiveSize,
        fontWeight: FontWeight.normal,
        color: effectiveColor,
      );
    } else {
      baseStyle = GoogleFonts.notoSerifJp(
        fontSize: effectiveSize,
        fontWeight: FontWeight.bold,
        color: effectiveColor,
      );
    }

    final children = <Widget>[];

    for (int i = 0; i < word.length; i++) {
      final char = word[i];
      final isKanjiChar = isKanji(char);
      final kanji = kanjiMap[char];
      final hasKanjiData = kanji != null;

      // 한자 힌트가 활성화되고, 한자이며, 캐시에 데이터가 있는 경우
      if (showKanjiHint && isKanjiChar && hasKanjiData) {
        children.add(
          _RoundedDottedUnderlineText(
            text: char,
            style: baseStyle,
            dotColor: theme.colors.mutedForeground.withValues(alpha: 0.6),
            onTap: () {
              KanjiInfoCard.showKanjiInfoSheet(
                context: context,
                kanji: kanji,
              );
            },
          ),
        );
      } else {
        // 일반 텍스트
        children.add(Text(char, style: baseStyle));
      }
    }

    return Wrap(
      alignment: _textAlignToWrapAlignment(textAlign),
      crossAxisAlignment: WrapCrossAlignment.end,
      children: children,
    );
  }

  WrapAlignment _textAlignToWrapAlignment(TextAlign align) {
    switch (align) {
      case TextAlign.left:
      case TextAlign.start:
        return WrapAlignment.start;
      case TextAlign.right:
      case TextAlign.end:
        return WrapAlignment.end;
      case TextAlign.center:
      case TextAlign.justify:
        return WrapAlignment.center;
    }
  }

  CrossAxisAlignment _textAlignToCrossAxisAlignment(TextAlign align) {
    switch (align) {
      case TextAlign.left:
      case TextAlign.start:
        return CrossAxisAlignment.start;
      case TextAlign.right:
      case TextAlign.end:
        return CrossAxisAlignment.end;
      case TextAlign.center:
      case TextAlign.justify:
        return CrossAxisAlignment.center;
    }
  }
}

/// 둥근 점선 밑줄이 있는 텍스트 위젯
class _RoundedDottedUnderlineText extends StatelessWidget {
  final String text;
  final TextStyle style;
  final Color dotColor;
  final VoidCallback onTap;

  const _RoundedDottedUnderlineText({
    required this.text,
    required this.style,
    required this.dotColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final fontSize = style.fontSize ?? 24;

    return GestureDetector(
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Text(text, style: style),
          Positioned(
            left: 0,
            right: 0,
            bottom: fontSize * 0.05, // 텍스트 바닥에서 약간 위
            child: CustomPaint(
              size: Size.zero,
              painter: _RoundedDotsPainter(
                color: dotColor,
                fontSize: fontSize,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 둥근 점선을 그리는 CustomPainter
class _RoundedDotsPainter extends CustomPainter {
  final Color color;
  final double fontSize;

  _RoundedDotsPainter({
    required this.color,
    required this.fontSize,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    // 점 크기와 간격을 폰트 크기에 비례하게 설정
    final dotRadius = fontSize * 0.03; // 점 반지름
    final dotSpacing = fontSize * 0.12; // 점 간격

    // 텍스트 너비 추정 (한자는 대략 폰트 크기와 비슷)
    final charWidth = fontSize;

    // 점선 영역을 80%로 제한 (좌우 10%씩 여백)
    final startX = charWidth * 0.1;
    final endX = charWidth * 0.9;
    final lineWidth = endX - startX;

    // 점 개수 계산
    final dotCount = (lineWidth / (dotRadius * 2 + dotSpacing)).floor();
    if (dotCount <= 0) return;

    final actualSpacing = dotCount > 1
        ? (lineWidth - dotCount * dotRadius * 2) / (dotCount - 1)
        : 0.0;

    for (int i = 0; i < dotCount; i++) {
      final x = startX + dotRadius + i * (dotRadius * 2 + actualSpacing);
      canvas.drawCircle(Offset(x, 0), dotRadius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _RoundedDotsPainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.fontSize != fontSize;
  }
}
