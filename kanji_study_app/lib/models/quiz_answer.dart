class QuizAnswer {
  final int id;
  final int attemptId;
  final int questionId;
  final String? userAnswer;
  final bool isCorrect;
  final int? timeTakenSeconds;
  final DateTime answeredAt;

  const QuizAnswer({
    required this.id,
    required this.attemptId,
    required this.questionId,
    this.userAnswer,
    required this.isCorrect,
    this.timeTakenSeconds,
    required this.answeredAt,
  });

  factory QuizAnswer.fromJson(Map<String, dynamic> json) {
    return QuizAnswer(
      id: json['id'] as int,
      attemptId: json['attempt_id'] as int,
      questionId: json['question_id'] as int,
      userAnswer: json['user_answer'] as String?,
      isCorrect: json['is_correct'] as bool,
      timeTakenSeconds: json['time_taken_seconds'] as int?,
      answeredAt: DateTime.parse(json['answered_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'attempt_id': attemptId,
      'question_id': questionId,
      'user_answer': userAnswer,
      'is_correct': isCorrect,
      'time_taken_seconds': timeTakenSeconds,
      'answered_at': answeredAt.toIso8601String(),
    };
  }

  // For creating new answers
  Map<String, dynamic> toJsonForCreate() {
    return {
      'attempt_id': attemptId,
      'question_id': questionId,
      'user_answer': userAnswer,
      'is_correct': isCorrect,
      'time_taken_seconds': timeTakenSeconds,
    };
  }
}
