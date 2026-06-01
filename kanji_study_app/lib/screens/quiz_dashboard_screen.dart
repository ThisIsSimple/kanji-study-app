import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../l10n/localization_extensions.dart';
import '../models/ai_quiz.dart';
import '../models/ai_quiz_attempt.dart';
import '../services/ai_quiz_service.dart';
import '../services/flashcard_service.dart';
import '../services/gemini_service.dart';
import '../widgets/app_toast.dart';
import '../widgets/custom_header.dart';
import 'ai_quiz_screen.dart';
import 'settings_ai_screen.dart';
import 'words_screen.dart';
import 'kanji_screen.dart';

class QuizDashboardScreen extends StatefulWidget {
  const QuizDashboardScreen({super.key});

  @override
  State<QuizDashboardScreen> createState() => _QuizDashboardScreenState();
}

class _QuizDashboardScreenState extends State<QuizDashboardScreen> {
  final AiQuizService _aiQuizService = AiQuizService.instance;
  final FlashcardService _flashcardService = FlashcardService.instance;
  final GeminiService _geminiService = GeminiService.instance;

  List<AiQuizAttempt> _recentAttempts = [];
  List<Map<String, dynamic>> _flashcardHistory = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      final attempts = await _aiQuizService.getRecentAttempts(limit: 5);
      final flashcardHistory = await _flashcardService.getFlashcardHistory(
        limit: 3,
      );

      if (mounted) {
        setState(() {
          _recentAttempts = attempts;
          _flashcardHistory = flashcardHistory;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _startQuiz(AiQuizType quizType) async {
    if (!_geminiService.isInitialized) {
      _showApiKeyDialog();
      return;
    }

    // 퀴즈 생성 중 로딩 표시
    final l10n = context.l10n;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(
        child: FCard(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const FCircularProgress(),
                const SizedBox(height: 16),
                Text(l10n.generatingQuiz),
              ],
            ),
          ),
        ),
      ),
    );

    try {
      final quiz = await _aiQuizService.generateQuiz(
        quizType: quizType,
        jlptLevel: 3, // 기본값 N3
        questionCount: 10,
      );

      if (mounted) {
        Navigator.pop(context); // 로딩 다이얼로그 닫기

        final result = await Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => AiQuizScreen(quiz: quiz)),
        );

