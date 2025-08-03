class UserProgress {
  final String kanjiCharacter;
  final DateTime lastStudied;
  final int studyCount;
  final bool mastered;

  const UserProgress({
    required this.kanjiCharacter,
    required this.lastStudied,
    required this.studyCount,
    required this.mastered,
  });

  factory UserProgress.fromJson(Map<String, dynamic> json) {
    return UserProgress(
      kanjiCharacter: json['kanjiCharacter'] as String,
      lastStudied: DateTime.parse(json['lastStudied'] as String),
      studyCount: json['studyCount'] as int,
      mastered: json['mastered'] as bool,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'kanjiCharacter': kanjiCharacter,
      'lastStudied': lastStudied.toIso8601String(),
      'studyCount': studyCount,
      'mastered': mastered,
    };
  }

  UserProgress copyWith({
    String? kanjiCharacter,
    DateTime? lastStudied,
    int? studyCount,
    bool? mastered,
  }) {
    return UserProgress(
      kanjiCharacter: kanjiCharacter ?? this.kanjiCharacter,
      lastStudied: lastStudied ?? this.lastStudied,
      studyCount: studyCount ?? this.studyCount,
      mastered: mastered ?? this.mastered,
    );
  }
}