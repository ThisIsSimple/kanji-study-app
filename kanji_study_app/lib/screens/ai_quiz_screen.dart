import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/ai_quiz.dart';
import '../models/ai_quiz_attempt.dart';
import '../services/ai_quiz_service.dart';
import '../widgets/custom_header.dart';
import 'ai_quiz_result_screen.dart';

class AiQuizScreen extends StatefulWidget {
  final AiQuiz quiz;

  const AiQuizScreen({super.key, required this.quiz});

  @override
  State<AiQuizScreen> createState() => _AiQuizScreenState();
}

class _AiQuizScreenState extends State<AiQuizScreen> {
  final AiQuizService _aiQuizService = AiQuizService.instance;

  late List<AiQuizQuestion> _questions;
  int _currentIndex = 0;
  final Map<int, String?> _answers = {}; // questionId -> userAnswer
  AiQuizAttempt? _attempt;
  bool _isLoading = true;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _initQuiz();
  }

  Future<void> _initQuiz() async {
    try {
      // 문제 목록 설정
      _questions = widget.quiz.questions ?? [];

      if (_questions.isEmpty) {
        // 문제가 없으면 로드
        final fullQuiz = await _aiQuizService.getQuizWithQuestions(widget.quiz.id);
        _questions = fullQuiz.questions ?? [];
      }

      // 응시 시작
      _attempt = await _aiQuizService.startAttempt(widget.quiz.id);

      setState(() => _isLoading = false);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('퀴즈 로드 실패: $e')),
        );
        Navigator.pop(context);
      }
    }
  }

  void _selectAnswer(String answer) {
    if (_questions.isEmpty) return;

    setState(() {
      _answers[_questions[_currentIndex].id] = answer;
    });
  }

  void _nextQuestion() {
    if (_currentIndex < _questions.length - 1) {
      setState(() => _currentIndex++);
    }
  }

  void _prevQuestion() {
    if (_currentIndex > 0) {
      setState(() => _currentIndex--);
    }
  }

  Future<void> _submitQuiz() async {
    if (_attempt == null) return;

    // 미응답 문제 확인
    final unanswered = _questions.where((q) => _answers[q.id] == null).length;
    if (unanswered > 0) {
      final shouldSubmit = await showDialog<bool>(
        context: context,
        builder: (context) => FDialog(
          title: const Text('제출 확인'),
          body: Text('아직 $unanswered개 문제에 응답하지 않았습니다.\n그래도 제출하시겠습니까?'),
          actions: [
            FButton(
              style: FButtonStyle.outline(),
              onPress: () => Navigator.pop(context, false),
              child: const Text('취소'),
            ),
            FButton(
              onPress: () => Navigator.pop(context, true),
              child: const Text('제출'),
            ),
          ],
        ),
      );

      if (shouldSubmit != true) return;
    }

    setState(() => _isSubmitting = true);

    try {
      // 답변 데이터 준비
      final answersData = _questions.map((q) {
        final userAnswer = _answers[q.id];
        final isCorrect = userAnswer == q.correctAnswer;
        return {
          'question_id': q.id,
          'user_answer': userAnswer,
          'is_correct': isCorrect,
        };
      }).toList();

      // 제출
      final result = await _aiQuizService.submitAttempt(
        attemptId: _attempt!.id,
        answers: answersData,
      );

      if (mounted) {
        // 결과 화면으로 이동
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => AiQuizResultScreen(
              attempt: result,
              questions: _questions,
              userAnswers: _answers,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('제출 실패: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = FTheme.of(context);

    if (_isLoading) {
      return Scaffold(
        backgroundColor: theme.colors.background,
        body: Column(
          children: [
            const CustomHeader(
              title: Text('퀴즈'),
              withBack: true,
            ),
            const Expanded(
              child: Center(child: FCircularProgress()),
            ),
          ],
        ),
      );
    }

    if (_questions.isEmpty) {
      return Scaffold(
        backgroundColor: theme.colors.background,
        body: Column(
          children: [
            const CustomHeader(
              title: Text('퀴즈'),
              withBack: true,
            ),
            const Expanded(
              child: Center(child: Text('문제가 없습니다.')),
            ),
          ],
        ),
      );
    }

    final currentQuestion = _questions[_currentIndex];
    final selectedAnswer = _answers[currentQuestion.id];

    return Scaffold(
      backgroundColor: theme.colors.background,
      body: Column(
        children: [
          // 헤더 - 중앙에 (1/10) 표시
          CustomHeader(
            title: Text(
              '(${_currentIndex + 1}/${_questions.length})',
              style: theme.typography.lg.copyWith(fontWeight: FontWeight.w600),
            ),
            titleAlign: HeaderTitleAlign.center,
            withBack: true,
          ),

          // 진행 바
          Container(
            height: 4,
            width: double.infinity,
            color: theme.colors.secondary,
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: (_currentIndex + 1) / _questions.length,
              child: Container(
                decoration: BoxDecoration(
                  color: theme.colors.primary,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ),

          // 문제 내용
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 문제 번호
                  Text(
                    '문제 ${_currentIndex + 1}',
                    style: theme.typography.sm.copyWith(
                      color: theme.colors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // 문제
                  FCard(
                    child: Center(
                      child: Text(
                        currentQuestion.question,
                        style: _getQuestionStyle(theme),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // 선택지
                  ...currentQuestion.options.asMap().entries.map((entry) {
                    final index = entry.key;
                    final option = entry.value;
                    final isSelected = selectedAnswer == option;
                    final optionLabel = String.fromCharCode(65 + index); // A, B, C, D

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: GestureDetector(
                        onTap: () => _selectAnswer(option),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? theme.colors.primary.withValues(alpha: 0.1)
                                : theme.colors.background,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected
                                  ? theme.colors.primary
                                  : theme.colors.border,
                              width: isSelected ? 2 : 1,
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              children: [
                                Container(
                                  width: 32,
                                  height: 32,
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? theme.colors.primary
                                        : theme.colors.secondary,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Center(
                                    child: Text(
                                      optionLabel,
                                      style: theme.typography.sm.copyWith(
                                        color: isSelected
                                            ? theme.colors.primaryForeground
                                            : theme.colors.foreground,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    option,
                                    style: _getOptionStyle(theme, option),
                                  ),
                                ),
                                if (isSelected)
                                  Icon(
                                    PhosphorIconsFill.checkCircle,
                                    color: theme.colors.primary,
                                    size: 20,
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),

          // 하단 버튼
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colors.background,
              border: Border(
                top: BorderSide(color: theme.colors.border),
              ),
            ),
            child: SafeArea(
              child: Row(
                children: [
                  // 이전 버튼
                  if (_currentIndex > 0)
                    Expanded(
                      child: FButton(
                        style: FButtonStyle.outline(),
                        onPress: _prevQuestion,
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(PhosphorIconsRegular.caretLeft, size: 16),
                            SizedBox(width: 4),
                            Text('이전'),
                          ],
                        ),
                      ),
                    )
                  else
                    const Spacer(),

                  const SizedBox(width: 12),

                  // 다음/제출 버튼
                  Expanded(
                    flex: 2,
                    child: FButton(
                      onPress: _isSubmitting
                          ? null
                          : _currentIndex < _questions.length - 1
                              ? _nextQuestion
                              : _submitQuiz,
                      child: _isSubmitting
                          ? const FCircularProgress()
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  _currentIndex < _questions.length - 1
                                      ? '다음'
                                      : '제출',
                                ),
                                const SizedBox(width: 4),
                                Icon(
                                  _currentIndex < _questions.length - 1
                                      ? PhosphorIconsRegular.caretRight
                                      : PhosphorIconsRegular.paperPlaneTilt,
                                  size: 16,
                                ),
                              ],
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  TextStyle _getQuestionStyle(FThemeData theme) {
    final question = _questions[_currentIndex].question;

    // 일본어 문자가 포함된 경우 일본어 폰트 사용
    if (_containsJapanese(question)) {
      return GoogleFonts.notoSerifJp(
        fontSize: 28,
        fontWeight: FontWeight.bold,
      );
    }

    return theme.typography.xl2.copyWith(fontWeight: FontWeight.bold);
  }

  TextStyle _getOptionStyle(FThemeData theme, String option) {
    if (_containsJapanese(option)) {
      return GoogleFonts.notoSerifJp(fontSize: 16);
    }
    return theme.typography.base;
  }

  bool _containsJapanese(String text) {
    return RegExp(r'[\u3040-\u309F\u30A0-\u30FF\u4E00-\u9FAF]').hasMatch(text);
  }
}