        if (result == true) {
          _loadData(); // 결과 갱신
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // 로딩 다이얼로그 닫기
        showAppToast(
          context,
          message: l10n.quizGenerateFailed(e.toString()),
          type: AppToastType.error,
        );
      }
    }
  }

  void _showApiKeyDialog() {
    final l10n = context.l10n;
    showFDialog(
      context: context,
      builder: (context, _, animation) => FDialog(
        animation: animation,
        direction: Axis.horizontal,
        title: Text(l10n.apiKeyRequired),
        body: Text(l10n.apiKeyRequiredBody),
        actions: [
          FButton(
            variant: FButtonVariant.outline,
            onPress: () => Navigator.pop(context),
            child: Text(l10n.cancel),
          ),
          FButton(
            onPress: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SettingsAiScreen(),
                ),
              );
            },
            child: Text(l10n.goToSettings),
          ),
        ],
      ),
    );
  }

  void _startFlashcard(String itemType) {
    // 단어/한자 화면으로 이동 (해당 화면에서 플래시카드 학습 시작 가능)
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => itemType == 'word'
            ? const WordsScreen(showMeanings: true, onMeaningsToggle: null)
            : const KanjiScreen(showMeanings: true, onMeaningsToggle: null),
      ),
    ).then((_) => _loadData());
  }

  @override
  Widget build(BuildContext context) {
    final theme = FTheme.of(context);
    final l10n = context.l10n;

    return Scaffold(
      backgroundColor: theme.colors.background,
      body: Column(
        children: [
          CustomHeader(title: Text(l10n.quiz)),
          Expanded(
            child: _isLoading
                ? const Center(child: FCircularProgress())
                : RefreshIndicator(
                    onRefresh: _loadData,
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // AI 퀴즈 섹션
                          _buildSectionTitle(
                            theme,
                            l10n.aiQuiz,
                            PhosphorIconsRegular.brain,
                          ),
                          const SizedBox(height: 12),
                          _buildQuizTypeGrid(theme),
                          const SizedBox(height: 24),

                          // 최근 퀴즈 기록
                          if (_recentAttempts.isNotEmpty) ...[
                            _buildSectionTitle(
                              theme,
                              l10n.recentQuizRecords,
                              PhosphorIconsRegular.chartBar,
                            ),
                            const SizedBox(height: 12),
                            _buildRecentAttempts(theme),
                            const SizedBox(height: 24),
                          ],

                          // 플래시카드 섹션
                          _buildSectionTitle(
                            theme,
                            l10n.flashcardStudy,
                            PhosphorIconsRegular.cards,
                          ),
                          const SizedBox(height: 12),
                          _buildFlashcardSection(theme),
                        ],
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(FThemeData theme, String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 20, color: theme.colors.primary),
        const SizedBox(width: 8),
        Text(
          title,
          style: theme.typography.lg.copyWith(fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildQuizTypeGrid(FThemeData theme) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.0,
      children: [
        _buildQuizTypeCard(
          theme,
          type: AiQuizType.jpToKr,
          icon: PhosphorIconsRegular.translate,
          color: Colors.blue,
        ),
        _buildQuizTypeCard(
          theme,
          type: AiQuizType.krToJp,
          icon: PhosphorIconsRegular.pencilSimple,
          color: Colors.green,
        ),
        _buildQuizTypeCard(
          theme,
          type: AiQuizType.kanjiReading,
          icon: PhosphorIconsRegular.textAa,
          color: Colors.orange,
        ),
        _buildQuizTypeCard(
          theme,
          type: AiQuizType.fillBlank,
          icon: PhosphorIconsRegular.textbox,
          color: Colors.purple,
        ),
      ],
    );
  }

  Widget _buildQuizTypeCard(
    FThemeData theme, {
    required AiQuizType type,
    required IconData icon,
    required Color color,
  }) {
    return GestureDetector(
      onTap: () => _startQuiz(type),
      child: FCard(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 24, color: color),
            ),
            const SizedBox(height: 8),
            Text(
              _quizTypeTitle(type),
              style: theme.typography.md.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 2),
            Text(
              _quizTypeSubtitle(type),
              style: theme.typography.xs.copyWith(
                color: theme.colors.mutedForeground,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentAttempts(FThemeData theme) {
    return FCard(
      child: Column(
        children: _recentAttempts.map((attempt) {
          final quiz = attempt.quiz;
          final percentage = quiz != null && attempt.correctCount != null
              ? (attempt.correctCount! / quiz.questionCount * 100).round()
              : 0;

          return FItem(
            prefix: CircleAvatar(
              backgroundColor: percentage >= 80
                  ? Colors.green.withValues(alpha: 0.1)
                  : percentage >= 60
                  ? Colors.orange.withValues(alpha: 0.1)
                  : Colors.red.withValues(alpha: 0.1),
              child: Text(
                '$percentage%',
                style: theme.typography.xs.copyWith(
                  fontWeight: FontWeight.bold,
                  color: percentage >= 80
                      ? Colors.green
                      : percentage >= 60
                      ? Colors.orange
                      : Colors.red,
                ),
              ),
            ),
            title: Text(
              quiz?.title ?? context.l10n.quiz,
              style: theme.typography.sm.copyWith(fontWeight: FontWeight.w500),
            ),
            subtitle: Text(
              context.l10n.correctAnswerCount(
                attempt.correctCount ?? 0,
                quiz?.questionCount ?? 0,
              ),
              style: theme.typography.xs.copyWith(
                color: theme.colors.mutedForeground,
              ),
            ),
            details: Text(
              _formatDate(attempt.completedAt ?? attempt.startedAt),
              style: theme.typography.xs.copyWith(
                color: theme.colors.mutedForeground,
              ),
            ),
            onPress: () async {
              // 같은 퀴즈 다시 풀기
              if (quiz != null) {
                final fullQuiz = await _aiQuizService.getQuizWithQuestions(
                  quiz.id,
                );
                if (mounted) {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AiQuizScreen(quiz: fullQuiz),
                    ),
                  );
                  if (result == true) _loadData();
                }
              }
            },
          );
        }).toList(),
      ),
    );
  }

  Widget _buildFlashcardSection(FThemeData theme) {
    return Column(
      children: [
        // 플래시카드 시작 버튼들
        Row(
          children: [
            Expanded(
              child: _buildFlashcardButton(
                theme,
                title: context.l10n.wordStudy,
                icon: PhosphorIconsRegular.bookOpen,
                color: Colors.indigo,
                onTap: () => _startFlashcard('word'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildFlashcardButton(
                theme,
                title: context.l10n.kanjiStudy,
                icon: PhosphorIconsRegular.translate,
                color: Colors.teal,
                onTap: () => _startFlashcard('kanji'),
              ),
            ),
          ],
        ),

        // 최근 플래시카드 기록
        if (_flashcardHistory.isNotEmpty) ...[
          const SizedBox(height: 12),
          FCard(
            child: Column(
              children: _flashcardHistory.map((session) {
                final itemType = session['item_type'] as String? ?? 'word';
                final totalCount = session['total_count'] as int? ?? 0;
                final correctCount = session['correct_count'] as int? ?? 0;
                final startedAt = session['started_at'] != null
                    ? DateTime.parse(session['started_at'] as String)
                    : DateTime.now();

                return FItem(
                  prefix: Icon(
                    itemType == 'word'
                        ? PhosphorIconsRegular.bookOpen
                        : PhosphorIconsRegular.translate,
                    color: theme.colors.primary,
                  ),
                  title: Text(
                    itemType == 'word'
                        ? context.l10n.wordFlashcards
                        : context.l10n.kanjiFlashcards,
                    style: theme.typography.sm.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  subtitle: Text(
                    context.l10n.correctAnswerCount(correctCount, totalCount),
                    style: theme.typography.xs.copyWith(
                      color: theme.colors.mutedForeground,
                    ),
                  ),
                  details: Text(
                    _formatDate(startedAt),
                    style: theme.typography.xs.copyWith(
                      color: theme.colors.mutedForeground,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildFlashcardButton(
    FThemeData theme, {
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: FCard(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(width: 8),
            Text(
              title,
              style: theme.typography.sm.copyWith(fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    final l10n = context.l10n;

    if (diff.inDays == 0) {
      return l10n.todayRelative;
    } else if (diff.inDays == 1) {
      return l10n.yesterdayRelative;
    } else if (diff.inDays < 7) {
      return l10n.daysAgo(diff.inDays);
    } else {
      return '${date.month}/${date.day}';
    }
  }

  String _quizTypeTitle(AiQuizType type) {
    final l10n = context.l10n;
    return switch (type) {
      AiQuizType.jpToKr => l10n.jpToMeaningQuizTitle,
      AiQuizType.krToJp => l10n.meaningToJpQuizTitle,
      AiQuizType.kanjiReading => l10n.furigana,
      AiQuizType.fillBlank => l10n.fillBlank,
    };
  }

  String _quizTypeSubtitle(AiQuizType type) {
    final l10n = context.l10n;
    return switch (type) {
      AiQuizType.jpToKr => l10n.meaningQuiz,
      AiQuizType.krToJp => l10n.wordQuiz,
      AiQuizType.kanjiReading => l10n.furigana,
      AiQuizType.fillBlank => l10n.fillBlank,
    };
  }
}
