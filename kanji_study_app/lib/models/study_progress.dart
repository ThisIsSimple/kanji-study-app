import 'study_record_model.dart';

class StudyItemProgress {
  final StudyType type;
  final int targetId;
  final StudyStatus? lastStatus;
  final int attemptCount;
  final int completedCount;
  final int forgotCount;
  final DateTime? lastStudiedAt;

  const StudyItemProgress({
    required this.type,
    required this.targetId,
    required this.lastStatus,
    required this.attemptCount,
    required this.completedCount,
    required this.forgotCount,
    required this.lastStudiedAt,
  });

  bool get isMastered =>
      completedCount >= 5 || lastStatus == StudyStatus.mastered;

  StudyItemProgress copyWithRecord(StudyRecord record) {
    final completed =
        record.status == StudyStatus.completed ||
            record.status == StudyStatus.mastered
        ? completedCount + 1
        : completedCount;
    final forgot = record.status == StudyStatus.forgot
        ? forgotCount + 1
        : forgotCount;

    return StudyItemProgress(
      type: type,
      targetId: targetId,
      lastStatus: record.status,
      attemptCount: attemptCount + 1,
      completedCount: completed,
      forgotCount: forgot,
      lastStudiedAt: record.createdAt ?? lastStudiedAt,
    );
  }

  static StudyItemProgress empty(StudyType type, int targetId) {
    return StudyItemProgress(
      type: type,
      targetId: targetId,
      lastStatus: null,
      attemptCount: 0,
      completedCount: 0,
      forgotCount: 0,
      lastStudiedAt: null,
    );
  }
}

class StudyProgressSummary {
  final StudyType type;
  final int totalItems;
  final int studiedItems;
  final int masteredItems;
  final int totalAttempts;

  const StudyProgressSummary({
    required this.type,
    required this.totalItems,
    required this.studiedItems,
    required this.masteredItems,
    required this.totalAttempts,
  });
}

Map<String, StudyItemProgress> buildProgressIndex(
  Iterable<StudyRecord> records,
) {
  final sortedRecords = records.toList()
    ..sort((left, right) {
      final leftTime = left.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      final rightTime =
          right.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      return leftTime.compareTo(rightTime);
    });

  final index = <String, StudyItemProgress>{};
  for (final record in sortedRecords) {
    final key = '${record.type.value}_${record.targetId}';
    final current =
        index[key] ?? StudyItemProgress.empty(record.type, record.targetId);
    index[key] = current.copyWithRecord(record);
  }
  return index;
}

StudyProgressSummary buildProgressSummary(
  StudyType type,
  Iterable<StudyItemProgress> progressItems,
) {
  final filtered = progressItems.where((item) => item.type == type).toList();
  return StudyProgressSummary(
    type: type,
    totalItems: filtered.length,
    studiedItems: filtered.where((item) => item.attemptCount > 0).length,
    masteredItems: filtered.where((item) => item.isMastered).length,
    totalAttempts: filtered.fold<int>(
      0,
      (sum, item) => sum + item.attemptCount,
    ),
  );
}
