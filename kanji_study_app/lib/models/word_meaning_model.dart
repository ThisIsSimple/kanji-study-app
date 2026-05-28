class WordMeaning {
  final String partOfSpeech;
  final String meaning;
  final String? source;
  final String? qualityStatus;

  const WordMeaning({
    required this.partOfSpeech,
    required this.meaning,
    this.source,
    this.qualityStatus,
  });

  factory WordMeaning.fromJson(Map<String, dynamic> json) {
    return WordMeaning(
      partOfSpeech: json['part_of_speech'] as String? ?? '',
      meaning: json['meaning'] as String? ?? '',
      source: json['source'] as String?,
      qualityStatus: json['quality_status'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'part_of_speech': partOfSpeech,
      'meaning': meaning,
      if (source != null) 'source': source,
      if (qualityStatus != null) 'quality_status': qualityStatus,
    };
  }
}
