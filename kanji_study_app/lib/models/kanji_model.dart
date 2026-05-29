import 'kanji_example.dart';
import 'language_settings.dart';

class Kanji {
  final int id;
  final String character;
  final List<String> meanings;
  final List<String> meaningsKo;
  final List<String> meaningsEn;
  final List<String> krMeanings;
  final List<String> jpMeanings;
  final List<String> enMeanings;
  final KanjiReadings readings;
  final List<String> jpOnReadings;
  final List<String> jpKunReadings;
  final List<String> krOnReadings;
  final List<String> krKunReadings;
  final List<String> koreanOnReadings; // 한글 음독
  final List<String> koreanKunReadings; // 한글 훈독
  final int grade;
  final int jlpt;
  final int strokeCount;
  final List<KanjiExample> examples;
  final String? radical; // 부수
  final String? commentary; // 한자 해설
  final String? krCommentary;
  final String? jpCommentary;
  final String? enCommentary;
  final String source;
  final String? externalId;
  final String? sourceVersion;
  final String qualityStatus;
  final String meaningSource;
  final bool isCommon;
  final int? priorityRank;
  final List<String> tags;
  final DateTime? updatedAt;

  Kanji({
    required this.id,
    required this.character,
    required this.meanings,
    List<String>? meaningsKo,
    this.meaningsEn = const [],
    List<String>? krMeanings,
    this.jpMeanings = const [],
    List<String>? enMeanings,
    required this.readings,
    List<String>? jpOnReadings,
    List<String>? jpKunReadings,
    List<String>? krOnReadings,
    List<String>? krKunReadings,
    List<String>? koreanOnReadings,
    List<String>? koreanKunReadings,
    required this.grade,
    required this.jlpt,
    required this.strokeCount,
    required this.examples,
    this.radical,
    this.commentary,
    String? krCommentary,
    this.jpCommentary,
    this.enCommentary,
    this.source = 'legacy_excel',
    this.externalId,
    this.sourceVersion,
    this.qualityStatus = 'reviewed',
    this.meaningSource = 'legacy_excel',
    this.isCommon = false,
    this.priorityRank,
    this.tags = const [],
    this.updatedAt,
  }) : meaningsKo = meaningsKo ?? meanings,
       krMeanings = krMeanings ?? meaningsKo ?? meanings,
       enMeanings = enMeanings ?? meaningsEn,
       jpOnReadings = jpOnReadings ?? readings.on,
       jpKunReadings = jpKunReadings ?? readings.kun,
       krOnReadings = krOnReadings ?? koreanOnReadings ?? const [],
       krKunReadings = krKunReadings ?? koreanKunReadings ?? const [],
       koreanOnReadings = koreanOnReadings ?? krOnReadings ?? const [],
       koreanKunReadings = koreanKunReadings ?? krKunReadings ?? const [],
       krCommentary = krCommentary ?? commentary;

