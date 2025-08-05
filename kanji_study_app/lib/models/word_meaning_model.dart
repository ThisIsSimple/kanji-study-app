class WordMeaning {
  final String partOfSpeech;
  final String meaning;

  const WordMeaning({
    required this.partOfSpeech,
    required this.meaning,
  });

  factory WordMeaning.fromJson(Map<String, dynamic> json) {
    return WordMeaning(
      partOfSpeech: json['part_of_speech'] as String? ?? '',
      meaning: json['meaning'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'part_of_speech': partOfSpeech,
      'meaning': meaning,
    };
  }
}