import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/kanji_model.dart';
import '../models/kanji_example.dart';
import '../models/word_model.dart';
import '../models/word_example_model.dart';
import '../models/user_progress.dart';

class GeminiService {
  static final GeminiService _instance = GeminiService._internal();
  static GeminiService get instance => _instance;

  GeminiService._internal();

  static const String _apiKeyPref = 'gemini_api_key';
  static const String _examplesCachePref = 'gemini_examples_cache';
  static const String _modelName = 'gemini-2.0-flash';

  String? _apiKey;
  bool _isInitialized = false;
  GenerativeModel? _model;

  Future<void> init() async {
    if (_isInitialized) return;

    final prefs = await SharedPreferences.getInstance();
    _apiKey = prefs.getString(_apiKeyPref);

    if (_apiKey != null && _apiKey!.isNotEmpty) {
      _model = GenerativeModel(model: _modelName, apiKey: _apiKey!);
      _isInitialized = true;
    }
  }

  Future<void> setApiKey(String apiKey) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_apiKeyPref, apiKey);
    _apiKey = apiKey;

    _model = GenerativeModel(model: _modelName, apiKey: apiKey);
    _isInitialized = true;
  }

  bool get isInitialized => _isInitialized && _apiKey != null && _model != null;

  String? get apiKey => _apiKey;

  /// 내부 헬퍼: 텍스트 생성 요청
  Future<String?> _generateContent(String prompt) async {
    if (!isInitialized || _model == null) {
      throw Exception('Gemini API가 초기화되지 않았습니다. API 키를 설정해주세요.');
    }

    try {
      final content = [Content.text(prompt)];
      final response = await _model!.generateContent(content);
      return response.text;
    } catch (e) {
      debugPrint('Gemini API 오류: $e');
      rethrow;
    }
  }

  // ============= 한자 예문 생성 =============

  /// 한자 예문 생성 함수
  Future<List<KanjiExample>> generateExamples(Kanji kanji) async {
    if (!isInitialized) {
      throw Exception('Gemini API가 초기화되지 않았습니다. API 키를 설정해주세요.');
    }

    // 캐시 확인
    final cachedExamples = await _getCachedExamples(kanji.character);
    if (cachedExamples.isNotEmpty) {
      return cachedExamples;
    }

    try {
      final prompt = _buildKanjiExamplePrompt(kanji);
      final response = await _generateContent(prompt);

      if (response == null) {
        throw Exception('응답을 받지 못했습니다.');
      }

      final examples = _parseKanjiExampleResponse(response);

      // 캐시에 저장
      await _cacheExamples(kanji.character, examples);

      return examples;
    } catch (e) {
      debugPrint('Gemini API 오류: $e');
      rethrow;
    }
  }

  // ============= 단어 예문 생성 (word_detail_screen용) =============

  /// 단어 예문 생성 함수
  Future<List<WordExample>> generateWordExamples(Word word) async {
    if (!isInitialized) {
      throw Exception('Gemini API가 초기화되지 않았습니다. API 키를 설정해주세요.');
    }

    try {
      final prompt = _buildWordExamplePrompt(word);
      final response = await _generateContent(prompt);

      if (response == null) {
        throw Exception('응답을 받지 못했습니다.');
      }

      return _parseWordExampleResponse(response);
    } catch (e) {
      debugPrint('Gemini API 오류 (단어 예문): $e');
      rethrow;
    }
  }

  String _buildWordExamplePrompt(Word word) {
    return '''
다음 일본어 단어에 대한 예문을 3개 만들어주세요. 각 예문은 일상생활에서 자연스럽게 사용할 수 있는 문장이어야 합니다.

단어: ${word.word}
읽기: ${word.reading}
의미: ${word.meaningsText}

다음 형식으로 응답해주세요:
[예문1]
일본어: (일본어 문장)
히라가나: (히라가나로 표기)
한국어: (한국어 번역)

[예문2]
일본어: (일본어 문장)
히라가나: (히라가나로 표기)
한국어: (한국어 번역)

[예문3]
일본어: (일본어 문장)
히라가나: (히라가나로 표기)
한국어: (한국어 번역)
''';
  }

  List<WordExample> _parseWordExampleResponse(String response) {
    final examples = <WordExample>[];
    final lines = response.split('\n');

    String? japanese;
    String? furigana;
    String? korean;

    for (final line in lines) {
      if (line.startsWith('일본어:')) {
        japanese = line.substring('일본어:'.length).trim();
      } else if (line.startsWith('히라가나:') || line.startsWith('후리가나:')) {
        furigana = line.substring(line.indexOf(':') + 1).trim();
      } else if (line.startsWith('한국어:')) {
        korean = line.substring('한국어:'.length).trim();

        // 세 가지 구성요소가 모두 있으면 예문 생성
        if (japanese != null && furigana != null) {
          examples.add(
            WordExample(
              japanese: japanese,
              furigana: furigana,
              korean: korean,
              source: 'gemini',
              createdAt: DateTime.now(),
            ),
          );

          // 다음 예문을 위해 초기화
          japanese = null;
          furigana = null;
          korean = null;
        }
      }
    }

    return examples;
  }

  // ============= 퀴즈 문제 생성 =============

  /// 퀴즈 문제 생성 함수
  Future<List<Map<String, dynamic>>> generateQuizQuestions(
    List<Kanji> kanjiList,
  ) async {
    if (!isInitialized) {
      throw Exception('Gemini API가 초기화되지 않았습니다.');
    }

    try {
      final prompt = _buildQuizPrompt(kanjiList);
      final response = await _generateContent(prompt);

      if (response == null) {
        throw Exception('응답을 받지 못했습니다.');
      }

      return _parseQuizResponse(response);
    } catch (e) {
      debugPrint('Gemini API 오류: $e');
      rethrow;
    }
  }

  // ============= 학습 팁 생성 =============

  /// 학습 팁 생성 함수
  Future<String> generateStudyTips(Kanji kanji) async {
    if (!isInitialized) {
      throw Exception('Gemini API가 초기화되지 않았습니다.');
    }

    try {
      final prompt =
          '''
한자: ${kanji.character}
의미: ${kanji.meanings.join(', ')}
음독: ${kanji.readings.on.join(', ')}
훈독: ${kanji.readings.kun.join(', ')}

이 한자를 효과적으로 암기할 수 있는 방법이나 연상법을 한국어로 제안해주세요.
한자의 모양이나 의미와 연관된 이야기나 이미지를 활용하면 좋습니다.
간단하고 기억하기 쉬운 2-3가지 팁을 제공해주세요.
''';

      final response = await _generateContent(prompt);
      return response ?? '학습 팁을 생성하지 못했습니다.';
    } catch (e) {
      debugPrint('Gemini API 오류: $e');
      rethrow;
    }
  }

  // ============= 학습 진도 분석 =============

  /// 학습 진도 분석 함수
  Future<String> analyzeProgress(
    List<UserProgress> progressList,
    List<Kanji> allKanji,
  ) async {
    if (!isInitialized) {
      throw Exception('Gemini API가 초기화되지 않았습니다.');
    }

    try {
      final prompt = _buildProgressAnalysisPrompt(progressList, allKanji);
      final response = await _generateContent(prompt);
      return response ?? '분석을 생성하지 못했습니다.';
    } catch (e) {
      debugPrint('Gemini API 오류: $e');
      rethrow;
    }
  }

  // ============= Private helper methods =============

  String _buildKanjiExamplePrompt(Kanji kanji) {
    return '''
한자: ${kanji.character}
의미: ${kanji.meanings.join(', ')}
음독: ${kanji.readings.on.join(', ')}
훈독: ${kanji.readings.kun.join(', ')}
학년: ${kanji.grade <= 6 ? '${kanji.grade}학년' : '중학교+'}
JLPT: N${kanji.jlpt}

위 한자를 사용한 일상생활에서 자주 쓰는 예문을 3개 생성해주세요.
JLPT N${kanji.jlpt} 수준에 맞는 난이도로 작성해주세요.

각 예문마다 다음 형식으로 작성해주세요:
예문1:
일본어: [일본어 문장]
히라가나: [전체 문장의 히라가나 읽기]
한국어: [자연스러운 한국어 번역]

예문2:
일본어: [일본어 문장]
히라가나: [전체 문장의 히라가나 읽기]
한국어: [자연스러운 한국어 번역]

예문3:
일본어: [일본어 문장]
히라가나: [전체 문장의 히라가나 읽기]
한국어: [자연스러운 한국어 번역]
''';
  }

  List<KanjiExample> _parseKanjiExampleResponse(String response) {
    final examples = <KanjiExample>[];

    try {
      // 예문 구분 패턴
      final examplePattern = RegExp(r'예문\d+:', multiLine: true);
      final parts = response.split(examplePattern);

      for (var i = 1; i < parts.length; i++) {
        final part = parts[i].trim();
        if (part.isEmpty) continue;

        final lines = part.split('\n');
        String japanese = '';
        String furigana = '';
        String korean = '';

        for (final line in lines) {
          if (line.startsWith('일본어:')) {
            japanese = line.substring('일본어:'.length).trim();
          } else if (line.startsWith('히라가나:') || line.startsWith('후리가나:')) {
            furigana = line.substring(line.indexOf(':') + 1).trim();
          } else if (line.startsWith('한국어:')) {
            korean = line.substring('한국어:'.length).trim();
          }
        }

        if (japanese.isNotEmpty && furigana.isNotEmpty && korean.isNotEmpty) {
          examples.add(
            KanjiExample(
              japanese: japanese,
              furigana: furigana,
              korean: korean,
              createdAt: DateTime.now(),
              source: 'gemini',
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('예문 파싱 오류: $e');
    }

    return examples;
  }

  String _buildQuizPrompt(List<Kanji> kanjiList) {
    final kanjiInfo = kanjiList
        .map((k) => '${k.character} (${k.meanings.join(', ')})')
        .join(', ');

    return '''
다음 한자들로 퀴즈 문제를 5개 생성해주세요: $kanjiInfo

문제 유형:
1. 한자의 의미 맞추기 (4지선다)
2. 읽기 맞추기 (4지선다)
3. 올바른 한자 선택하기 (4지선다)

각 문제는 다음 JSON 형식으로 작성해주세요:
{
  "type": "meaning|reading|kanji",
  "question": "문제 내용",
  "options": ["선택지1", "선택지2", "선택지3", "선택지4"],
  "correctAnswer": 0,
  "explanation": "정답 설명"
}

5개의 문제를 JSON 배열로 반환해주세요.
''';
  }

  List<Map<String, dynamic>> _parseQuizResponse(String response) {
    try {
      // JSON 배열 추출
      final jsonMatch = RegExp(r'\[[\s\S]*\]').firstMatch(response);
      if (jsonMatch != null) {
        final jsonString = jsonMatch.group(0)!;
        return List<Map<String, dynamic>>.from(json.decode(jsonString));
      }
    } catch (e) {
      debugPrint('퀴즈 파싱 오류: $e');
    }

    return [];
  }

  String _buildProgressAnalysisPrompt(
    List<UserProgress> progressList,
    List<Kanji> allKanji,
  ) {
    final studiedCount = progressList.length;
    final masteredCount = progressList.where((p) => p.mastered).length;
    final totalCount = allKanji.length;

    return '''
학습 진도 분석:
- 전체 한자: $totalCount개
- 학습한 한자: $studiedCount개
- 마스터한 한자: $masteredCount개

학습한 한자들의 JLPT 레벨 분포와 학년 분포를 고려하여,
현재 학습 진도에 대한 분석과 앞으로의 학습 방향을 제안해주세요.
한국어로 간단명료하게 3-4문장으로 작성해주세요.
''';
  }

  // ============= 캐시 관련 메서드 =============

  Future<List<KanjiExample>> _getCachedExamples(String character) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheData = prefs.getString(_examplesCachePref);

      if (cacheData != null) {
        final cache = json.decode(cacheData) as Map<String, dynamic>;
        if (cache.containsKey(character)) {
          final examplesList = cache[character] as List;
          return examplesList
              .map((e) => KanjiExample.fromJson(e as Map<String, dynamic>))
              .toList();
        }
      }
    } catch (e) {
      debugPrint('캐시 읽기 오류: $e');
    }

    return [];
  }

  Future<void> _cacheExamples(
    String character,
    List<KanjiExample> examples,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheData = prefs.getString(_examplesCachePref);

      Map<String, dynamic> cache = {};
      if (cacheData != null) {
        cache = json.decode(cacheData) as Map<String, dynamic>;
      }

      cache[character] = examples.map((e) => e.toJson()).toList();

      await prefs.setString(_examplesCachePref, json.encode(cache));
    } catch (e) {
      debugPrint('캐시 저장 오류: $e');
    }
  }

  /// 캐시 초기화
  Future<void> clearCache() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_examplesCachePref);
  }
}
