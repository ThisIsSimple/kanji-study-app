import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../models/ai_quiz.dart';
import '../models/ai_quiz_attempt.dart';
import 'supabase_service.dart';
import 'gemini_service.dart';

/// 퀴즈 문제 검증기
class _QuizQuestionValidator {
  /// JSON 응답에서 퀴즈 문제를 검증하고 유효한 경우 반환
  /// 유효하지 않으면 null 반환
  static Map<String, dynamic>? validate(Map<String, dynamic> json) {
    try {
      // 필수 필드 존재 여부 검증
      if (!json.containsKey('question') || json['question'] is! String) {
        debugPrint('검증 실패: question 필드가 없거나 유효하지 않음');
        return null;
      }
      if (!json.containsKey('options') || json['options'] is! List) {
        debugPrint('검증 실패: options 필드가 없거나 유효하지 않음');
        return null;
      }
      if (!json.containsKey('correct_answer') ||
          json['correct_answer'] is! String) {
        debugPrint('검증 실패: correct_answer 필드가 없거나 유효하지 않음');
        return null;
      }
      if (!json.containsKey('explanation') || json['explanation'] is! String) {
        debugPrint('검증 실패: explanation 필드가 없거나 유효하지 않음');
        return null;
      }

      final question = json['question'] as String;
      final options = List<String>.from(json['options']);
      final correctAnswer = json['correct_answer'] as String;
      final explanation = json['explanation'] as String;

      // 빈 문자열 검증
      if (question.trim().isEmpty) {
        debugPrint('검증 실패: question이 비어있음');
        return null;
      }

      // 옵션 개수 검증 (4개)
      if (options.length != 4) {
        debugPrint('검증 실패: options 개수가 4개가 아님 (${options.length}개)');
        return null;
      }

      // 정답이 옵션에 포함되어 있는지 검증
      if (!options.contains(correctAnswer)) {
        debugPrint('검증 실패: correct_answer가 options에 포함되어 있지 않음');
        return null;
      }

      return {
        'question': question,
        'options': options,
        'correct_answer': correctAnswer,
        'explanation': explanation,
      };
    } catch (e) {
      debugPrint('검증 중 오류 발생: $e');
      return null;
    }
  }
}

/// AI 퀴즈 생성 및 관리 서비스
class AiQuizService {
  static final AiQuizService _instance = AiQuizService._internal();
  static AiQuizService get instance => _instance;

  AiQuizService._internal();

  final SupabaseService _supabaseService = SupabaseService.instance;
  final GeminiService _geminiService = GeminiService.instance;

  static const String _modelName = 'gemini-2.0-flash';

  /// Gemini API 사용 가능 여부
  bool get isGeminiAvailable => _geminiService.isInitialized;

  /// API 키 가져오기
  String? get _apiKey => _geminiService.apiKey;

  // ============= 퀴즈 생성 =============

  /// AI로 퀴즈 생성
  Future<AiQuiz> generateQuiz({
    required AiQuizType quizType,
    int? jlptLevel,
    int questionCount = 10,
  }) async {
    if (!isGeminiAvailable) {
      throw Exception('Gemini API가 초기화되지 않았습니다. 설정에서 API 키를 입력해주세요.');
    }

    final userId = _supabaseService.currentUser?.id;
    if (userId == null) {
      throw Exception('로그인이 필요합니다.');
    }

    // 1. 퀴즈에 사용할 단어/한자 가져오기
    final sourceItems = await _getSourceItems(
      quizType,
      jlptLevel,
      questionCount,
    );

    if (sourceItems.isEmpty) {
      throw Exception('퀴즈를 생성할 데이터가 없습니다.');
    }

    // 2. Gemini로 문제 생성
    final questionsData = await _generateQuestionsWithGemini(
      quizType: quizType,
      sourceItems: sourceItems,
      questionCount: questionCount,
    );

    // 3. 퀴즈를 DB에 저장
    final title = AiQuiz.generateTitle(quizType, jlptLevel);

    final quizData = await _supabaseService.client
        .from('ai_quizzes')
        .insert({
          'user_id': userId,
          'quiz_type': quizType.value,
          'title': title,
          'jlpt_level': jlptLevel,
          'question_count': questionsData.length,
        })
        .select()
        .single();

    final quizId = quizData['id'] as int;

    // 4. 문제들을 DB에 저장
    final questionsToInsert = questionsData.asMap().entries.map((entry) {
      final index = entry.key;
      final q = entry.value;
      return {
        'quiz_id': quizId,
        'question_index': index,
        'question': q['question'],
        'options': q['options'],
        'correct_answer': q['correct_answer'],
        'explanation': q['explanation'],
        'source_id': q['source_id'],
      };
    }).toList();

    await _supabaseService.client
        .from('ai_quiz_questions')
        .insert(questionsToInsert);

    // 5. 생성된 퀴즈 반환
    return await getQuizWithQuestions(quizId);
  }

