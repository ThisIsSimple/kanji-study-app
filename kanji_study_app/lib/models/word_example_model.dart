class WordExample {
  final String japanese;
  final String furigana;
  final String korean;
  final String? explanation;
  final String? source;
  final DateTime? createdAt;

  const WordExample({
    required this.japanese,
    required this.furigana,
    required this.korean,
    this.explanation,
    this.source,
    this.createdAt,
  });

  factory WordExample.fromJson(Map<String, dynamic> json) {
    return WordExample(
      japanese: json['japanese'] as String,
      furigana: json['furigana'] as String? ?? json['hiragana'] as String? ?? json['hurigana'] as String? ?? '', // 호환성을 위해 다양한 이름 체크
      korean: json['korean'] as String,
      explanation: json['explanation'] as String?,
      source: json['source'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'japanese': japanese,
      'furigana': furigana,
      'korean': korean,
      'explanation': explanation,
      'source': source,
      'created_at': createdAt?.toIso8601String(),
    };
  }
}