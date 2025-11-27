/// AI로 생성된 퀴즈 유형
enum AiQuizType {
  jpToKr('jp_to_kr', '일→한', '일본어 단어의 한국어 뜻 맞추기'),
  krToJp('kr_to_jp', '한→일', '한국어 뜻에 해당하는 일본어 단어 맞추기'),
  kanjiReading('kanji_reading', '한자읽기', '한자의 후리가나 맞추기'),
  fillBlank('fill_blank', '빈칸채우기', '문장의 빈칸에 들어갈 단어 맞추기');

  final String value;
  final String displayName;
  final String description;

  const AiQuizType(this.value, this.displayName, this.description);

  static AiQuizType fromValue(String value) {
    return AiQuizType.values.firstWhere(
      (type) => type.value == value,
      orElse: () => AiQuizType.jpToKr,
    );
  }
}

/// AI로 생성된 퀴즈 모델
class AiQuiz {
  final int id;
  final String userId;
  final AiQuizType quizType;
  final String title;
  final int? jlptLevel;
  final int questionCount;
  final DateTime createdAt;
  final List<AiQuizQuestion>? questions;

  const AiQuiz({
    required this.id,
    required this.userId,
    required this.quizType,
    required this.title,
    this.jlptLevel,
    required this.questionCount,
    required this.createdAt,
    this.questions,
  });

  factory AiQuiz.fromJson(Map<String, dynamic> json) {
    return AiQuiz(
      id: json['id'] as int,
      userId: json['user_id'] as String,
      quizType: AiQuizType.fromValue(json['quiz_type'] as String),
      title: json['title'] as String,
      jlptLevel: json['jlpt_level'] as int?,
      questionCount: json['question_count'] as int,
      createdAt: DateTime.parse(json['created_at'] as String),
      questions: json['ai_quiz_questions'] != null
          ? (json['ai_quiz_questions'] as List)
              .map((q) => AiQuizQuestion.fromJson(q as Map<String, dynamic>))
              .toList()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'quiz_type': quizType.value,
      'title': title,
      'jlpt_level': jlptLevel,
      'question_count': questionCount,
      'created_at': createdAt.toIso8601String(),
    };
  }

  Map<String, dynamic> toJsonForCreate() {
    return {
      'user_id': userId,
      'quiz_type': quizType.value,
      'title': title,
      'jlpt_level': jlptLevel,
      'question_count': questionCount,
    };
  }

  /// 퀴즈 타이틀 자동 생성
  static String generateTitle(AiQuizType type, int? jlptLevel) {
    final levelStr = jlptLevel != null ? 'N$jlptLevel ' : '';
    return '$levelStr${type.displayName} 퀴즈';
  }
}

/// AI 퀴즈 문제 모델
class AiQuizQuestion {
  final int id;
  final int quizId;
  final int questionIndex;
  final String question;
  final List<String> options;
  final String correctAnswer;
  final String? explanation;
  final int? sourceId;

  const AiQuizQuestion({
    required this.id,
    required this.quizId,
    required this.questionIndex,
    required this.question,
    required this.options,
    required this.correctAnswer,
    this.explanation,
    this.sourceId,
  });

  factory AiQuizQuestion.fromJson(Map<String, dynamic> json) {
    return AiQuizQuestion(
      id: json['id'] as int,
      quizId: json['quiz_id'] as int,
      questionIndex: json['question_index'] as int,
      question: json['question'] as String,
      options: (json['options'] as List<dynamic>).cast<String>(),
      correctAnswer: json['correct_answer'] as String,
      explanation: json['explanation'] as String?,
      sourceId: json['source_id'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'quiz_id': quizId,
      'question_index': questionIndex,
      'question': question,
      'options': options,
      'correct_answer': correctAnswer,
      'explanation': explanation,
      'source_id': sourceId,
    };
  }

  Map<String, dynamic> toJsonForCreate() {
    return {
      'quiz_id': quizId,
      'question_index': questionIndex,
      'question': question,
      'options': options,
      'correct_answer': correctAnswer,
      'explanation': explanation,
      'source_id': sourceId,
    };
  }
}