  /// 퀴즈 유형에 따라 소스 데이터 가져오기
  Future<List<Map<String, dynamic>>> _getSourceItems(
    AiQuizType quizType,
    int? jlptLevel,
    int count,
  ) async {
    switch (quizType) {
      case AiQuizType.jpToKr:
      case AiQuizType.krToJp:
      case AiQuizType.fillBlank:
        // 단어 기반 퀴즈
        return await _getWords(jlptLevel, count * 2); // 오답 보기용으로 여유있게
      case AiQuizType.kanjiReading:
        // 한자 기반 퀴즈
        return await _getKanji(jlptLevel, count * 2);
    }
  }

  Future<List<Map<String, dynamic>>> _getWords(
    int? jlptLevel,
    int count,
  ) async {
    var query = _supabaseService.client
        .from('words')
        .select('id, word, reading, meanings, jlpt_level');

    if (jlptLevel != null) {
      query = query.eq('jlpt_level', jlptLevel);
    }

    final data = await query.limit(count);

    // 셔플해서 반환
    final list = List<Map<String, dynamic>>.from(data);
    list.shuffle();
    return list;
  }

  Future<List<Map<String, dynamic>>> _getKanji(
    int? jlptLevel,
    int count,
  ) async {
    var query = _supabaseService.client
        .from('kanji')
        .select('id, character, meanings, on_readings, kun_readings, jlpt');

    if (jlptLevel != null) {
      query = query.eq('jlpt', jlptLevel);
    }

    final data = await query.limit(count);

    final list = List<Map<String, dynamic>>.from(data);
    list.shuffle();
    return list;
  }

  /// Gemini로 문제 생성 (구조화된 출력 + 검증)
  Future<List<Map<String, dynamic>>> _generateQuestionsWithGemini({
    required AiQuizType quizType,
    required List<Map<String, dynamic>> sourceItems,
    required int questionCount,
  }) async {
    if (_apiKey == null) {
      throw Exception('Gemini API 키가 설정되지 않았습니다.');
    }

    final prompt = _buildQuizPrompt(quizType, sourceItems, questionCount);

    try {
      // 구조화된 출력을 위한 스키마 정의
      final schema = Schema.array(
        items: Schema.object(
          properties: {
            'question': Schema.string(description: '문제 내용', nullable: false),
            'options': Schema.array(
              items: Schema.string(description: '선택지'),
              description: '4개의 선택지 배열',
              nullable: false,
            ),
            'correct_answer': Schema.string(
              description: '정답 (options 중 하나)',
              nullable: false,
            ),
            'explanation': Schema.string(
              description: '정답 해설 (한국어)',
              nullable: false,
            ),
          },
          requiredProperties: [
            'question',
            'options',
            'correct_answer',
            'explanation',
          ],
        ),
        description: '퀴즈 문제 배열',
      );

      // GenerativeModel 생성 (구조화된 출력 설정)
      final model = GenerativeModel(
        model: _modelName,
        apiKey: _apiKey!,
        generationConfig: GenerationConfig(
          responseMimeType: 'application/json',
          responseSchema: schema,
        ),
      );

      final content = [Content.text(prompt)];
      final response = await model.generateContent(content);

      if (response.text == null) {
        throw Exception('Gemini 응답을 받지 못했습니다.');
      }

      return _parseAndValidateQuizResponse(response.text!, sourceItems);
    } catch (e) {
      debugPrint('Gemini 퀴즈 생성 오류: $e');
      // 폴백: 간단한 문제 자동 생성
      return _generateFallbackQuestions(quizType, sourceItems, questionCount);
    }
  }

