import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/ai_quiz.dart';
import '../models/ai_quiz_attempt.dart';
import '../widgets/custom_header.dart';

class AiQuizResultScreen extends StatefulWidget {
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
  State<AiQuizResultScreen> createState() => _AiQuizResultScreenState();
}

class _AiQuizResultScreenState extends State<AiQuizResultScreen> {
  final Set<int> _expandedItems = {};

  void _toggleExpanded(int index) {
    setState(() {
      if (_expandedItems.contains(index)) {
        _expandedItems.remove(index);
      } else {
        _expandedItems.add(index);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = FTheme.of(context);
    final correctCount = widget.attempt.correctCount ?? 0;
    final totalCount = widget.questions.length;
    final percentage = totalCount > 0 ? (correctCount / totalCount * 100).round() : 0;

    return Scaffold(
      backgroundColor: theme.colors.background,
      body: Column(
        children: [
          CustomHeader(
            title: const Text('퀴즈 결과'),
            withBack: true,
          ),
          Expanded(
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

                  ...widget.questions.asMap().entries.map((entry) {
                    final index = entry.key;
                    final question = entry.value;
                    final userAnswer = widget.userAnswers[question.id];
                    final isCorrect = userAnswer == question.correctAnswer;
                    final isExpanded = _expandedItems.contains(index);

                    return _buildQuestionResult(
                      theme,
                      index: index,
                      question: question,
                      userAnswer: userAnswer,
                      isCorrect: isCorrect,
                      isExpanded: isExpanded,
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
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ],
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
      child: Column(
        children: [
          Icon(icon, size: 48, color: scoreColor),
          const SizedBox(height: 12),
          Text(
            message,
            style: theme.typography.lg.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 20),
          // 점수 원형 표시
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 100,
                height: 100,
                child: CircularProgressIndicator(
                  value: percentage / 100,
                  strokeWidth: 10,
                  backgroundColor: theme.colors.secondary,
                  valueColor: AlwaysStoppedAnimation(scoreColor),
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '$percentage%',
                    style: theme.typography.xl.copyWith(
                      fontWeight: FontWeight.bold,
                      color: scoreColor,
                    ),
                  ),
                  Text(
                    '$correctCount/$totalCount',
                    style: theme.typography.xs.copyWith(
                      color: theme.colors.mutedForeground,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          // 소요 시간
          if (widget.attempt.duration != null)
            Text(
              '소요 시간: ${_formatDuration(widget.attempt.duration!)}',
              style: theme.typography.sm.copyWith(
                color: theme.colors.mutedForeground,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildQuestionResult(
    FThemeData theme, {
    required int index,
    required AiQuizQuestion question,
    required String? userAnswer,
    required bool isCorrect,
    required bool isExpanded,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: FCard(
        child: Column(
          children: [
            // 헤더 (탭 가능)
            GestureDetector(
              onTap: () => _toggleExpanded(index),
              child: Row(
                children: [
                  // 정답/오답 아이콘
                  Container(
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
                  const SizedBox(width: 12),

                  // 문제 번호 및 내용 미리보기
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '문제 ${index + 1}',
                          style: theme.typography.sm.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          question.question,
                          style: _containsJapanese(question.question)
                              ? GoogleFonts.notoSerifJp(
                                  fontSize: 13,
                                  color: theme.colors.mutedForeground,
                                )
                              : theme.typography.sm.copyWith(
                                  color: theme.colors.mutedForeground,
                                ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),

                  // 확장 아이콘
                  AnimatedRotation(
                    duration: const Duration(milliseconds: 200),
                    turns: isExpanded ? 0.5 : 0,
                    child: Icon(
                      PhosphorIconsRegular.caretDown,
                      size: 20,
                      color: theme.colors.mutedForeground,
                    ),
                  ),
                ],
              ),
            ),

            // 확장된 내용
            AnimatedCrossFade(
              duration: const Duration(milliseconds: 200),
              crossFadeState: isExpanded
                  ? CrossFadeState.showSecond
                  : CrossFadeState.showFirst,
              firstChild: const SizedBox.shrink(),
              secondChild: Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const FDivider(),
                    const SizedBox(height: 12),

                    // 문제
                    Text(
                      question.question,
                      style: _containsJapanese(question.question)
                          ? GoogleFonts.notoSerifJp(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            )
                          : theme.typography.lg.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
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
            ),
          ],
        ),
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '$minutes분 $seconds초';
  }

  bool _containsJapanese(String text) {
    return RegExp(r'[\u3040-\u309F\u30A0-\u30FF\u4E00-\u9FAF]').hasMatch(text);
  }
}
