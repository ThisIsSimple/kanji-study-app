class LearningGoal {
  final int dailyGoal;
  final int targetJlptLevel;

  const LearningGoal({required this.dailyGoal, required this.targetJlptLevel});

  bool get isValid =>
      dailyGoal >= 1 &&
      dailyGoal <= 100 &&
      targetJlptLevel >= 1 &&
      targetJlptLevel <= 5;

  factory LearningGoal.fromJson(Map<String, dynamic> json) {
    return LearningGoal(
      dailyGoal: json['daily_goal'] as int,
      targetJlptLevel: json['target_jlpt_level'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {'daily_goal': dailyGoal, 'target_jlpt_level': targetJlptLevel};
  }
}