  String _buildQuizPrompt(
    AiQuizType quizType,
    List<Map<String, dynamic>> sourceItems,
    int questionCount,
  ) {
    final itemsJson = json.encode(sourceItems.take(questionCount + 5).toList());

    String typeDescription;
    String exampleFormat;

    switch (quizType) {
      case AiQuizType.jpToKr:
        typeDescription = '일본어 단어를 보고 한국어 뜻을 맞추는 4지선다 퀴즈';
        exampleFormat = '''
{
  "question": "食べる",
  "options": ["먹다", "마시다", "자다", "걷다"],
  "correct_answer": "먹다",
  "explanation": "食べる(たべる)는 '먹다'라는 뜻입니다."
}''';
        break;
      case AiQuizType.krToJp:
        typeDescription = '한국어 뜻을 보고 일본어 단어를 맞추는 4지선다 퀴즈';
        exampleFormat = '''
{
  "question": "먹다",
  "options": ["食べる", "飲む", "寝る", "歩く"],
  "correct_answer": "食べる",
  "explanation": "'먹다'는 일본어로 食べる(たべる)입니다."
}''';
        break;
      case AiQuizType.kanjiReading:
        typeDescription = '한자를 보고 올바른 읽기(후리가나)를 맞추는 4지선다 퀴즈';
        exampleFormat = '''
{
  "question": "食",
  "options": ["しょく", "にく", "きょく", "ごく"],
  "correct_answer": "しょく",
  "explanation": "食의 음독은 しょく(식)입니다."
}''';
        break;
      case AiQuizType.fillBlank:
        typeDescription = '문장의 빈칸에 들어갈 올바른 단어를 맞추는 4지선다 퀴즈';
        exampleFormat = '''
{
  "question": "私は毎日ご飯を___。",
  "options": ["食べます", "飲みます", "見ます", "聞きます"],
  "correct_answer": "食べます",
  "explanation": "'밥을 먹다'는 ご飯を食べる입니다."
}''';
        break;
    }

    return '''
다음 데이터를 사용하여 $typeDescription를 $questionCount개 생성해주세요.

데이터:
$itemsJson

요구사항:
1. 각 문제는 정확히 4개의 선택지를 가집니다
2. 오답 선택지는 비슷하지만 다른 의미/읽기를 가진 것으로 구성
3. correct_answer는 반드시 options 배열에 포함된 값이어야 합니다
4. 설명(explanation)은 한국어로 간단히 작성

예시:
$exampleFormat

$questionCount개의 문제를 생성해주세요.
''';
  }

  /// 퀴즈 응답 파싱 및 검증
  List<Map<String, dynamic>> _parseAndValidateQuizResponse(
    String response,
    List<Map<String, dynamic>> sourceItems,
  ) {
    try {
      // JSON 배열 추출 (구조화된 출력이므로 바로 파싱 가능)
      List<dynamic> rawParsed;

      // 구조화된 출력인 경우 JSON 배열로 바로 파싱
      if (response.trim().startsWith('[')) {
        rawParsed = json.decode(response) as List<dynamic>;
      } else {
        // 혹시 다른 텍스트가 포함된 경우 JSON 배열 추출
        final jsonMatch = RegExp(r'\[[\s\S]*\]').firstMatch(response);
        if (jsonMatch == null) {
          debugPrint('JSON 배열을 찾을 수 없습니다.');
          return [];
        }
        rawParsed = json.decode(jsonMatch.group(0)!) as List<dynamic>;
      }

      // 검증된 문제들만 필터링
      final validQuestions = <Map<String, dynamic>>[];

      for (var i = 0; i < rawParsed.length; i++) {
        final rawQuestion = rawParsed[i] as Map<String, dynamic>;

        // 검증 수행
        final validated = _QuizQuestionValidator.validate(rawQuestion);

        if (validated != null) {
          // source_id 매핑
          if (i < sourceItems.length) {
            validated['source_id'] = sourceItems[i]['id'];
          }
          validQuestions.add(validated);
        } else {
          debugPrint('문제 ${i + 1} 검증 실패, 스킵');
        }
      }

      if (validQuestions.isEmpty) {
        debugPrint('유효한 문제가 없습니다.');
        return [];
      }

      debugPrint('검증 완료: ${validQuestions.length}/${rawParsed.length}개 문제 유효');
      return validQuestions;
    } catch (e) {
      debugPrint('퀴즈 응답 파싱 오류: $e');
      return [];
    }
  }

  /// 헬퍼 함수: meanings 배열에서 첫 번째 의미 추출
  /// meanings는 [{"part_of_speech": "...", "meaning": "..."}, ...] 형태의 List
  String _extractMeaningFromList(
    dynamic meanings, {
    String defaultValue = '뜻 없음',
  }) {
    if (meanings == null) return defaultValue;
    if (meanings is List && meanings.isNotEmpty) {
      final first = meanings.first;
      if (first is Map<String, dynamic>) {
        final meaning = first['meaning'] as String?;
        if (meaning != null && meaning.isNotEmpty) {
          return meaning;
        }
      }
    }
    return defaultValue;
  }

