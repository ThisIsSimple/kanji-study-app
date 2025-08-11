class WordExample {
  final String japanese;
  final String hiragana;
  final String korean;
  final String? explanation;
  final String? source;
  final DateTime? createdAt;

  const WordExample({
    required this.japanese,
    required this.hiragana,
    required this.korean,
    this.explanation,
    this.source,
    this.createdAt,
  });

  factory WordExample.fromJson(Map<String, dynamic> json) {
    return WordExample(
      japanese: json['japanese'] as String,
      hiragana: json['hiragana'] as String,
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
      'hiragana': hiragana,
      'korean': korean,
      'explanation': explanation,
      'source': source,
      'created_at': createdAt?.toIso8601String(),
    };
  }
}