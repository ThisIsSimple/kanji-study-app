import 'package:flutter_test/flutter_test.dart';
import 'package:konnakanji/models/study_record_model.dart';
import 'package:konnakanji/services/analytics_service.dart';

void main() {
  test('buildDailyStats groups records by local day consistently', () {
    final records = [
      StudyRecord(
        type: StudyType.word,
        targetId: 10,
        status: StudyStatus.completed,
        createdAt: DateTime(2026, 2, 1, 8),
      ),
      StudyRecord(
        type: StudyType.word,
        targetId: 10,
        status: StudyStatus.forgot,
        createdAt: DateTime(2026, 2, 1, 9),
      ),
      StudyRecord(
        type: StudyType.kanji,
        targetId: 2,
        status: StudyStatus.completed,
        createdAt: DateTime(2026, 2, 2, 10),
      ),
    ];

    final stats = AnalyticsService.buildDailyStats(
      records,
      startDate: DateTime(2026, 2, 1),
      endDate: DateTime(2026, 2, 3),
    );

    expect(stats, hasLength(3));
    expect(stats[0].wordsStudied, 1);
    expect(stats[0].kanjiStudied, 0);
    expect(stats[0].totalCompleted, 1);
    expect(stats[0].totalForgot, 1);
    expect(stats[1].kanjiStudied, 1);
    expect(stats[1].wordsStudied, 0);
    expect(stats[2].totalStudied, 0);
  });
}