  /// 옵션 리스트가 4개가 되도록 더미 옵션 추가
  List<String> _ensureFourOptions(
    List<String> options,
    String correctAnswer,
    List<String> dummyOptions,
  ) {
    final result = options.toSet().toList(); // 중복 제거
    var dummyIndex = 0;

    while (result.length < 4 && dummyIndex < dummyOptions.length) {
      final dummy = dummyOptions[dummyIndex];
      if (!result.contains(dummy) && dummy != correctAnswer) {
        result.add(dummy);
      }
      dummyIndex++;
    }

    // 그래도 4개 미만이면 번호 붙여서 추가
    var fallbackIndex = 1;
    while (result.length < 4) {
      final fallback = '선택지 $fallbackIndex';
      if (!result.contains(fallback)) {
        result.add(fallback);
      }
      fallbackIndex++;
    }

    return result;
  }

  /// 폴백: Gemini 실패 시 간단한 문제 자동 생성
  List<Map<String, dynamic>> _generateFallbackQuestions(
    AiQuizType quizType,
    List<Map<String, dynamic>> sourceItems,
    int questionCount,
  ) {
    final questions = <Map<String, dynamic>>[];
    final itemsToUse = sourceItems.take(questionCount).toList();

    // 퀴즈 타입별 더미 옵션 정의
    const koreanDummyOptions = ['다른 뜻', '알 수 없음', '해당 없음', '기타'];
    const japaneseDummyOptions = ['わからない', 'ない', 'なし', 'その他'];
    const readingDummyOptions = ['カ', 'キ', 'ク', 'ケ', 'コ', 'サ', 'シ', 'ス'];

    for (var i = 0; i < itemsToUse.length; i++) {
      final item = itemsToUse[i];
      final otherItems = sourceItems
          .where((s) => s['id'] != item['id'])
          .take(3)
          .toList();

      Map<String, dynamic> question;

      switch (quizType) {
        case AiQuizType.jpToKr:
          final correctAnswer = _extractMeaningFromList(item['meanings']);
          final rawOptions = [
            correctAnswer,
            ...otherItems.map((o) => _extractMeaningFromList(o['meanings'])),
          ];
          final options = _ensureFourOptions(
            rawOptions,
            correctAnswer,
            koreanDummyOptions,
          )..shuffle();

          question = {
            'question': item['word'] ?? '',
            'options': options,
            'correct_answer': correctAnswer,
            'explanation': '${item['word']}의 뜻은 $correctAnswer입니다.',
            'source_id': item['id'],
          };
          break;

        case AiQuizType.krToJp:
          final koreanMeaning = _extractMeaningFromList(item['meanings']);
          final correctAnswer = item['word'] as String? ?? '';
          final rawOptions = <String>[
            correctAnswer,
            ...otherItems.map((o) => o['word'] as String? ?? ''),
          ];
          final options = _ensureFourOptions(
            rawOptions,
            correctAnswer,
            japaneseDummyOptions,
          )..shuffle();

          question = {
            'question': koreanMeaning,
            'options': options,
            'correct_answer': correctAnswer,
            'explanation': '$koreanMeaning는 일본어로 $correctAnswer입니다.',
            'source_id': item['id'],
          };
          break;

        case AiQuizType.kanjiReading:
          final onReadings =
              (item['on_readings'] as List?)?.cast<String>() ?? [];
          final correctAnswer = onReadings.isNotEmpty ? onReadings.first : 'なし';
          final rawOptions = [
            correctAnswer,
            ...otherItems.map((o) {
              final readings =
                  (o['on_readings'] as List?)?.cast<String>() ?? [];
              return readings.isNotEmpty ? readings.first : 'なし';
            }),
          ];
          final options = _ensureFourOptions(
            rawOptions,
            correctAnswer,
            readingDummyOptions,
          )..shuffle();

          question = {
            'question': item['character'] ?? '',
            'options': options,
            'correct_answer': correctAnswer,
            'explanation': '${item['character']}의 음독은 $correctAnswer입니다.',
            'source_id': item['id'],
          };
          break;

        case AiQuizType.fillBlank:
          final word = item['word'] as String? ?? '';
          final koreanMeaning = _extractMeaningFromList(
            item['meanings'],
            defaultValue: '뜻',
          );
          final correctAnswer = word;
          final rawOptions = <String>[
            correctAnswer,
            ...otherItems.map((o) => o['word'] as String? ?? ''),
          ];
          final options = _ensureFourOptions(
            rawOptions,
            correctAnswer,
            japaneseDummyOptions,
          )..shuffle();

          question = {
            'question': '「$koreanMeaning」を日本語で言うと？ ___',
            'options': options,
            'correct_answer': correctAnswer,
            'explanation': '정답은 $correctAnswer입니다.',
            'source_id': item['id'],
          };
          break;
      }

      questions.add(question);
    }

    return questions;
  }