  factory Kanji.fromJson(Map<String, dynamic> json) {
    // Handle legacy format (List<String>) and new format (List<KanjiExample>)
    List<KanjiExample> parseExamples(dynamic examplesData) {
      if (examplesData == null || examplesData is! List) {
        return [];
      }

      final List<KanjiExample> result = [];
      for (final example in examplesData) {
        if (example is String) {
          // Legacy format: convert string to KanjiExample
          result.add(KanjiExample.fromString(example));
        } else if (example is Map<String, dynamic>) {
          // New format: parse as KanjiExample
          result.add(KanjiExample.fromJson(example));
        } else {
          result.add(KanjiExample.fromString(example.toString()));
        }
      }
      return result;
    }

    List<String> parseStringList(dynamic value) {
      if (value == null || value is! List) {
        return [];
      }
      return value.map((item) => item.toString()).toList();
    }

    bool hasKorean(String value) => RegExp(r'[가-힣]').hasMatch(value);

    final rawMeanings = parseStringList(json['meanings']);
    final explicitMeaningsKo = parseStringList(json['meanings_ko']);
    final explicitMeaningsEn = parseStringList(json['meanings_en']);
    final explicitKrMeanings = parseStringList(json['kr_meanings']);
    final explicitJpMeanings = parseStringList(json['jp_meanings']);
    final explicitEnMeanings = parseStringList(json['en_meanings']);
    final fallbackMeaningsKo = rawMeanings.where(hasKorean).toList();
    final fallbackMeaningsEn = rawMeanings.where((m) => !hasKorean(m)).toList();
    final meaningsKo = explicitMeaningsKo.isNotEmpty
        ? explicitMeaningsKo
        : fallbackMeaningsKo;
    final meaningsEn = explicitMeaningsEn.isNotEmpty
        ? explicitMeaningsEn
        : fallbackMeaningsEn;
    final readingsJson = json['readings'] is Map<String, dynamic>
        ? json['readings'] as Map<String, dynamic>
        : <String, dynamic>{};
    final jpOnReadings = parseStringList(json['jp_on_readings']);
    final jpKunReadings = parseStringList(json['jp_kun_readings']);
    final legacyOnReadings = parseStringList(json['on_readings']);
    final legacyKunReadings = parseStringList(json['kun_readings']);
    final readings = KanjiReadings(
      on: jpOnReadings.isNotEmpty
          ? jpOnReadings
          : legacyOnReadings.isNotEmpty
          ? legacyOnReadings
          : parseStringList(readingsJson['on']),
      kun: jpKunReadings.isNotEmpty
          ? jpKunReadings
          : legacyKunReadings.isNotEmpty
          ? legacyKunReadings
          : parseStringList(readingsJson['kun']),
    );
    final krOnReadings = parseStringList(json['kr_on_readings']);
    final krKunReadings = parseStringList(json['kr_kun_readings']);
    final koreanOnReadings = parseStringList(json['korean_on_readings']);
    final koreanKunReadings = parseStringList(json['korean_kun_readings']);

    return Kanji(
      id: json['id'] as int,
      character: json['character'] as String,
      meanings: meaningsKo,
      meaningsKo: meaningsKo,
      meaningsEn: meaningsEn,
      krMeanings: explicitKrMeanings.isNotEmpty
          ? explicitKrMeanings
          : meaningsKo,
      jpMeanings: explicitJpMeanings,
      enMeanings: explicitEnMeanings.isNotEmpty
          ? explicitEnMeanings
          : meaningsEn,
      readings: readings,
      jpOnReadings: jpOnReadings.isNotEmpty ? jpOnReadings : readings.on,
      jpKunReadings: jpKunReadings.isNotEmpty ? jpKunReadings : readings.kun,
      krOnReadings: krOnReadings.isNotEmpty ? krOnReadings : koreanOnReadings,
      krKunReadings: krKunReadings.isNotEmpty
          ? krKunReadings
          : koreanKunReadings,
      koreanOnReadings: koreanOnReadings.isNotEmpty
          ? koreanOnReadings
          : krOnReadings,
      koreanKunReadings: koreanKunReadings.isNotEmpty
          ? koreanKunReadings
          : krKunReadings,
      grade: json['grade'] as int,
      jlpt: json['jlpt'] as int,
      strokeCount: json['strokeCount'] as int,
      examples: parseExamples(json['examples']),
      radical: json['radical'] as String?,
      commentary: json['commentary'] as String?,
      krCommentary:
          (json['kr_commentary'] as String?) ?? (json['commentary'] as String?),
      jpCommentary: json['jp_commentary'] as String?,
      enCommentary: json['en_commentary'] as String?,
      source: json['source'] as String? ?? 'legacy_excel',
      externalId: json['external_id'] as String?,
      sourceVersion: json['source_version'] as String?,
      qualityStatus: json['quality_status'] as String? ?? 'reviewed',
      meaningSource: json['meaning_source'] as String? ?? 'legacy_excel',
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
      'character': character,
      'meanings': meanings,
      'meanings_ko': meaningsKo,
      'meanings_en': meaningsEn,
      'kr_meanings': krMeanings,
      'jp_meanings': jpMeanings,
      'en_meanings': enMeanings,
      'readings': readings.toJson(),
      'jp_on_readings': jpOnReadings,
      'jp_kun_readings': jpKunReadings,
      'kr_on_readings': krOnReadings,
      'kr_kun_readings': krKunReadings,
      'korean_on_readings': koreanOnReadings,
      'korean_kun_readings': koreanKunReadings,
      'grade': grade,
      'jlpt': jlpt,
      'strokeCount': strokeCount,
      'examples': examples.map((e) => e.toJson()).toList(),
      'radical': radical,
      'commentary': commentary,
      'kr_commentary': krCommentary,
      'jp_commentary': jpCommentary,
      'en_commentary': enCommentary,
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

  List<String> displayMeanings(KanjiMeaningLanguage language) {
    final selected = switch (language) {
      KanjiMeaningLanguage.ko => krMeanings.isNotEmpty
          ? krMeanings
          : meaningsKo,
      KanjiMeaningLanguage.en => enMeanings.isNotEmpty
          ? enMeanings
          : meaningsEn,
    };
    if (selected.isNotEmpty) return selected;
    if (krMeanings.isNotEmpty) return krMeanings;
    if (meaningsKo.isNotEmpty) return meaningsKo;
    return meanings;
  }

  String displayMeaningsText(KanjiMeaningLanguage language) {
    return displayMeanings(language)
        .where((meaning) => meaning.isNotEmpty)
        .join(', ');
  }

  String? displayCommentary(AppLanguage appLanguage) {
    final selected = switch (appLanguage) {
      AppLanguage.en => enCommentary,
      AppLanguage.ja => jpCommentary,
      AppLanguage.ko => krCommentary ?? commentary,
    };
    if (selected != null && selected.isNotEmpty) return selected;
    if (krCommentary != null && krCommentary!.isNotEmpty) return krCommentary;
    if (commentary != null && commentary!.isNotEmpty) return commentary;
    return null;
  }
}

class KanjiReadings {
  final List<String> on; // 음독
  final List<String> kun; // 훈독

  const KanjiReadings({required this.on, required this.kun});

  factory KanjiReadings.fromJson(Map<String, dynamic> json) {
    return KanjiReadings(
      on: List<String>.from(json['on'] as List),
      kun: List<String>.from(json['kun'] as List),
    );
  }

  Map<String, dynamic> toJson() {
    return {'on': on, 'kun': kun};
  }

  List<String> get all => [...on, ...kun];
}
