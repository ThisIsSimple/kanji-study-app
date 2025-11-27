import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../models/ai_quiz.dart';
import '../models/ai_quiz_attempt.dart';
import '../services/ai_quiz_service.dart';
import '../services/flashcard_service.dart';
import '../services/gemini_service.dart';
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
      final flashcardHistory = await _flashcardService.getFlashcardHistory(limit: 3);

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
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(
        child: FCard(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: const [
                FCircularProgress(),
                SizedBox(height: 16),
                Text('AI가 퀴즈를 생성하고 있습니다...'),
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
          MaterialPageRoute(
            builder: (context) => AiQuizScreen(quiz: quiz),
          ),
        );

        if (result == true) {
          _loadData(); // 결과 갱신
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // 로딩 다이얼로그 닫기
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('퀴즈 생성 실패: $e')),
        );
      }
    }
  }

  void _showApiKeyDialog() {
    showDialog(
      context: context,
      builder: (context) => FDialog(
        title: const Text('API 키 필요'),
        body: const Text('AI 퀴즈를 사용하려면 Gemini API 키가 필요합니다.\n설정에서 API 키를 입력해주세요.'),
        actions: [
          FButton(
            style: FButtonStyle.outline(),
            onPress: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          FButton(
            onPress: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsAiScreen()),
              );
            },
            child: const Text('설정으로 이동'),
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

    return Scaffold(
      backgroundColor: theme.colors.background,
      body: Column(
        children: [
          const CustomHeader(title: Text('퀴즈')),
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
                          _buildSectionTitle(theme, 'AI 퀴즈', PhosphorIconsRegular.brain),
                          const SizedBox(height: 12),
                          _buildQuizTypeGrid(theme),
                          const SizedBox(height: 24),

                          // 최근 퀴즈 기록
                          if (_recentAttempts.isNotEmpty) ...[
                            _buildSectionTitle(theme, '최근 퀴즈 기록', PhosphorIconsRegular.chartBar),
                            const SizedBox(height: 12),
                            _buildRecentAttempts(theme),
                            const SizedBox(height: 24),
                          ],

                          // 플래시카드 섹션
                          _buildSectionTitle(theme, '플래시카드', PhosphorIconsRegular.cards),
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
      childAspectRatio: 1.3,
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
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, size: 28, color: color),
              ),
              const SizedBox(height: 12),
              Text(
                type.displayName,
                style: theme.typography.base.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                type == AiQuizType.jpToKr
                    ? '뜻 맞추기'
                    : type == AiQuizType.krToJp
                        ? '단어 맞추기'
                        : type == AiQuizType.kanjiReading
                            ? '후리가나'
                            : '문장 완성',
                style: theme.typography.xs.copyWith(
                  color: theme.colors.mutedForeground,
                ),
              ),
            ],
          ),
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

          return ListTile(
            leading: CircleAvatar(
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
              quiz?.title ?? '퀴즈',
              style: theme.typography.sm.copyWith(fontWeight: FontWeight.w500),
            ),
            subtitle: Text(
              '${attempt.correctCount ?? 0}/${quiz?.questionCount ?? 0} 정답',
              style: theme.typography.xs.copyWith(
                color: theme.colors.mutedForeground,
              ),
            ),
            trailing: Text(
              _formatDate(attempt.completedAt ?? attempt.startedAt),
              style: theme.typography.xs.copyWith(
                color: theme.colors.mutedForeground,
              ),
            ),
            onTap: () async {
              // 같은 퀴즈 다시 풀기
              if (quiz != null) {
                final fullQuiz = await _aiQuizService.getQuizWithQuestions(quiz.id);
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
                title: '단어 학습',
                icon: PhosphorIconsRegular.bookOpen,
                color: Colors.indigo,
                onTap: () => _startFlashcard('word'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildFlashcardButton(
                theme,
                title: '한자 학습',
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

                return ListTile(
                  leading: Icon(
                    itemType == 'word'
                        ? PhosphorIconsRegular.bookOpen
                        : PhosphorIconsRegular.translate,
                    color: theme.colors.primary,
                  ),
                  title: Text(
                    itemType == 'word' ? '단어 플래시카드' : '한자 플래시카드',
                    style: theme.typography.sm.copyWith(fontWeight: FontWeight.w500),
                  ),
                  subtitle: Text(
                    '$correctCount/$totalCount 정답',
                    style: theme.typography.xs.copyWith(
                      color: theme.colors.mutedForeground,
                    ),
                  ),
                  trailing: Text(
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
        child: Padding(
          padding: const EdgeInsets.all(16),
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
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays == 0) {
      return '오늘';
    } else if (diff.inDays == 1) {
      return '어제';
    } else if (diff.inDays < 7) {
      return '${diff.inDays}일 전';
    } else {
      return '${date.month}/${date.day}';
    }
  }
}

