import 'word_meaning_model.dart';

class Word {
  final int id;
  final String word;
  final String reading;
  final List<WordMeaning> meanings;
  final int jlptLevel;
  final String source;
  final String? externalId;
  final String? sourceVersion;
  final String qualityStatus;
  final String meaningSource;
  final bool isCommon;
  final int? priorityRank;
  final List<String> tags;
  final DateTime? updatedAt;

  const Word({
    required this.id,
    required this.word,
    required this.reading,
    required this.meanings,
    required this.jlptLevel,
    this.source = 'legacy_naver',
    this.externalId,
    this.sourceVersion,
    this.qualityStatus = 'reviewed',
    this.meaningSource = 'legacy_naver',
    this.isCommon = false,
    this.priorityRank,
    this.tags = const [],
    this.updatedAt,
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
      source: json['source'] as String? ?? 'legacy_naver',
      externalId: json['external_id'] as String?,
      sourceVersion: json['source_version'] as String?,
      qualityStatus: json['quality_status'] as String? ?? 'reviewed',
      meaningSource: json['meaning_source'] as String? ?? 'legacy_naver',
      isCommon: json['is_common'] as bool? ?? false,
      priorityRank: json['priority_rank'] as int?,
      tags: json['tags'] != null ? List<String>.from(json['tags'] as List) : [],
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'word': word,
      'reading': reading,
      'meanings': meanings.map((m) => m.toJson()).toList(),
      'jlpt_level': jlptLevel,
      'source': source,
      'external_id': externalId,
      'source_version': sourceVersion,
      'quality_status': qualityStatus,
      'meaning_source': meaningSource,
      'is_common': isCommon,
      'priority_rank': priorityRank,
      'tags': tags,
      'updated_at': updatedAt?.toUtc().toIso8601String(),
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
