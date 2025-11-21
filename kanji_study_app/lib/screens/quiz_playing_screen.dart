import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:math';
import '../models/models.dart';
import '../services/supabase_service.dart';
import 'quiz_result_screen.dart';

class QuizPlayingScreen extends StatefulWidget {
  final QuizSet quizSet;
  final QuizAttempt attempt;

  const QuizPlayingScreen({
    super.key,
    required this.quizSet,
    required this.attempt,
  });

  @override
  State<QuizPlayingScreen> createState() => _QuizPlayingScreenState();
}

class _QuizPlayingScreenState extends State<QuizPlayingScreen> {
  final SupabaseService _supabaseService = SupabaseService.instance;
  final PageController _pageController = PageController();

  List<QuizQuestionData> _questions = [];
  List<String?> _userAnswers = [];
  int _currentQuestionIndex = 0;
  bool _isLoading = true;
  DateTime? _startTime;
  bool _showFeedback = false;
  String? _selectedAnswer;

  @override
  void initState() {
    super.initState();
    _startTime = DateTime.now();
    _loadQuizData();
  }

  Future<void> _loadQuizData() async {
    try {
      // Load kanji data for this quiz
      final allKanji = await _supabaseService.getAllKanji();
      final quizKanji = allKanji
          .where((kanji) => widget.quizSet.kanjiIds.contains(kanji['id']))
          .toList();

      // Generate questions
      final questions = await _generateQuestions(quizKanji);

      setState(() {
        _questions = questions;
        _userAnswers = List.filled(questions.length, null);
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('퀴즈 데이터를 불러오는데 실패했습니다: $e')));
        Navigator.pop(context);
      }
    }
  }

  Future<List<QuizQuestionData>> _generateQuestions(
    List<Map<String, dynamic>> kanjiData,
  ) async {
    final questions = <QuizQuestionData>[];
    final random = Random();

    for (int i = 0; i < kanjiData.length; i++) {
      final kanji = kanjiData[i];
      final questionTypes = [
        'meaning_to_kanji',
        'kanji_to_meaning',
        'kanji_to_reading',
      ];
      final questionType = questionTypes[random.nextInt(questionTypes.length)];

      QuizQuestionData question;

      switch (questionType) {
        case 'meaning_to_kanji':
          question = _generateMeaningToKanjiQuestion(kanji, kanjiData, i);
          break;
        case 'kanji_to_meaning':
          question = _generateKanjiToMeaningQuestion(kanji, kanjiData, i);
          break;
        case 'kanji_to_reading':
          question = _generateKanjiToReadingQuestion(kanji, kanjiData, i);
          break;
        default:
          question = _generateKanjiToMeaningQuestion(kanji, kanjiData, i);
      }

      questions.add(question);
    }

    return questions;
  }

  QuizQuestionData _generateMeaningToKanjiQuestion(
    Map<String, dynamic> targetKanji,
    List<Map<String, dynamic>> allKanji,
    int index,
  ) {
    final random = Random();
    final correctAnswer = targetKanji['character'] as String;
    final meaning = (targetKanji['meanings'] as List<dynamic>).first as String;

    // Generate wrong options
    final wrongOptions = <String>[];
    final otherKanji = List<Map<String, dynamic>>.from(allKanji)
      ..removeAt(index);

    while (wrongOptions.length < 3 && otherKanji.isNotEmpty) {
      final randomKanji = otherKanji[random.nextInt(otherKanji.length)];
      final character = randomKanji['character'] as String;
      if (character != correctAnswer && !wrongOptions.contains(character)) {
        wrongOptions.add(character);
      }
      otherKanji.remove(randomKanji);
    }

    final options = [correctAnswer, ...wrongOptions]..shuffle();

    return QuizQuestionData(
      questionType: 'meaning_to_kanji',
      questionText: '"$meaning"의 한자는?',
      correctAnswer: correctAnswer,
      options: options,
      orderIndex: index,
    );
  }

  QuizQuestionData _generateKanjiToMeaningQuestion(
    Map<String, dynamic> targetKanji,
    List<Map<String, dynamic>> allKanji,
    int index,
  ) {
    final random = Random();
    final character = targetKanji['character'] as String;
    final correctAnswer =
        (targetKanji['meanings'] as List<dynamic>).first as String;

    // Generate wrong options
    final wrongOptions = <String>[];
    final otherKanji = List<Map<String, dynamic>>.from(allKanji)
      ..removeAt(index);

    while (wrongOptions.length < 3 && otherKanji.isNotEmpty) {
      final randomKanji = otherKanji[random.nextInt(otherKanji.length)];
      final meanings = randomKanji['meanings'] as List<dynamic>;
      if (meanings.isNotEmpty) {
        final meaning = meanings.first as String;
        if (meaning != correctAnswer && !wrongOptions.contains(meaning)) {
          wrongOptions.add(meaning);
        }
      }
      otherKanji.remove(randomKanji);
    }

    final options = [correctAnswer, ...wrongOptions]..shuffle();

    return QuizQuestionData(
      questionType: 'kanji_to_meaning',
      questionText: character,
      correctAnswer: correctAnswer,
      options: options,
      orderIndex: index,
    );
  }

  QuizQuestionData _generateKanjiToReadingQuestion(
    Map<String, dynamic> targetKanji,
    List<Map<String, dynamic>> allKanji,
    int index,
  ) {
    final random = Random();
    final character = targetKanji['character'] as String;

    // Prefer Korean on reading, fallback to kun reading
    final koreanOnReadings =
        targetKanji['korean_on_readings'] as List<dynamic>?;
    final koreanKunReadings =
        targetKanji['korean_kun_readings'] as List<dynamic>?;

    String correctAnswer;
    if (koreanOnReadings != null && koreanOnReadings.isNotEmpty) {
      correctAnswer = koreanOnReadings.first as String;
    } else if (koreanKunReadings != null && koreanKunReadings.isNotEmpty) {
      correctAnswer = koreanKunReadings.first as String;
    } else {
      // Fallback to Japanese reading
      final onReadings = targetKanji['on_readings'] as List<dynamic>?;
      final kunReadings = targetKanji['kun_readings'] as List<dynamic>?;

      if (onReadings != null && onReadings.isNotEmpty) {
        correctAnswer = onReadings.first as String;
      } else if (kunReadings != null && kunReadings.isNotEmpty) {
        correctAnswer = kunReadings.first as String;
      } else {
        correctAnswer = '불명';
      }
    }

    // Generate wrong options
    final wrongOptions = <String>[];
    final otherKanji = List<Map<String, dynamic>>.from(allKanji)
      ..removeAt(index);

    while (wrongOptions.length < 3 && otherKanji.isNotEmpty) {
      final randomKanji = otherKanji[random.nextInt(otherKanji.length)];

      // Try Korean readings first
      final readings = [
        ...(randomKanji['korean_on_readings'] as List<dynamic>? ?? []),
        ...(randomKanji['korean_kun_readings'] as List<dynamic>? ?? []),
        ...(randomKanji['on_readings'] as List<dynamic>? ?? []),
        ...(randomKanji['kun_readings'] as List<dynamic>? ?? []),
      ];

      if (readings.isNotEmpty) {
        final reading = readings[random.nextInt(readings.length)] as String;
        if (reading != correctAnswer && !wrongOptions.contains(reading)) {
          wrongOptions.add(reading);
        }
      }
      otherKanji.remove(randomKanji);
    }

    final options = [correctAnswer, ...wrongOptions]..shuffle();

    return QuizQuestionData(
      questionType: 'kanji_to_reading',
      questionText: character,
      correctAnswer: correctAnswer,
      options: options,
      orderIndex: index,
    );
  }

  void _selectAnswer(String answer) {
    if (_showFeedback) return;

    setState(() {
      _selectedAnswer = answer;
      _userAnswers[_currentQuestionIndex] = answer;
      _showFeedback = true;
    });

    // Save answer to database
    _saveAnswer(answer);

    // Auto advance after 2 seconds
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        _nextQuestion();
      }
    });
  }

  Future<void> _saveAnswer(String answer) async {
    try {
      final question = _questions[_currentQuestionIndex];
      final isCorrect = answer == question.correctAnswer;

      final quizAnswer = QuizAnswer(
        id: 0, // Will be set by database
        attemptId: widget.attempt.id,
        questionId: _currentQuestionIndex + 1, // Use index + 1 as question ID
        userAnswer: answer,
        isCorrect: isCorrect,
        answeredAt: DateTime.now(),
      );

      await _supabaseService.saveQuizAnswer(quizAnswer);
    } catch (e) {
      // Handle error silently for now
      debugPrint('Error saving answer: $e');
    }
  }

  void _nextQuestion() {
    if (_currentQuestionIndex < _questions.length - 1) {
      setState(() {
        _currentQuestionIndex++;
        _showFeedback = false;
        _selectedAnswer = null;
      });
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _completeQuiz();
    }
  }

  void _previousQuestion() {
    if (_currentQuestionIndex > 0) {
      setState(() {
        _currentQuestionIndex--;
        _showFeedback = false;
        _selectedAnswer = _userAnswers[_currentQuestionIndex];
      });
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _completeQuiz() async {
    try {
      final endTime = DateTime.now();
      final timeTaken = endTime.difference(_startTime!).inSeconds;

      // Calculate score
      int correctCount = 0;
      for (int i = 0; i < _questions.length; i++) {
        if (_userAnswers[i] == _questions[i].correctAnswer) {
          correctCount++;
        }
      }

      // Complete the attempt
      await _supabaseService.completeQuizAttempt(
        attemptId: widget.attempt.id,
        score: correctCount,
        totalPoints: _questions.length,
        timeTakenSeconds: timeTaken,
      );

      if (mounted) {
        final result = await Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => QuizResultScreen(
              quizSet: widget.quizSet,
              attempt: widget.attempt.copyWith(
                score: correctCount,
                totalPoints: _questions.length,
                timeTakenSeconds: timeTaken,
                completedAt: endTime,
              ),
              questions: _questions,
              userAnswers: _userAnswers,
            ),
          ),
        );

        // Return result to previous screen
        if (!mounted) return;
        Navigator.pop(context, result);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('퀴즈를 완료하는데 실패했습니다: $e')));
      }
    }
  }

  Color _getOptionColor(FThemeData theme, String option) {
    if (!_showFeedback) {
      return _selectedAnswer == option
          ? theme.colors.primary.withValues(alpha: 0.1)
          : theme.colors.secondary;
    }

    final question = _questions[_currentQuestionIndex];
    if (option == question.correctAnswer) {
      return Colors.green.withValues(alpha: 0.2);
    } else if (option == _selectedAnswer && option != question.correctAnswer) {
      return Colors.red.withValues(alpha: 0.2);
    } else {
      return theme.colors.secondary;
    }
  }

  Color _getOptionBorderColor(FThemeData theme, String option) {
    if (!_showFeedback) {
      return _selectedAnswer == option
          ? theme.colors.primary
          : theme.colors.border;
    }

    final question = _questions[_currentQuestionIndex];
    if (option == question.correctAnswer) {
      return Colors.green;
    } else if (option == _selectedAnswer && option != question.correctAnswer) {
      return Colors.red;
    } else {
      return theme.colors.border;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = FTheme.of(context);

    if (_isLoading) {
      return FScaffold(
        header: const FHeader(title: Text('퀴즈 로딩 중...')),
        child: const Center(child: FCircularProgress()),
      );
    }

    return FScaffold(
      header: FHeader(
        title: Row(
          children: [
            Expanded(
              child: Text('${_currentQuestionIndex + 1}/${_questions.length}'),
            ),
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () {
                showFDialog(
                  context: context,
                  builder: (context, style, animation) => FDialog(
                    style: style,
                    animation: animation,
                    direction: Axis.horizontal,
                    title: const Text('퀴즈 종료'),
                    body: const Text('정말로 퀴즈를 종료하시겠습니까?\n진행 상황이 저장되지 않습니다.'),
                    actions: [
                      FButton(
                        style: FButtonStyle.outline(),
                        onPress: () => Navigator.pop(context),
                        child: const Text('계속하기'),
                      ),
                      FButton(
                        style: FButtonStyle.destructive(),
                        onPress: () {
                          Navigator.pop(context); // Close dialog
                          Navigator.pop(context); // Close quiz
                        },
                        child: const Text('종료'),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
      child: Column(
        children: [
          // Progress Bar
          Container(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                LinearProgressIndicator(
                  value: (_currentQuestionIndex + 1) / _questions.length,
                  backgroundColor: theme.colors.secondary,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    theme.colors.primary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${_currentQuestionIndex + 1}/${_questions.length}',
                  style: theme.typography.sm.copyWith(
                    color: theme.colors.mutedForeground,
                  ),
                ),
              ],
            ),
          ),

          // Question Content
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              onPageChanged: (index) {
                setState(() {
                  _currentQuestionIndex = index;
                  _selectedAnswer = _userAnswers[index];
                  _showFeedback = _userAnswers[index] != null;
                });
              },
              itemCount: _questions.length,
              itemBuilder: (context, index) {
                final currentQuestion = _questions[index];

                return Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      // Question Card
                      FCard(
                        child: Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Column(
                            children: [
                              Text(
                                currentQuestion.questionType ==
                                        'meaning_to_kanji'
                                    ? '다음 뜻의 한자를 고르세요'
                                    : currentQuestion.questionType ==
                                          'kanji_to_meaning'
                                    ? '다음 한자의 뜻을 고르세요'
                                    : '다음 한자의 읽기를 고르세요',
                                style: theme.typography.base.copyWith(
                                  color: theme.colors.mutedForeground,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                currentQuestion.questionText,
                                style:
                                    currentQuestion.questionType ==
                                        'meaning_to_kanji'
                                    ? theme.typography.xl2.copyWith(
                                        fontWeight: FontWeight.bold,
                                      )
                                    : GoogleFonts.notoSerifJp(
                                        fontSize: 48,
                                        fontWeight: FontWeight.bold,
                                      ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Options
                      Expanded(
                        child: GridView.builder(
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                crossAxisSpacing: 12,
                                mainAxisSpacing: 12,
                                childAspectRatio: 2.5,
                              ),
                          itemCount: currentQuestion.options.length,
                          itemBuilder: (context, optionIndex) {
                            final option = currentQuestion.options[optionIndex];

                            return GestureDetector(
                              onTap: _showFeedback
                                  ? null
                                  : () => _selectAnswer(option),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: _getOptionColor(theme, option),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: _getOptionBorderColor(theme, option),
                                    width: 2,
                                  ),
                                ),
                                child: Center(
                                  child: Text(
                                    option,
                                    style:
                                        currentQuestion.questionType ==
                                                'kanji_to_meaning' ||
                                            currentQuestion.questionType ==
                                                'kanji_to_reading'
                                        ? theme.typography.lg.copyWith(
                                            fontWeight: FontWeight.w600,
                                          )
                                        : GoogleFonts.notoSerifJp(
                                            fontSize: 24,
                                            fontWeight: FontWeight.bold,
                                          ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),

                      // Navigation Buttons
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          if (_currentQuestionIndex > 0)
                            Expanded(
                              child: OutlinedButton(
                                onPressed: _previousQuestion,
                                child: const Text('이전'),
                              ),
                            ),
                          if (_currentQuestionIndex > 0)
                            const SizedBox(width: 12),
                          Expanded(
                            child: FButton(
                              onPress: _showFeedback ? _nextQuestion : null,
                              child: Text(
                                _currentQuestionIndex == _questions.length - 1
                                    ? '결과 보기'
                                    : '다음',
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class QuizQuestionData {
  final String questionType;
  final String questionText;
  final String correctAnswer;
  final List<String> options;
  final int orderIndex;

  QuizQuestionData({
    required this.questionType,
    required this.questionText,
    required this.correctAnswer,
    required this.options,
    required this.orderIndex,
  });
}

extension QuizAttemptExtension on QuizAttempt {
  QuizAttempt copyWith({
    int? id,
    String? userId,
    int? quizSetId,
    DateTime? startedAt,
    DateTime? completedAt,
    int? score,
    int? totalPoints,
    int? timeTakenSeconds,
  }) {
    return QuizAttempt(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      quizSetId: quizSetId ?? this.quizSetId,
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
      score: score ?? this.score,
      totalPoints: totalPoints ?? this.totalPoints,
      timeTakenSeconds: timeTakenSeconds ?? this.timeTakenSeconds,
    );
  }
}
