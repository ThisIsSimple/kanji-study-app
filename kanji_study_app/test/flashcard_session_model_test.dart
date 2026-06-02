import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:konnakanji/models/flashcard_session_model.dart';

void main() {
  test('preserves sessionClientId through JSON and session updates', () {
    final session = FlashcardSession(
      sessionClientId: 'session-1',
      itemType: 'word',
      itemIds: const [10, 20],
      startTime: DateTime(2026, 6, 1, 10),
    );

    final withResult = session.copyWithResult(
      FlashcardResult(
        itemType: 'word',
        itemId: 10,
        isCorrect: true,
        timestamp: DateTime(2026, 6, 1, 10, 1),
      ),
    );
    final next = withResult.copyWithNextCard();
    final restored = FlashcardSession.fromJsonString(next.toJsonString());

    expect(restored.sessionClientId, 'session-1');
    expect(restored.results.single.itemId, 10);
    expect(restored.currentIndex, 1);
  });

  test('loads legacy session JSON without sessionClientId', () {
    final legacyJson = jsonEncode({
      'itemType': 'kanji',
      'itemIds': [1],
      'currentIndex': 0,
      'results': [],
      'startTime': DateTime(2026, 6, 1, 10).toIso8601String(),
      'endTime': null,
    });

    final session = FlashcardSession.fromJsonString(legacyJson);

    expect(session.sessionClientId, isNull);
    expect(session.itemType, 'kanji');
    expect(session.itemIds, [1]);
  });
}
