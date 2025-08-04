import 'kanji_example.dart';

class Kanji {
  final int id;
  final String character;
  final List<String> meanings;
  final KanjiReadings readings;
  final int grade;
  final int jlpt;
  final int strokeCount;
  final int frequency;
  final List<KanjiExample> examples;

  const Kanji({
    required this.id,
    required this.character,
    required this.meanings,
    required this.readings,
    required this.grade,
    required this.jlpt,
    required this.strokeCount,
    required this.frequency,
    required this.examples,
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
      readings: KanjiReadings.fromJson(json['readings'] as Map<String, dynamic>),
      grade: json['grade'] as int,
      jlpt: json['jlpt'] as int,
      strokeCount: json['strokeCount'] as int,
      frequency: json['frequency'] as int,
      examples: parseExamples(json['examples']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'character': character,
      'meanings': meanings,
      'readings': readings.toJson(),
      'grade': grade,
      'jlpt': jlpt,
      'strokeCount': strokeCount,
      'frequency': frequency,
      'examples': examples.map((e) => e.toJson()).toList(),
    };
  }
}

class KanjiReadings {
  final List<String> on;  // 음독
  final List<String> kun; // 훈독

  const KanjiReadings({
    required this.on,
    required this.kun,
  });

  factory KanjiReadings.fromJson(Map<String, dynamic> json) {
    return KanjiReadings(
      on: List<String>.from(json['on'] as List),
      kun: List<String>.from(json['kun'] as List),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'on': on,
      'kun': kun,
    };
  }

  List<String> get all => [...on, ...kun];
}