  // ============= 퀴즈 조회 =============

  /// 퀴즈 목록 조회
  Future<List<AiQuiz>> getQuizzes({
    AiQuizType? quizType,
    int limit = 20,
    int offset = 0,
  }) async {
    final userId = _supabaseService.currentUser?.id;
    if (userId == null) return [];

    var query = _supabaseService.client
        .from('ai_quizzes')
        .select()
        .eq('user_id', userId);

    if (quizType != null) {
      query = query.eq('quiz_type', quizType.value);
    }

    final data = await query
        .order('created_at', ascending: false)
        .range(offset, offset + limit - 1);

    return (data as List).map((q) => AiQuiz.fromJson(q)).toList();
  }

  /// 퀴즈 상세 조회 (문제 포함)
  Future<AiQuiz> getQuizWithQuestions(int quizId) async {
    final data = await _supabaseService.client
        .from('ai_quizzes')
        .select('*, ai_quiz_questions(*)')
        .eq('id', quizId)
        .single();

    return AiQuiz.fromJson(data);
  }

  /// 퀴즈 삭제
  Future<void> deleteQuiz(int quizId) async {
    await _supabaseService.client.from('ai_quizzes').delete().eq('id', quizId);
  }

  // ============= 퀴즈 응시 =============

  /// 퀴즈 응시 시작
  Future<AiQuizAttempt> startAttempt(int quizId) async {
    final userId = _supabaseService.currentUser?.id;
    if (userId == null) {
      throw Exception('로그인이 필요합니다.');
    }

    final data = await _supabaseService.client
        .from('ai_quiz_attempts')
        .insert({'quiz_id': quizId, 'user_id': userId})
        .select()
        .single();

    return AiQuizAttempt.fromJson(data);
  }

  /// 퀴즈 응시 완료 및 답변 저장
  Future<AiQuizAttempt> submitAttempt({
    required int attemptId,
    required List<Map<String, dynamic>> answers,
  }) async {
    // 정답 수 계산
    final correctCount = answers.where((a) => a['is_correct'] == true).length;
    final score = correctCount; // 1문제당 1점

    // 응시 기록 업데이트
    await _supabaseService.client
        .from('ai_quiz_attempts')
        .update({
          'score': score,
          'correct_count': correctCount,
          'completed_at': DateTime.now().toIso8601String(),
        })
        .eq('id', attemptId);

    // 답변 일괄 저장
    final answersToInsert = answers
        .map(
          (a) => {
            'attempt_id': attemptId,
            'question_id': a['question_id'],
            'user_answer': a['user_answer'],
            'is_correct': a['is_correct'],
          },
        )
        .toList();

    await _supabaseService.client
        .from('ai_quiz_answers')
        .insert(answersToInsert);

    // 업데이트된 응시 기록 반환
    return await getAttemptWithDetails(attemptId);
  }

  /// 응시 기록 상세 조회
  Future<AiQuizAttempt> getAttemptWithDetails(int attemptId) async {
    final data = await _supabaseService.client
        .from('ai_quiz_attempts')
        .select('*, ai_quizzes(*), ai_quiz_answers(*)')
        .eq('id', attemptId)
        .single();

    return AiQuizAttempt.fromJson(data);
  }

  /// 최근 응시 기록 조회
  Future<List<AiQuizAttempt>> getRecentAttempts({int limit = 10}) async {
    final userId = _supabaseService.currentUser?.id;
    if (userId == null) return [];

    final data = await _supabaseService.client
        .from('ai_quiz_attempts')
        .select('*, ai_quizzes(*)')
        .eq('user_id', userId)
        .not('completed_at', 'is', null)
        .order('completed_at', ascending: false)
        .limit(limit);

    return (data as List).map((a) => AiQuizAttempt.fromJson(a)).toList();
  }

  /// 특정 퀴즈의 응시 기록 조회
  Future<List<AiQuizAttempt>> getQuizAttempts(int quizId) async {
    final userId = _supabaseService.currentUser?.id;
    if (userId == null) return [];

    final data = await _supabaseService.client
        .from('ai_quiz_attempts')
        .select('*, ai_quiz_answers(*)')
        .eq('quiz_id', quizId)
        .eq('user_id', userId)
        .order('started_at', ascending: false);

    return (data as List).map((a) => AiQuizAttempt.fromJson(a)).toList();
  }
}
