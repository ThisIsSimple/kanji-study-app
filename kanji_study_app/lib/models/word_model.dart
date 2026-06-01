import 'word_meaning_model.dart';
import 'language_settings.dart';

class Word {
  final int id;
  final String word;
  final String reading;
  final List<WordMeaning> meanings;
  final List<WordMeaning> meaningsKo;
  final List<WordMeaning> meaningsEn;
  final List<WordMeaning> meaningsJp;
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
    List<WordMeaning>? meaningsKo,
    this.meaningsEn = const [],
    this.meaningsJp = const [],
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
  }) : meaningsKo = meaningsKo ?? meanings;

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

    bool hasKorean(String value) => RegExp(r'[가-힣]').hasMatch(value);

    final rawMeanings = parseMeanings(json['meanings']);
    final explicitMeaningsKo = parseMeanings(json['meanings_ko']);
    final explicitMeaningsEn = parseMeanings(json['meanings_en']);
    final explicitMeaningsJp = parseMeanings(json['meanings_jp']);
    final fallbackMeaningsKo = rawMeanings
        .where((meaning) => hasKorean(meaning.meaning))
        .toList();
    final fallbackMeaningsEn = rawMeanings
        .where((meaning) => !hasKorean(meaning.meaning))
        .toList();
    final meaningsKo = explicitMeaningsKo.isNotEmpty
        ? explicitMeaningsKo
        : fallbackMeaningsKo;
    final meaningsEn = explicitMeaningsEn.isNotEmpty
        ? explicitMeaningsEn
        : fallbackMeaningsEn;

    return Word(
      id: json['id'] as int,
      word: json['word'] as String,
      reading: json['reading'] as String,
      meanings: meaningsKo,
      meaningsKo: meaningsKo,
      meaningsEn: meaningsEn,
      meaningsJp: explicitMeaningsJp,
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
      'meanings_ko': meaningsKo.map((m) => m.toJson()).toList(),
      'meanings_en': meaningsEn.map((m) => m.toJson()).toList(),
      'meanings_jp': meaningsJp.map((m) => m.toJson()).toList(),
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
  String get meaningsText => displayMeaningsText(WordMeaningLanguage.ko);

  List<WordMeaning> displayMeanings(WordMeaningLanguage language) {
    final selected = switch (language) {
      WordMeaningLanguage.ko => meaningsKo,
      WordMeaningLanguage.en => meaningsEn,
      WordMeaningLanguage.ja => meaningsJp,
    };
    if (selected.isNotEmpty) return selected;
    if (meaningsKo.isNotEmpty) return meaningsKo;
    return meanings;
  }

  String displayMeaningsText(WordMeaningLanguage language) {
    return displayMeanings(language)
        .map((m) => m.meaning)
        .where((m) => m.isNotEmpty)
        .join(', ');
  }

  // Helper method to check if word matches search query
  bool matchesQuery(String query, {WordMeaningLanguage? meaningLanguage}) {
    final lowerQuery = query.toLowerCase();

    // Check word
    if (word.toLowerCase().contains(lowerQuery)) return true;

    // Check reading
    if (reading.toLowerCase().contains(lowerQuery)) return true;

    // Check meanings
    final meaningsToSearch = meaningLanguage == null
        ? meanings
        : displayMeanings(meaningLanguage);
    for (final meaning in meaningsToSearch) {
      if (meaning.meaning.toLowerCase().contains(lowerQuery)) return true;
      if (meaning.partOfSpeech.toLowerCase().contains(lowerQuery)) return true;
    }

    return false;
  }
}
