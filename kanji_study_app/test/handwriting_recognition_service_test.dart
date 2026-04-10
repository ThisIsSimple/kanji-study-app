import 'package:flutter_test/flutter_test.dart';
import 'package:konnakanji/services/handwriting_recognition_service.dart';

void main() {
  test('extractKanjiCandidates keeps unique single kanji only', () {
    final candidates = HandwritingRecognitionService.extractKanjiCandidates([
      '日',
      '日本',
      ' 日 ',
      'に',
      '',
      '本',
      'A',
      '本',
    ]);

    expect(candidates, ['日', '本']);
  });
}
