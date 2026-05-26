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

  test('extractJapaneseTextCandidates keeps Japanese text candidates', () {
    final candidates =
        HandwritingRecognitionService.extractJapaneseTextCandidates([
          '日本',
          '勉強',
          'ありがとう',
          'カタカナ',
          '時々',
          ' コーヒー ',
        ]);

    expect(candidates, ['日本', '勉強', 'ありがとう', 'カタカナ', '時々', 'コーヒー']);
  });

  test('extractJapaneseTextCandidates removes non-Japanese and duplicates', () {
    final candidates =
        HandwritingRecognitionService.extractJapaneseTextCandidates([
          '',
          ' ',
          '日本',
          '日本',
          '日本1',
          'study',
          '勉強A',
          'カタカナ',
        ]);

    expect(candidates, ['日本', 'カタカナ']);
  });

  test('describeFailure explains known iOS simulator ML Kit issues', () {
    final message = HandwritingRecognitionService.describeFailure(
      "Building for 'iOS-simulator', but linking in object file "
      'MLImage.framework/MLImage[arm64] built for iOS',
    );

    expect(
      message,
      HandwritingRecognitionService.iosSimulatorLimitationMessage,
    );
  });

  test('describeFailure keeps unknown failures debuggable', () {
    final message = HandwritingRecognitionService.describeFailure(
      Exception('model download failed'),
    );

    expect(message, contains('model download failed'));
  });
}
