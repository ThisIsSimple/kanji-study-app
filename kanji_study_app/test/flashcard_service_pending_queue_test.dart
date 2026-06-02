import 'package:flutter_test/flutter_test.dart';
import 'package:konnakanji/models/flashcard_session_model.dart';
import 'package:konnakanji/services/flashcard_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late FlashcardService service;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    service = FlashcardService.instance;
  });

  test('replaces pending session with same sessionClientId', () async {
    await service.enqueuePendingCompletedSessionForTest(
      'user-1',
      _session('session-1', [1]),
    );
    await service.enqueuePendingCompletedSessionForTest(
      'user-1',
      _session('session-1', [2, 3]),
    );

    final pending = await service.loadPendingCompletedSessionsForTest();

    expect(pending, hasLength(1));
    expect(_sessionJson(pending.single)['sessionClientId'], 'session-1');
    expect(_sessionJson(pending.single)['itemIds'], [2, 3]);
  });

  test('removes only synced sessions for current user', () async {
    await service.enqueuePendingCompletedSessionForTest(
      'user-1',
      _session('session-1', [1]),
    );
    await service.enqueuePendingCompletedSessionForTest(
      'user-1',
      _session('session-2', [2]),
    );
    await service.enqueuePendingCompletedSessionForTest(
      'user-2',
      _session('session-3', [3]),
    );

    await service.removeSyncedPendingCompletedSessionsForTest('user-1', {
      'session-1',
      'session-3',
    });

    final pending = await service.loadPendingCompletedSessionsForTest();
    final ids = pending.map((item) => _sessionJson(item)['sessionClientId']);

    expect(ids, ['session-2', 'session-3']);
  });

  test('preserves sessions enqueued after sync snapshot', () async {
    await service.enqueuePendingCompletedSessionForTest(
      'user-1',
      _session('session-1', [1]),
    );
    final syncSnapshot = await service.loadPendingCompletedSessionsForTest();

    await service.enqueuePendingCompletedSessionForTest(
      'user-1',
      _session('session-2', [2]),
    );
    await service.removeSyncedPendingCompletedSessionsForTest('user-1', {
      _sessionJson(syncSnapshot.single)['sessionClientId'] as String,
    });

    final pending = await service.loadPendingCompletedSessionsForTest();

    expect(pending, hasLength(1));
    expect(_sessionJson(pending.single)['sessionClientId'], 'session-2');
  });

  test('serializes concurrent pending queue enqueues', () async {
    await Future.wait(
      List.generate(
        10,
        (index) => service.enqueuePendingCompletedSessionForTest(
          'user-1',
          _session('session-$index', [index]),
        ),
      ),
    );

    final pending = await service.loadPendingCompletedSessionsForTest();
    final ids = pending.map((item) => _sessionJson(item)['sessionClientId']);

    expect(pending, hasLength(10));
    expect(ids.toSet(), {
      'session-0',
      'session-1',
      'session-2',
      'session-3',
      'session-4',
      'session-5',
      'session-6',
      'session-7',
      'session-8',
      'session-9',
    });
  });
}

FlashcardSession _session(String sessionClientId, List<int> itemIds) {
  final startTime = DateTime(2026, 6, 1, 10);
  return FlashcardSession(
    sessionClientId: sessionClientId,
    itemType: 'word',
    itemIds: itemIds,
    currentIndex: itemIds.length,
    results: itemIds
        .map(
          (itemId) => FlashcardResult(
            itemType: 'word',
            itemId: itemId,
            isCorrect: true,
            timestamp: startTime.add(Duration(minutes: itemId)),
          ),
        )
        .toList(),
    startTime: startTime,
    endTime: startTime.add(Duration(minutes: itemIds.length)),
  );
}

Map<String, dynamic> _sessionJson(Map<String, dynamic> pending) {
  return pending['session'] as Map<String, dynamic>;
}
