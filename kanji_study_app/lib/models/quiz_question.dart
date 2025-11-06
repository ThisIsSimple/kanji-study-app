class QuizQuestion {
  final int id;
  final int quizSetId;
  final String questionType; // 'meaning', 'reading', 'kanji', 'sentence'
  final String questionText;
  final String correctAnswer;
  final List<String> options;
  final String? explanation;
  final int points;
  final int orderIndex;

  const QuizQuestion({
    required this.id,
    required this.quizSetId,
    required this.questionType,
    required this.questionText,
    required this.correctAnswer,
    required this.options,
    this.explanation,
    this.points = 1,
    required this.orderIndex,
  });

  factory QuizQuestion.fromJson(Map<String, dynamic> json) {
    return QuizQuestion(
      id: json['id'] as int,
      quizSetId: json['quiz_set_id'] as int,
      questionType: json['question_type'] as String,
      questionText: json['question_text'] as String,
      correctAnswer: json['correct_answer'] as String,
      options: (json['options'] as List<dynamic>).cast<String>(),
      explanation: json['explanation'] as String?,
      points: json['points'] as int? ?? 1,
      orderIndex: json['order_index'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'quiz_set_id': quizSetId,
      'question_type': questionType,
      'question_text': questionText,
      'correct_answer': correctAnswer,
      'options': options,
      'explanation': explanation,
      'points': points,
      'order_index': orderIndex,
    };
  }

  // For creating new questions
  Map<String, dynamic> toJsonForCreate() {
    return {
      'quiz_set_id': quizSetId,
      'question_type': questionType,
      'question_text': questionText,
      'correct_answer': correctAnswer,
      'options': options,
      'explanation': explanation,
      'points': points,
      'order_index': orderIndex,
    };
  }

  bool checkAnswer(String userAnswer) {
    return userAnswer.trim().toLowerCase() ==
        correctAnswer.trim().toLowerCase();
  }
}
