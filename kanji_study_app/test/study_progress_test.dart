import 'package:flutter_test/flutter_test.dart';
import 'package:konnakanji/models/study_progress.dart';
import 'package:konnakanji/models/study_record_model.dart';

void main() {
  test('buildProgressIndex calculates attempts and mastered state', () {
    final records = [
      StudyRecord(
        type: StudyType.kanji,
        targetId: 1,
        status: StudyStatus.completed,
        createdAt: DateTime(2026, 1, 1, 9),
      ),
      StudyRecord(
        type: StudyType.kanji,
        targetId: 1,
        status: StudyStatus.forgot,
        createdAt: DateTime(2026, 1, 2, 9),
      ),
      StudyRecord(
        type: StudyType.kanji,
        targetId: 1,
        status: StudyStatus.completed,
        createdAt: DateTime(2026, 1, 3, 9),
      ),
      StudyRecord(
        type: StudyType.kanji,
        targetId: 1,
        status: StudyStatus.completed,
        createdAt: DateTime(2026, 1, 4, 9),
      ),
      StudyRecord(
        type: StudyType.kanji,
        targetId: 1,
        status: StudyStatus.mastered,
        createdAt: DateTime(2026, 1, 5, 9),
      ),
      StudyRecord(
        type: StudyType.word,
        targetId: 77,
        status: StudyStatus.completed,
        createdAt: DateTime(2026, 1, 2, 12),
      ),
    ];

    final index = buildProgressIndex(records);
    final kanji = index['kanji_1']!;
    final word = index['word_77']!;

    expect(kanji.attemptCount, 5);
    expect(kanji.completedCount, 4);
    expect(kanji.forgotCount, 1);
    expect(kanji.isMastered, isTrue);
    expect(kanji.lastStatus, StudyStatus.mastered);
    expect(word.attemptCount, 1);

    final summary = buildProgressSummary(StudyType.kanji, index.values);
    expect(summary.studiedItems, 1);
    expect(summary.masteredItems, 1);
    expect(summary.totalAttempts, 5);
  });
}
