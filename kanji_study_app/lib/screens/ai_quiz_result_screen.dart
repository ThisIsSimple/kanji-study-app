import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/ai_quiz.dart';
import '../models/ai_quiz_attempt.dart';

class AiQuizResultScreen extends StatelessWidget {
  final AiQuizAttempt attempt;
  final List<AiQuizQuestion> questions;
  final Map<int, String?> userAnswers;

  const AiQuizResultScreen({
    super.key,
    required this.attempt,
    required this.questions,
    required this.userAnswers,
  });

  @override
  Widget build(BuildContext context) {
    final theme = FTheme.of(context);
    final correctCount = attempt.correctCount ?? 0;
    final totalCount = questions.length;
    final percentage = totalCount > 0 ? (correctCount / totalCount * 100).round() : 0;

    return FScaffold(
      header: FHeader(
        title: const Text('퀴즈 결과'),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // 점수 카드
            _buildScoreCard(theme, correctCount, totalCount, percentage),
            const SizedBox(height: 24),

            // 문제별 결과
            Text(
              '문제별 결과',
              style: theme.typography.lg.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            ...questions.asMap().entries.map((entry) {
              final index = entry.key;
              final question = entry.value;
              final userAnswer = userAnswers[question.id];
              final isCorrect = userAnswer == question.correctAnswer;

              return _buildQuestionResult(
                theme,
                index: index,
                question: question,
                userAnswer: userAnswer,
                isCorrect: isCorrect,
              );
            }),

            const SizedBox(height: 24),

            // 버튼들
            Row(
              children: [
                Expanded(
                  child: FButton(
                    style: FButtonStyle.outline(),
                    onPress: () => Navigator.of(context).popUntil((route) => route.isFirst),
                    child: const Text('홈으로'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FButton(
                    onPress: () {
                      Navigator.pop(context, true); // 다시 풀기
                    },
                    child: const Text('다시 풀기'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScoreCard(
    FThemeData theme,
    int correctCount,
    int totalCount,
    int percentage,
  ) {
    Color scoreColor;
    String message;
    IconData icon;

    if (percentage >= 90) {
      scoreColor = Colors.green;
      message = '훌륭합니다! 🎉';
      icon = PhosphorIconsFill.trophy;
    } else if (percentage >= 70) {
      scoreColor = Colors.blue;
      message = '잘했어요! 👏';
      icon = PhosphorIconsFill.thumbsUp;
    } else if (percentage >= 50) {
      scoreColor = Colors.orange;
      message = '조금 더 노력해봐요! 💪';
      icon = PhosphorIconsFill.lightbulb;
    } else {
      scoreColor = Colors.red;
      message = '다시 도전해보세요! 📚';
      icon = PhosphorIconsFill.bookOpen;
    }

    return FCard(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(icon, size: 48, color: scoreColor),
            const SizedBox(height: 16),
            Text(
              message,
              style: theme.typography.lg.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 24),

            // 점수 원형 표시
            Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 120,
                  height: 120,
                  child: CircularProgressIndicator(
                    value: percentage / 100,
                    strokeWidth: 12,
                    backgroundColor: theme.colors.secondary,
                    valueColor: AlwaysStoppedAnimation(scoreColor),
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '$percentage%',
                      style: theme.typography.xl2.copyWith(
                        fontWeight: FontWeight.bold,
                        color: scoreColor,
                      ),
                    ),
                    Text(
                      '$correctCount/$totalCount',
                      style: theme.typography.sm.copyWith(
                        color: theme.colors.mutedForeground,
                      ),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 16),

            // 소요 시간
            if (attempt.duration != null)
              Text(
                '소요 시간: ${_formatDuration(attempt.duration!)}',
                style: theme.typography.sm.copyWith(
                  color: theme.colors.mutedForeground,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuestionResult(
    FThemeData theme, {
    required int index,
    required AiQuizQuestion question,
    required String? userAnswer,
    required bool isCorrect,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: FCard(
        child: ExpansionTile(
          leading: Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: isCorrect
                  ? Colors.green.withValues(alpha: 0.1)
                  : Colors.red.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isCorrect ? PhosphorIconsFill.check : PhosphorIconsFill.x,
              size: 16,
              color: isCorrect ? Colors.green : Colors.red,
            ),
          ),
          title: Text(
            '문제 ${index + 1}',
            style: theme.typography.sm.copyWith(fontWeight: FontWeight.w600),
          ),
          subtitle: Text(
            question.question,
            style: _containsJapanese(question.question)
                ? GoogleFonts.notoSerifJp(fontSize: 14)
                : theme.typography.sm,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 문제
                  Text(
                    question.question,
                    style: _containsJapanese(question.question)
                        ? GoogleFonts.notoSerifJp(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          )
                        : theme.typography.lg.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),

                  // 사용자 답변
                  Row(
                    children: [
                      Icon(
                        isCorrect ? PhosphorIconsFill.check : PhosphorIconsFill.x,
                        size: 16,
                        color: isCorrect ? Colors.green : Colors.red,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '내 답변: ',
                        style: theme.typography.sm.copyWith(
                          color: theme.colors.mutedForeground,
                        ),
                      ),
                      Expanded(
                        child: Text(
                          userAnswer ?? '응답 없음',
                          style: theme.typography.sm.copyWith(
                            color: isCorrect ? Colors.green : Colors.red,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),

                  // 오답인 경우 정답 표시
                  if (!isCorrect) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(
                          PhosphorIconsFill.checkCircle,
                          size: 16,
                          color: Colors.green,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '정답: ',
                          style: theme.typography.sm.copyWith(
                            color: theme.colors.mutedForeground,
                          ),
                        ),
                        Expanded(
                          child: Text(
                            question.correctAnswer,
                            style: theme.typography.sm.copyWith(
                              color: Colors.green,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],

                  // 해설
                  if (question.explanation != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: theme.colors.secondary,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            PhosphorIconsRegular.lightbulb,
                            size: 16,
                            color: theme.colors.mutedForeground,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              question.explanation!,
                              style: theme.typography.sm.copyWith(
                                color: theme.colors.mutedForeground,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes}분 ${seconds}초';
  }

  bool _containsJapanese(String text) {
    return RegExp(r'[\u3040-\u309F\u30A0-\u30FF\u4E00-\u9FAF]').hasMatch(text);
  }
}

