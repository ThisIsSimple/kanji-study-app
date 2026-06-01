import 'package:flutter_test/flutter_test.dart';
import 'package:konnakanji/models/favorite_crdt_state.dart';

void main() {
  FavoriteCrdtState state({
    required bool isFavorite,
    required DateTime operationTimestamp,
    required String operationId,
    String deviceId = 'device-a',
  }) {
    return FavoriteCrdtState(
      userId: 'user-1',
      type: 'kanji',
      targetId: 10,
      isFavorite: isFavorite,
      operationTimestamp: operationTimestamp,
      operationId: operationId,
      deviceId: deviceId,
    );
  }

  test('newer remove wins over older add', () {
    final add = state(
      isFavorite: true,
      operationTimestamp: DateTime.utc(2026, 6, 1, 10),
      operationId: 'op-add',
      deviceId: 'device-a',
    );
    final remove = state(
      isFavorite: false,
      operationTimestamp: DateTime.utc(2026, 6, 1, 11),
      operationId: 'op-remove',
      deviceId: 'device-b',
    );

    final merged = mergeFavoriteStates(add, remove);

    expect(merged.isFavorite, isFalse);
    expect(merged.operationId, 'op-remove');
  });

  test('newer add wins over older remove', () {
    final remove = state(
      isFavorite: false,
      operationTimestamp: DateTime.utc(2026, 6, 1, 10),
      operationId: 'op-remove',
      deviceId: 'device-a',
    );
    final add = state(
      isFavorite: true,
      operationTimestamp: DateTime.utc(2026, 6, 1, 11),
      operationId: 'op-add',
      deviceId: 'device-b',
    );

    final merged = mergeFavoriteStates(remove, add);

    expect(merged.isFavorite, isTrue);
    expect(merged.operationId, 'op-add');
  });

  test('operation id breaks timestamp ties deterministically', () {
    final timestamp = DateTime.utc(2026, 6, 1, 10);
    final lowerOperationId = state(
      isFavorite: true,
      operationTimestamp: timestamp,
      operationId: 'op-a',
    );
    final higherOperationId = state(
      isFavorite: false,
      operationTimestamp: timestamp,
      operationId: 'op-b',
    );

    expect(
      mergeFavoriteStates(lowerOperationId, higherOperationId).operationId,
      'op-b',
    );
    expect(
      mergeFavoriteStates(higherOperationId, lowerOperationId).operationId,
      'op-b',
    );
  });
}
