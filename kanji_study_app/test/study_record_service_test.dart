import 'package:flutter_test/flutter_test.dart';
import 'package:konnakanji/models/study_record_model.dart';
import 'package:konnakanji/services/study_record_service.dart';

void main() {
  test('StudyRecord preserves recordClientId through JSON helpers', () {
    final record = StudyRecord(
      id: 1,
      userId: 'user-1',
      type: StudyType.word,
      targetId: 10,
      status: StudyStatus.completed,
      notes: 'note',
      recordClientId: 'record-1',
      createdAt: DateTime.utc(2026, 6, 1, 10),
    );

    final restored = StudyRecord.fromJson(record.toJson());
    final createJson = record.toJsonForCreate();

    expect(restored.recordClientId, 'record-1');
    expect(createJson['record_client_id'], 'record-1');
  });

  test('mergeStudyRecordsForTest deduplicates by recordClientId', () {
    final local = StudyRecord(
      userId: 'user-1',
      type: StudyType.word,
      targetId: 10,
      status: StudyStatus.completed,
      recordClientId: 'record-1',
      createdAt: DateTime.utc(2026, 6, 1, 10),
    );
    final server = local.copyWith(id: 100);

    final merged = StudyRecordService.mergeStudyRecordsForTest(
      [local],
      [server],
    );

    expect(merged, hasLength(1));
    expect(merged.single.recordClientId, 'record-1');
  });

  test('recordMergeKeyForTest falls back for legacy records', () {
    final first = StudyRecord(
      userId: 'user-1',
      type: StudyType.word,
      targetId: 10,
      status: StudyStatus.completed,
      createdAt: DateTime.utc(2026, 6, 1, 10),
    );
    final second = first.copyWith(id: 2);

    expect(
      StudyRecordService.recordMergeKeyForTest(first),
      StudyRecordService.recordMergeKeyForTest(second),
    );
    expect(
      StudyRecordService.recordMergeKeyForTest(first),
      'user-1|word|10|completed|2026-06-01T10:00:00.000Z',
    );
  });

  test('existingRecordClientIdOrNullForTest treats legacy ids as missing', () {
    expect(
      StudyRecordService.existingRecordClientIdOrNullForTest('record-1'),
      'record-1',
    );
    expect(
      StudyRecordService.existingRecordClientIdOrNullForTest(null),
      isNull,
    );
    expect(StudyRecordService.existingRecordClientIdOrNullForTest(''), isNull);
  });

  test('recordClientIdForSyncForTest reuses existing id or creates one', () {
    var generatedCount = 0;

    String createId() {
      generatedCount += 1;
      return 'generated-$generatedCount';
    }

    expect(
      StudyRecordService.recordClientIdForSyncForTest(
        'record-1',
        createRecordClientId: createId,
      ),
      'record-1',
    );
    expect(generatedCount, 0);

    expect(
      StudyRecordService.recordClientIdForSyncForTest(
        null,
        createRecordClientId: createId,
      ),
      'generated-1',
    );
    expect(
      StudyRecordService.recordClientIdForSyncForTest(
        '',
        createRecordClientId: createId,
      ),
      'generated-2',
    );
  });

  test(
    'filterRecordsByDateRange keeps local records inside inclusive range',
    () {
      final records = [
        StudyRecord(
          userId: 'user-1',
          type: StudyType.word,
          targetId: 10,
          status: StudyStatus.completed,
          createdAt: DateTime(2026, 5, 25, 23, 59),
        ),
        StudyRecord(
          userId: 'user-1',
          type: StudyType.word,
          targetId: 11,
          status: StudyStatus.forgot,
          createdAt: DateTime(2026, 5, 26, 9),
        ),
        StudyRecord(
          userId: 'user-1',
          type: StudyType.kanji,
          targetId: 12,
          status: StudyStatus.completed,
          createdAt: DateTime(2026, 5, 26, 18),
        ),
        StudyRecord(
          userId: 'user-1',
          type: StudyType.word,
          targetId: 13,
          status: StudyStatus.completed,
          createdAt: DateTime(2026, 5, 27),
        ),
      ];

      final filtered = StudyRecordService.filterRecordsByDateRange(
        records,
        startDate: DateTime(2026, 5, 26),
        endDate: DateTime(2026, 5, 26, 23, 59, 59),
      );

      expect(filtered.map((record) => record.targetId), [11, 12]);
      expect(filtered.map((record) => record.type), [
        StudyType.word,
        StudyType.kanji,
      ]);
    },
  );
}
