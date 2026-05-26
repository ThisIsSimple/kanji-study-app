import 'package:flutter_test/flutter_test.dart';
import 'package:konnakanji/models/study_record_model.dart';
import 'package:konnakanji/services/study_record_service.dart';

void main() {
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
