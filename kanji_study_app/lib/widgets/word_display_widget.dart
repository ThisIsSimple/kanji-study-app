import 'dart:math' as math;
import 'package:flutter/gestures.dart';
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
    // 후리가나 스타일 (본문의 45% 크기)
    final rubySize = effectiveSize * 0.45;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: _textAlignToCrossAxisAlignment(textAlign),
      children: [
        // 후리가나
        Text(
          reading!,
          style: GoogleFonts.notoSansJp(
            fontSize: rubySize,
            color: effectiveColor.withValues(alpha: 0.7),
            fontWeight: FontWeight.normal,
          ),
          textAlign: textAlign,
        ),
        SizedBox(height: effectiveSize * 0.05),
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

  /// RichText로 글자별 스타일링
  Widget _buildRichText({
    required BuildContext context,
    required FThemeData theme,
    required Color effectiveColor,
    required double effectiveSize,
    required Map<String, Kanji?> kanjiMap,
  }) {
    final spans = <InlineSpan>[];

    for (int i = 0; i < word.length; i++) {
      final char = word[i];
      final isKanjiChar = isKanji(char);
      final kanji = kanjiMap[char];
      final hasKanjiData = kanji != null;

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

      // 한자 힌트가 활성화되고, 한자이며, 캐시에 데이터가 있는 경우
      if (showKanjiHint && isKanjiChar && hasKanjiData) {
        // 점선 밑줄 스타일 추가
        final underlinedStyle = baseStyle.copyWith(
          decoration: TextDecoration.underline,
          decorationStyle: TextDecorationStyle.dotted,
          decorationColor: theme.colors.mutedForeground.withValues(alpha: 0.5),
          decorationThickness: 1.5,
        );

        spans.add(
          TextSpan(
            text: char,
            style: underlinedStyle,
            recognizer: TapGestureRecognizer()
              ..onTap = () {
                KanjiInfoCard.showKanjiInfoSheet(
                  context: context,
                  kanji: kanji,
                );
              },
          ),
        );
      } else {
        // 일반 텍스트
        spans.add(
          TextSpan(
            text: char,
            style: baseStyle,
          ),
        );
      }
    }

    return RichText(
      text: TextSpan(children: spans),
      textAlign: textAlign,
    );
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
