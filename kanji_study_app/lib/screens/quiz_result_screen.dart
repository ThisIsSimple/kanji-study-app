import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/models.dart';
import 'quiz_playing_screen.dart';

class QuizResultScreen extends StatefulWidget {
  final QuizSet quizSet;
  final QuizAttempt attempt;
  final List<QuizQuestionData> questions;
  final List<String?> userAnswers;

  const QuizResultScreen({
    super.key,
    required this.quizSet,
    required this.attempt,
    required this.questions,
    required this.userAnswers,
  });

  @override
  State<QuizResultScreen> createState() => _QuizResultScreenState();
}

class _QuizResultScreenState extends State<QuizResultScreen>
    with TickerProviderStateMixin {
  late AnimationController _scoreAnimationController;
  late Animation<double> _scoreAnimation;
  late AnimationController _celebrationController;

  int get correctCount => widget.attempt.score ?? 0;
  int get totalCount => widget.attempt.totalPoints ?? widget.questions.length;
  double get percentage =>
      totalCount > 0 ? (correctCount / totalCount) * 100 : 0;

  @override
  void initState() {
    super.initState();

    _scoreAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _scoreAnimation = Tween<double>(begin: 0.0, end: percentage).animate(
      CurvedAnimation(
        parent: _scoreAnimationController,
        curve: Curves.easeOutBack,
      ),
    );

    _celebrationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    // Start animations
    Future.delayed(const Duration(milliseconds: 500), () {
      _scoreAnimationController.forward();

      if (percentage >= 80) {
        Future.delayed(const Duration(milliseconds: 1000), () {
          _celebrationController.forward();
        });
      }
    });
  }

  @override
  void dispose() {
    _scoreAnimationController.dispose();
    _celebrationController.dispose();
    super.dispose();
  }

  String get _performanceMessage {
    if (percentage >= 90) return '완벽해요! 🎉';
    if (percentage >= 80) return '훌륭해요! 👏';
    if (percentage >= 70) return '잘했어요! 👍';
    if (percentage >= 60) return '괜찮아요! 😊';
    return '다시 도전해보세요! 💪';
  }

  Color get _performanceColor {
    if (percentage >= 80) return Colors.green;
    if (percentage >= 60) return Colors.orange;
    return Colors.red;
  }

  List<Map<String, dynamic>> get _wrongAnswers {
    final wrong = <Map<String, dynamic>>[];
    for (int i = 0; i < widget.questions.length; i++) {
      if (widget.userAnswers[i] != widget.questions[i].correctAnswer) {
        wrong.add({
          'index': i,
          'question': widget.questions[i],
          'userAnswer': widget.userAnswers[i],
        });
      }
    }
    return wrong;
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '$minutes:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  void _retryQuiz() {
    Navigator.pushReplacementNamed(
      context,
      '/quiz-playing',
      arguments: {'quizSet': widget.quizSet},
    );
  }

  void _backToQuizList() {
    Navigator.pop(context, true); // Return true to indicate completion
  }

  Widget _buildScoreCircle(FThemeData theme) {
    return SizedBox(
      width: 200,
      height: 200,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Background circle
          Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: theme.colors.secondary.withValues(alpha: 0.3),
            ),
          ),

          // Animated progress circle
          AnimatedBuilder(
            animation: _scoreAnimation,
            builder: (context, child) {
              return CustomPaint(
                size: const Size(200, 200),
                painter: ScoreCirclePainter(
                  percentage: _scoreAnimation.value,
                  color: _performanceColor,
                  backgroundColor: theme.colors.secondary,
                ),
              );
            },
          ),

          // Score text
          AnimatedBuilder(
            animation: _scoreAnimation,
            builder: (context, child) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${_scoreAnimation.value.round()}%',
                    style: theme.typography.xl4.copyWith(
                      fontWeight: FontWeight.bold,
                      color: _performanceColor,
                    ),
                  ),
                  Text(
                    '$correctCount/$totalCount',
                    style: theme.typography.base.copyWith(
                      color: theme.colors.mutedForeground,
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    final theme = FTheme.of(context);

    return FCard(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(
              value,
              style: theme.typography.lg.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: theme.typography.xs.copyWith(
                color: theme.colors.mutedForeground,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWrongAnswerItem(Map<String, dynamic> wrongAnswer) {
    final theme = FTheme.of(context);
    final question = wrongAnswer['question'] as QuizQuestionData;
    final userAnswer = wrongAnswer['userAnswer'] as String?;

    return FCard(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Question
            Row(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.red),
                  ),
                  child: Center(
                    child: Text(
                      '${wrongAnswer['index'] + 1}',
                      style: theme.typography.xs.copyWith(
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    question.questionType == 'meaning_to_kanji'
                        ? '"${question.questionText.replaceAll('"의 한자는?', '').replaceAll('"', '')}"의 한자'
                        : question.questionType == 'kanji_to_meaning'
                        ? '${question.questionText}의 뜻'
                        : '${question.questionText}의 읽기',
                    style: theme.typography.base.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Question text (for non-meaning questions)
            if (question.questionType != 'meaning_to_kanji') ...[
              Center(
                child: Text(
                  question.questionText,
                  style: GoogleFonts.notoSerifJp(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],

            // Answers
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '정답',
                        style: theme.typography.xs.copyWith(
                          color: Colors.green,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.green.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.green),
                        ),
                        child: Text(
                          question.correctAnswer,
                          style: theme.typography.base.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '내 답',
                        style: theme.typography.xs.copyWith(
                          color: Colors.red,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.red.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.red),
                        ),
                        child: Text(
                          userAnswer ?? '무응답',
                          style: theme.typography.base.copyWith(
                            fontWeight: FontWeight.w600,
                            color: userAnswer == null
                                ? theme.colors.mutedForeground
                                : null,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = FTheme.of(context);

    return FScaffold(
      header: FHeader(
        title: Row(
          children: [
            const Expanded(child: Text('퀴즈 결과')),
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: _backToQuizList,
            ),
          ],
        ),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Score Section
            FCard(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  children: [
                    _buildScoreCircle(theme),
                    const SizedBox(height: 24),
                    Text(
                      _performanceMessage,
                      style: theme.typography.xl.copyWith(
                        fontWeight: FontWeight.bold,
                        color: _performanceColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.quizSet.title,
                      style: theme.typography.base.copyWith(
                        color: theme.colors.mutedForeground,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Statistics
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    '소요 시간',
                    widget.attempt.timeTakenSeconds != null
                        ? _formatTime(widget.attempt.timeTakenSeconds!)
                        : '0:00',
                    Icons.timer,
                    Colors.blue,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    '정답률',
                    '${percentage.round()}%',
                    Icons.check_circle,
                    _performanceColor,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    '틀린 문제',
                    '${_wrongAnswers.length}개',
                    Icons.error,
                    Colors.red,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Wrong Answers Review
            if (_wrongAnswers.isNotEmpty) ...[
              Row(
                children: [
                  Text(
                    '틀린 문제 복습',
                    style: theme.typography.lg.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${_wrongAnswers.length}개',
                    style: theme.typography.base.copyWith(
                      color: theme.colors.mutedForeground,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _wrongAnswers.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  return _buildWrongAnswerItem(_wrongAnswers[index]);
                },
              ),
              const SizedBox(height: 24),
            ],

            // Action Buttons
            Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  child: FButton(
                    onPress: _retryQuiz,
                    child: const Text('다시 도전하기'),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: _backToQuizList,
                    child: const Text('퀴즈 목록으로'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class ScoreCirclePainter extends CustomPainter {
  final double percentage;
  final Color color;
  final Color backgroundColor;

  ScoreCirclePainter({
    required this.percentage,
    required this.color,
    required this.backgroundColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 10;

    // Background circle
    final backgroundPaint = Paint()
      ..color = backgroundColor.withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10;

    canvas.drawCircle(center, radius, backgroundPaint);

    // Progress arc
    final progressPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round;

    final sweepAngle = (percentage / 100) * 2 * 3.14159;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -3.14159 / 2, // Start from top
      sweepAngle,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}
