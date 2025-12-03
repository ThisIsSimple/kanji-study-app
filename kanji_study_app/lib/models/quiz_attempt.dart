class QuizAttempt {
  final int id;
  final String userId;
  final int quizSetId;
  final DateTime startedAt;
  final DateTime? completedAt;
  final int? score;
  final int? totalPoints;
  final int? timeTakenSeconds;

  const QuizAttempt({
    required this.id,
    required this.userId,
    required this.quizSetId,
    required this.startedAt,
    this.completedAt,
    this.score,
    this.totalPoints,
    this.timeTakenSeconds,
  });

  factory QuizAttempt.fromJson(Map<String, dynamic> json) {
    return QuizAttempt(
      id: json['id'] as int,
      userId: json['user_id'] as String,
      quizSetId: json['quiz_set_id'] as int,
      // Supabase에서 반환하는 시간은 UTC이므로 일관되게 UTC로 파싱
      startedAt: _parseUtcDateTime(json['started_at'] as String),
      completedAt: json['completed_at'] != null
          ? _parseUtcDateTime(json['completed_at'] as String)
          : null,
      score: json['score'] as int?,
      totalPoints: json['total_points'] as int?,
      timeTakenSeconds: json['time_taken_seconds'] as int?,
    );
  }

  /// UTC DateTime 파싱 헬퍼
  /// Supabase에서 반환하는 시간 문자열을 일관되게 UTC로 파싱
  static DateTime _parseUtcDateTime(String dateString) {
    final parsed = DateTime.parse(dateString);
    // 이미 UTC이거나 시간대 정보가 포함된 경우 그대로 반환
    if (parsed.isUtc) {
      return parsed;
    }
    // 시간대 정보 없이 파싱된 경우 (로컬로 해석됨)
    // Supabase는 UTC를 반환하므로 UTC로 재해석
    return DateTime.utc(
      parsed.year,
      parsed.month,
      parsed.day,
      parsed.hour,
      parsed.minute,
      parsed.second,
      parsed.millisecond,
      parsed.microsecond,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'quiz_set_id': quizSetId,
      'started_at': startedAt.toIso8601String(),
      'completed_at': completedAt?.toIso8601String(),
      'score': score,
      'total_points': totalPoints,
      'time_taken_seconds': timeTakenSeconds,
    };
  }

  // For creating new attempts
  Map<String, dynamic> toJsonForCreate() {
    return {'user_id': userId, 'quiz_set_id': quizSetId};
  }

  // For updating an attempt when completed
  Map<String, dynamic> toJsonForComplete({
    required int score,
    required int totalPoints,
    required int timeTakenSeconds,
  }) {
    return {
      // UTC로 저장하여 started_at과 일관성 유지
      'completed_at': DateTime.now().toUtc().toIso8601String(),
      'score': score,
      'total_points': totalPoints,
      'time_taken_seconds': timeTakenSeconds,
    };
  }

  double? get scorePercentage {
    if (score != null && totalPoints != null && totalPoints! > 0) {
      return (score! / totalPoints!) * 100;
    }
    return null;
  }

  bool get isCompleted => completedAt != null;
}
