import 'kanji_example.dart';

class Kanji {
  final int id;
  final String character;
  final List<String> meanings;
  final KanjiReadings readings;
  final List<String> koreanOnReadings; // 한글 음독
  final List<String> koreanKunReadings; // 한글 훈독
  final int grade;
  final int jlpt;
  final int strokeCount;
  final List<KanjiExample> examples;
  final String? radical; // 부수
  final String? commentary; // 한자 해설

  const Kanji({
    required this.id,
    required this.character,
    required this.meanings,
    required this.readings,
    this.koreanOnReadings = const [],
    this.koreanKunReadings = const [],
    required this.grade,
    required this.jlpt,
    required this.strokeCount,
    required this.examples,
    this.radical,
    this.commentary,
  });

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

    return Kanji(
      id: json['id'] as int,
      character: json['character'] as String,
      meanings: List<String>.from(json['meanings'] as List),
      readings: KanjiReadings.fromJson(
        json['readings'] as Map<String, dynamic>,
      ),
      koreanOnReadings: json['korean_on_readings'] != null
          ? List<String>.from(json['korean_on_readings'] as List)
          : [],
      koreanKunReadings: json['korean_kun_readings'] != null
          ? List<String>.from(json['korean_kun_readings'] as List)
          : [],
      grade: json['grade'] as int,
      jlpt: json['jlpt'] as int,
      strokeCount: json['strokeCount'] as int,
      examples: parseExamples(json['examples']),
      radical: json['radical'] as String?,
      commentary: json['commentary'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'character': character,
      'meanings': meanings,
      'readings': readings.toJson(),
      'korean_on_readings': koreanOnReadings,
      'korean_kun_readings': koreanKunReadings,
      'grade': grade,
      'jlpt': jlpt,
      'strokeCount': strokeCount,
      'examples': examples.map((e) => e.toJson()).toList(),
      'radical': radical,
      'commentary': commentary,
    };
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
