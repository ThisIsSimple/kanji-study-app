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
                (point) => StrokePoint(
                  x: point.x,
                  y: point.y,
                  t: point.timestamp,
                ),
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

    return extractKanjiCandidates(candidates.map((candidate) => candidate.text));
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

  void dispose() {
    _recognizer.close();
  }
}
