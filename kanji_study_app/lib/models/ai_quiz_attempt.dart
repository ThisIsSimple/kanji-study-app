import 'ai_quiz.dart';

/// AI 퀴즈 응시 기록 모델
class AiQuizAttempt {
  final int id;
  final int quizId;
  final String userId;
  final int? score;
  final int? correctCount;
  final DateTime startedAt;
  final DateTime? completedAt;
  final AiQuiz? quiz;
  final List<AiQuizAnswer>? answers;

  const AiQuizAttempt({
    required this.id,
    required this.quizId,
    required this.userId,
    this.score,
    this.correctCount,
    required this.startedAt,
    this.completedAt,
    this.quiz,
    this.answers,
  });

  bool get isCompleted => completedAt != null;

  Duration? get duration {
    if (completedAt == null) return null;
    return completedAt!.difference(startedAt);
  }

  double get accuracyPercentage {
    if (quiz == null || correctCount == null) return 0;
    return (correctCount! / quiz!.questionCount * 100);
  }

  factory AiQuizAttempt.fromJson(Map<String, dynamic> json) {
    return AiQuizAttempt(
      id: json['id'] as int,
      quizId: json['quiz_id'] as int,
      userId: json['user_id'] as String,
      score: json['score'] as int?,
      correctCount: json['correct_count'] as int?,
      // DateTime.parse()는 시간대 정보(Z, +00:00 등)가 있으면 UTC로 파싱
      // 시간대 없으면 로컬로 파싱하여 내부 UTC timestamp로 변환
      // completed_at은 UTC로 저장되므로 올바르게 처리됨
      startedAt: DateTime.parse(json['started_at'] as String),
      completedAt: json['completed_at'] != null
          ? DateTime.parse(json['completed_at'] as String)
          : null,
      quiz: json['ai_quizzes'] != null
          ? AiQuiz.fromJson(json['ai_quizzes'] as Map<String, dynamic>)
          : null,
      answers: json['ai_quiz_answers'] != null
          ? (json['ai_quiz_answers'] as List)
                .map((a) => AiQuizAnswer.fromJson(a as Map<String, dynamic>))
                .toList()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'quiz_id': quizId,
      'user_id': userId,
      'score': score,
      'correct_count': correctCount,
      'started_at': startedAt.toIso8601String(),
      'completed_at': completedAt?.toIso8601String(),
    };
  }

  Map<String, dynamic> toJsonForCreate() {
    return {'quiz_id': quizId, 'user_id': userId};
  }

  AiQuizAttempt copyWith({
    int? id,
    int? quizId,
    String? userId,
    int? score,
    int? correctCount,
    DateTime? startedAt,
    DateTime? completedAt,
    AiQuiz? quiz,
    List<AiQuizAnswer>? answers,
  }) {
    return AiQuizAttempt(
      id: id ?? this.id,
      quizId: quizId ?? this.quizId,
      userId: userId ?? this.userId,
      score: score ?? this.score,
      correctCount: correctCount ?? this.correctCount,
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
      quiz: quiz ?? this.quiz,
      answers: answers ?? this.answers,
    );
  }
}

/// AI 퀴즈 응시 답변 모델
class AiQuizAnswer {
  final int id;
  final int attemptId;
  final int questionId;
  final String? userAnswer;
  final bool isCorrect;

  const AiQuizAnswer({
    required this.id,
    required this.attemptId,
    required this.questionId,
    this.userAnswer,
    required this.isCorrect,
  });

  factory AiQuizAnswer.fromJson(Map<String, dynamic> json) {
    return AiQuizAnswer(
      id: json['id'] as int,
      attemptId: json['attempt_id'] as int,
      questionId: json['question_id'] as int,
      userAnswer: json['user_answer'] as String?,
      isCorrect: json['is_correct'] as bool,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'attempt_id': attemptId,
      'question_id': questionId,
      'user_answer': userAnswer,
      'is_correct': isCorrect,
    };
  }

  Map<String, dynamic> toJsonForCreate() {
    return {
      'attempt_id': attemptId,
      'question_id': questionId,
      'user_answer': userAnswer,
      'is_correct': isCorrect,
    };
  }
}
