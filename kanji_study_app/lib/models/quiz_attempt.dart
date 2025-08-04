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
      startedAt: DateTime.parse(json['started_at'] as String),
      completedAt: json['completed_at'] != null 
          ? DateTime.parse(json['completed_at'] as String)
          : null,
      score: json['score'] as int?,
      totalPoints: json['total_points'] as int?,
      timeTakenSeconds: json['time_taken_seconds'] as int?,
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
    return {
      'user_id': userId,
      'quiz_set_id': quizSetId,
    };
  }

  // For updating an attempt when completed
  Map<String, dynamic> toJsonForComplete({
    required int score,
    required int totalPoints,
    required int timeTakenSeconds,
  }) {
    return {
      'completed_at': DateTime.now().toIso8601String(),
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