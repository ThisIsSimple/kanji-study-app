import 'package:flutter/material.dart';
import 'package:ruby_text/ruby_text.dart';
import '../utils/furigana_parser.dart';

/// Furigana 형식의 텍스트를 표시하는 위젯
/// 
/// 예시:
/// ```dart
/// FuriganaText(
///   text: '野菜[やさい]を蒸[む]すのは健康的[けんこうてき]です。',
///   style: TextStyle(fontSize: 18),
///   rubyStyle: TextStyle(fontSize: 10),
/// )
/// ```
class FuriganaText extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final TextStyle? rubyStyle;
  final TextAlign? textAlign;
  final TextDirection? textDirection;
  final bool? softWrap;
  final TextOverflow? overflow;
  final int? maxLines;
  final double spacing;
  
  const FuriganaText({
    super.key,
    required this.text,
    this.style,
    this.rubyStyle,
    this.textAlign,
    this.textDirection,
    this.softWrap,
    this.overflow,
    this.maxLines,
    this.spacing = -0.5,  // 기본값을 -0.5로 설정해서 간격을 좁힘
  });
  
  @override
  Widget build(BuildContext context) {
    // 텍스트가 비어있거나 대괄호가 없으면 일반 Text 위젯 사용
    if (text.isEmpty || !text.contains('[')) {
      return Text(
        text,
        style: style,
        textAlign: textAlign,
        textDirection: textDirection,
        softWrap: softWrap,
        overflow: overflow,
        maxLines: maxLines,
      );
    }
    
    // Furigana 파싱
    final rubyData = FuriganaParser.parse(text);
    
    // RubyText 위젯 사용
    return RubyText(
      rubyData,
      style: style,
      rubyStyle: rubyStyle ?? _getDefaultRubyStyle(style),
      textAlign: textAlign,
      textDirection: textDirection,
      softWrap: softWrap,
      overflow: overflow,
      maxLines: maxLines,
      spacing: spacing,  // 한자와 후리가나 사이 간격 조절
    );
  }
  
  /// 기본 ruby 스타일 생성
  TextStyle _getDefaultRubyStyle(TextStyle? baseStyle) {
    final baseFontSize = baseStyle?.fontSize ?? 14.0;
    return TextStyle(
      fontSize: baseFontSize * 0.55, // 후리가나는 본문의 55% 크기
      color: baseStyle?.color?.withValues(alpha: 0.8), // 약간 연한 색상
      fontWeight: FontWeight.normal,
    );
  }
}

/// 간단한 정적 메서드를 제공하는 헬퍼 클래스
class FuriganaHelper {
  /// 후리가나 텍스트에서 일반 텍스트만 추출
  static String extractPlainText(String furiganaText) {
    if (!furiganaText.contains('[')) {
      return furiganaText;
    }
    final data = FuriganaParser.parse(furiganaText);
    return FuriganaParser.toPlainText(data);
  }
  
  /// 후리가나 텍스트에서 읽기만 추출
  static String extractReading(String furiganaText) {
    if (!furiganaText.contains('[')) {
      return furiganaText;
    }
    final data = FuriganaParser.parse(furiganaText);
    return FuriganaParser.toFuriganaText(data);
  }
}