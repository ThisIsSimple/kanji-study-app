class KanjiExample {
  final String japanese;      // 일본어 예문
  final String hiragana;      // 히라가나 읽기
  final String korean;        // 한국어 번역
  final DateTime? createdAt;  // 생성 시간
  final String? source;       // 출처 (gemini/manual/user)

  const KanjiExample({
    required this.japanese,
    required this.hiragana,
    required this.korean,
    this.createdAt,
    this.source = 'manual',
  });

  factory KanjiExample.fromJson(Map<String, dynamic> json) {
    return KanjiExample(
      japanese: json['japanese'] as String,
      hiragana: json['hiragana'] as String,
      korean: json['korean'] as String,
      createdAt: json['createdAt'] != null 
          ? DateTime.parse(json['createdAt'] as String)
          : null,
      source: json['source'] as String? ?? 'manual',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'japanese': japanese,
      'hiragana': hiragana,
      'korean': korean,
      'createdAt': createdAt?.toIso8601String(),
      'source': source,
    };
  }

  // Legacy support: convert from simple string
  static KanjiExample fromString(String example) {
    return KanjiExample(
      japanese: example,
      hiragana: '',
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
        other.hiragana == hiragana &&
        other.korean == korean;
  }

  @override
  int get hashCode => japanese.hashCode ^ hiragana.hashCode ^ korean.hashCode;
}