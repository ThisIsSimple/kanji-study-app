class KanjiExample {
  final String japanese; // 일본어 예문
  final String furigana; // 후리가나 읽기
  final String korean; // 한국어 번역
  final String? explanation; // 해설 (퀴즈용)
  final DateTime? createdAt; // 생성 시간
  final String? source; // 출처 (gemini/manual/user)

  const KanjiExample({
    required this.japanese,
    required this.furigana,
    required this.korean,
    this.explanation,
    this.createdAt,
    this.source = 'manual',
  });

  factory KanjiExample.fromJson(Map<String, dynamic> json) {
    return KanjiExample(
      japanese: json['japanese'] as String,
      furigana:
          json['furigana'] as String? ??
          json['hiragana'] as String? ??
          '', // 호환성을 위해 hiragana도 체크
      korean: json['korean'] as String,
      explanation: json['explanation'] as String?,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : null,
      source: json['source'] as String? ?? 'manual',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'japanese': japanese,
      'furigana': furigana,
      'korean': korean,
      'explanation': explanation,
      'createdAt': createdAt?.toIso8601String(),
      'source': source,
    };
  }

  // Legacy support: convert from simple string
  static KanjiExample fromString(String example) {
    return KanjiExample(
      japanese: example,
      furigana: '',
      korean: '',
      source: 'legacy',
    );
  }

  @override
  String toString() {
    return japanese;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is KanjiExample &&
        other.japanese == japanese &&
        other.furigana == furigana &&
        other.korean == korean;
  }

  @override
  int get hashCode => japanese.hashCode ^ furigana.hashCode ^ korean.hashCode;
}
