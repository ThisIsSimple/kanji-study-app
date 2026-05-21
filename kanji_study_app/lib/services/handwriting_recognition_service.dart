import 'dart:ui';

import 'package:google_mlkit_digital_ink_recognition/google_mlkit_digital_ink_recognition.dart';

class HandwritingStrokePointData {
  final double x;
  final double y;
  final int timestamp;

  const HandwritingStrokePointData({
    required this.x,
    required this.y,
    required this.timestamp,
  });
}

class HandwritingStrokeData {
  final List<HandwritingStrokePointData> points;

  const HandwritingStrokeData({required this.points});
}

class HandwritingRecognitionService {
  static const String japaneseLanguageCode = 'ja';
  static const String iosSimulatorLimitationMessage =
      'iOS 시뮬레이터에서는 ML Kit 필기 인식이 제한될 수 있습니다. '
      'iPhone/iPad 실기기 또는 TestFlight에서 필기 인식을 검증해주세요.';

  static final HandwritingRecognitionService instance =
      HandwritingRecognitionService._internal();

  HandwritingRecognitionService._internal();

  final DigitalInkRecognizerModelManager _modelManager =
      DigitalInkRecognizerModelManager();
  late final DigitalInkRecognizer _recognizer = DigitalInkRecognizer(
    languageCode: japaneseLanguageCode,
  );

  Future<bool> isJapaneseModelDownloaded() {
    return _modelManager.isModelDownloaded(japaneseLanguageCode);
  }

  Future<bool> downloadJapaneseModel() {
    return _modelManager.downloadModel(japaneseLanguageCode);
  }

  Future<List<String>> recognizeSingleKanji({
    required List<HandwritingStrokeData> strokes,
    required Size writingArea,
  }) async {
    final meaningfulStrokes = strokes
        .where((stroke) => stroke.points.length >= 2)
        .toList();

    if (meaningfulStrokes.isEmpty || writingArea.isEmpty) {
      return const [];
    }

    final ink = Ink()
      ..strokes = meaningfulStrokes.map((stroke) {
        final digitalStroke = Stroke()
          ..points = stroke.points
              .map(
                (point) =>
                    StrokePoint(x: point.x, y: point.y, t: point.timestamp),
              )
              .toList();
        return digitalStroke;
      }).toList();

    final candidates = await _recognizer.recognize(
      ink,
      context: DigitalInkRecognitionContext(
        writingArea: WritingArea(
          width: writingArea.width,
          height: writingArea.height,
        ),
      ),
    );

    return extractKanjiCandidates(
      candidates.map((candidate) => candidate.text),
    );
  }

  static List<String> extractKanjiCandidates(Iterable<String> candidates) {
    final seen = <String>{};
    final result = <String>[];

    for (final rawCandidate in candidates) {
      final candidate = rawCandidate.trim();
      if (candidate.isEmpty) continue;
      if (candidate.runes.length != 1) continue;
      if (!_isKanji(candidate)) continue;
      if (seen.add(candidate)) {
        result.add(candidate);
      }
    }

    return result;
  }

  static bool _isKanji(String candidate) {
    final rune = candidate.runes.first;

    return (rune >= 0x3400 && rune <= 0x4DBF) ||
        (rune >= 0x4E00 && rune <= 0x9FFF) ||
        (rune >= 0xF900 && rune <= 0xFAFF);
  }

  static String describeFailure(Object error) {
    if (isLikelyIosSimulatorMlKitIssue(error)) {
      return iosSimulatorLimitationMessage;
    }

    return '필기 인식에 실패했습니다: $error';
  }

  static bool isLikelyIosSimulatorMlKitIssue(Object error) {
    final message = error.toString().toLowerCase();
    final mentionsSimulator =
        message.contains('simulator') ||
        message.contains('iphonesimulator') ||
        message.contains('iOS-simulator'.toLowerCase());
    final mentionsMlKit =
        message.contains('mlkit') ||
        message.contains('mlimage') ||
        message.contains('googlemlkit') ||
        message.contains('digitalink');
    final mentionsArchitecture =
        message.contains('arm64') ||
        message.contains('architecture') ||
        message.contains('built for ios') ||
        message.contains('linker command failed');

    return mentionsSimulator && mentionsMlKit && mentionsArchitecture;
  }

  void dispose() {
    _recognizer.close();
  }
}
