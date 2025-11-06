class QuizSet {
  final int id;
  final String title;
  final String? description;
  final String createdBy;
  final int? difficultyLevel;
  final String? category;
  final List<int> kanjiIds;
  final bool isPublic;
  final DateTime createdAt;
  final DateTime updatedAt;

  const QuizSet({
    required this.id,
    required this.title,
    this.description,
    required this.createdBy,
    this.difficultyLevel,
    this.category,
    required this.kanjiIds,
    this.isPublic = false,
    required this.createdAt,
    required this.updatedAt,
  });

  factory QuizSet.fromJson(Map<String, dynamic> json) {
    return QuizSet(
      id: json['id'] as int,
      title: json['title'] as String,
      description: json['description'] as String?,
      createdBy: json['created_by'] as String,
      difficultyLevel: json['difficulty_level'] as int?,
      category: json['category'] as String?,
      kanjiIds: (json['kanji_ids'] as List<dynamic>).cast<int>(),
      isPublic: json['is_public'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'created_by': createdBy,
      'difficulty_level': difficultyLevel,
      'category': category,
      'kanji_ids': kanjiIds,
      'is_public': isPublic,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  // For creating new quiz sets
  Map<String, dynamic> toJsonForCreate() {
    return {
      'title': title,
      'description': description,
      'created_by': createdBy,
      'difficulty_level': difficultyLevel,
      'category': category,
      'kanji_ids': kanjiIds,
      'is_public': isPublic,
    };
  }
}
