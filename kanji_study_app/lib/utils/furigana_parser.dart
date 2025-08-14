import 'package:ruby_text/ruby_text.dart';

/// Furigana 파서 유틸리티
/// 
/// 예시: "野菜[やさい]を蒸[む]すのは健康的[けんこうてき]です。"
/// → [RubyTextData('野菜', ruby: 'やさい'), RubyTextData('を'), RubyTextData('蒸', ruby: 'む'), ...]
class FuriganaParser {
  /// Furigana 형식의 텍스트를 RubyTextData 리스트로 파싱
  static List<RubyTextData> parse(String text) {
    final List<RubyTextData> result = [];
    
    int i = 0;
    while (i < text.length) {
      // 대괄호를 찾아서 그 앞의 한자와 대괄호 안의 후리가나를 추출
      final nextBracket = text.indexOf('[', i);
      
      if (nextBracket == -1) {
        // 더 이상 대괄호가 없으면 나머지 텍스트를 일반 텍스트로 처리
        if (i < text.length) {
          _parseNormalText(text.substring(i), result);
        }
        break;
      }
      
      // 대괄호 전까지의 텍스트 처리
      if (nextBracket > i) {
        final beforeBracket = text.substring(i, nextBracket);
        
        // 한자와 일반 텍스트를 구분
        final kanjiMatch = _extractLastKanji(beforeBracket);
        
        if (kanjiMatch != null) {
          // 한자 앞의 일반 텍스트가 있으면 먼저 추가
          if (kanjiMatch['before']!.isNotEmpty) {
            _parseNormalText(kanjiMatch['before']!, result);
          }
          
          // 대괄호 닫기 찾기
          final closeBracket = text.indexOf(']', nextBracket);
          if (closeBracket != -1) {
            final ruby = text.substring(nextBracket + 1, closeBracket);
            // 한자와 후리가나를 함께 추가
            result.add(RubyTextData(
              kanjiMatch['kanji']!,
              ruby: ruby,
            ));
            i = closeBracket + 1;
          } else {
            // 닫는 대괄호가 없으면 일반 텍스트로 처리
            _parseNormalText(beforeBracket, result);
            result.add(RubyTextData('['));
            i = nextBracket + 1;
          }
        } else {
          // 한자가 없으면 일반 텍스트로 처리
          _parseNormalText(beforeBracket, result);
          
          // 대괄호 처리
          final closeBracket = text.indexOf(']', nextBracket);
          if (closeBracket != -1) {
            // 대괄호와 그 내용을 일반 텍스트로 처리
            _parseNormalText(text.substring(nextBracket, closeBracket + 1), result);
            i = closeBracket + 1;
          } else {
            result.add(RubyTextData('['));
            i = nextBracket + 1;
          }
        }
      } else {
        // 대괄호가 텍스트 시작 부분에 있는 경우
        final closeBracket = text.indexOf(']', nextBracket);
        if (closeBracket != -1) {
          _parseNormalText(text.substring(nextBracket, closeBracket + 1), result);
          i = closeBracket + 1;
        } else {
          result.add(RubyTextData('['));
          i = nextBracket + 1;
        }
      }
    }
    
    return result;
  }
  
  /// 텍스트에서 마지막 한자 부분을 추출
  static Map<String, String>? _extractLastKanji(String text) {
    // 텍스트를 뒤에서부터 검사하여 연속된 한자를 찾음
    int kanjiEnd = text.length;
    int kanjiStart = kanjiEnd;
    
    // 뒤에서부터 한자가 아닌 문자를 찾을 때까지 검사
    for (int i = text.length - 1; i >= 0; i--) {
      if (_isKanji(text[i])) {
        kanjiStart = i;
      } else {
        break;
      }
    }
    
    // 한자를 찾았으면
    if (kanjiStart < kanjiEnd) {
      return {
        'before': text.substring(0, kanjiStart),
        'kanji': text.substring(kanjiStart, kanjiEnd),
      };
    }
    
    return null;
  }
  
  /// 일반 텍스트를 파싱하여 RubyTextData 리스트에 추가
  static void _parseNormalText(String text, List<RubyTextData> result) {
    final buffer = StringBuffer();
    
    for (int i = 0; i < text.length; i++) {
      final char = text[i];
      
      // 한자, 히라가나, 카타카나, 기타 문자를 구분
      if (_isKanji(char)) {
        // 이전에 쌓인 버퍼가 있으면 먼저 추가
        if (buffer.isNotEmpty) {
          result.add(RubyTextData(buffer.toString()));
          buffer.clear();
        }
        // 한자는 개별적으로 추가 (후리가나 없음)
        result.add(RubyTextData(char));
      } else {
        // 한자가 아닌 경우 버퍼에 추가
        buffer.write(char);
      }
    }
    
    // 남은 버퍼 내용 추가
    if (buffer.isNotEmpty) {
      result.add(RubyTextData(buffer.toString()));
    }
  }
  
  /// 문자가 한자인지 확인
  static bool _isKanji(String char) {
    final code = char.codeUnitAt(0);
    // CJK Unified Ideographs 범위
    return (code >= 0x4E00 && code <= 0x9FFF) ||
           (code >= 0x3400 && code <= 0x4DBF);
  }
  
  /// 파싱된 결과를 일반 텍스트로 변환 (후리가나 제거)
  static String toPlainText(List<RubyTextData> data) {
    return data.map((item) => item.text).join();
  }
  
  /// 파싱된 결과를 후리가나 텍스트로 변환 (한자 대신 후리가나 사용)
  static String toFuriganaText(List<RubyTextData> data) {
    return data.map((item) => item.ruby ?? item.text).join();
  }
}