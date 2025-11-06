import 'word_meaning_model.dart';

class Word {
  final int id;
  final String word;
  final String reading;
  final List<WordMeaning> meanings;
  final int jlptLevel;

  const Word({
    required this.id,
    required this.word,
    required this.reading,
    required this.meanings,
    required this.jlptLevel,
  });

  factory Word.fromJson(Map<String, dynamic> json) {
    List<WordMeaning> parseMeanings(dynamic meaningsData) {
      if (meaningsData == null || meaningsData is! List) {
        return [];
      }

      return meaningsData
          .map(
            (meaning) => WordMeaning.fromJson(meaning as Map<String, dynamic>),
          )
          .toList();
    }

    return Word(
      id: json['id'] as int,
      word: json['word'] as String,
      reading: json['reading'] as String,
      meanings: parseMeanings(json['meanings']),
      jlptLevel: json['jlpt_level'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'word': word,
      'reading': reading,
      'meanings': meanings.map((m) => m.toJson()).toList(),
      'jlpt_level': jlptLevel,
    };
  }

  // Helper method to get combined meanings string
  String get meaningsText {
    return meanings.map((m) => m.meaning).where((m) => m.isNotEmpty).join(', ');
  }

  // Helper method to check if word matches search query
  bool matchesQuery(String query) {
    final lowerQuery = query.toLowerCase();

    // Check word
    if (word.toLowerCase().contains(lowerQuery)) return true;

    // Check reading
    if (reading.toLowerCase().contains(lowerQuery)) return true;

    // Check meanings
    for (final meaning in meanings) {
      if (meaning.meaning.toLowerCase().contains(lowerQuery)) return true;
      if (meaning.partOfSpeech.toLowerCase().contains(lowerQuery)) return true;
    }

    return false;
  }
}
