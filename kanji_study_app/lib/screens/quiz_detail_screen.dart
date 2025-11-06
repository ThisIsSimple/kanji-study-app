import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/models.dart';
import '../services/supabase_service.dart';
import 'quiz_playing_screen.dart';

class QuizDetailScreen extends StatefulWidget {
  final QuizSet quizSet;

  const QuizDetailScreen({super.key, required this.quizSet});

  @override
  State<QuizDetailScreen> createState() => _QuizDetailScreenState();
}

class _QuizDetailScreenState extends State<QuizDetailScreen> {
  final SupabaseService _supabaseService = SupabaseService.instance;
  List<QuizAttempt> _previousAttempts = [];
  List<Map<String, dynamic>> _previewKanji = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      setState(() {
        _isLoading = true;
      });

      // Load previous attempts
      final attempts = await _supabaseService.getUserQuizAttempts(
        quizSetId: widget.quizSet.id,
      );

      // Load kanji preview (first 5 kanji)
      final allKanji = await _supabaseService.getAllKanji();
      final previewKanji = allKanji
          .where((kanji) => widget.quizSet.kanjiIds.contains(kanji['id']))
          .take(5)
          .toList();

      setState(() {
        _previousAttempts = attempts;
        _previewKanji = previewKanji;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('데이터를 불러오는데 실패했습니다: $e')));
      }
    }
  }

  void _startQuiz() async {
    try {
      // Start quiz attempt
      final attempt = await _supabaseService.startQuizAttempt(
        widget.quizSet.id,
      );

      if (attempt != null && mounted) {
        final result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                QuizPlayingScreen(quizSet: widget.quizSet, attempt: attempt),
          ),
        );

        // Refresh data if quiz was completed
        if (result == true) {
          _loadData();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('퀴즈를 시작할 수 없습니다: $e')));
      }
    }
  }

  Color _getDifficultyColor(FThemeData theme, int? difficulty) {
    switch (difficulty) {
      case 1:
        return Colors.green;
      case 2:
        return Colors.blue;
      case 3:
        return Colors.orange;
      case 4:
        return Colors.red;
      case 5:
        return Colors.purple;
      default:
        return theme.colors.mutedForeground;
    }
  }

  String _getDifficultyText(int? difficulty) {
    switch (difficulty) {
      case 1:
        return '초급';
      case 2:
        return '초중급';
      case 3:
        return '중급';
      case 4:
        return '중고급';
      case 5:
        return '고급';
      default:
        return '미설정';
    }
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

  @override
  Widget build(BuildContext context) {
    final theme = FTheme.of(context);

    return FScaffold(
      header: FHeader(title: Text(widget.quizSet.title)),
      child: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Quiz Info Card
                  FCard(
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  widget.quizSet.title,
                                  style: theme.typography.xl.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: _getDifficultyColor(
                                    theme,
                                    widget.quizSet.difficultyLevel,
                                  ).withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: _getDifficultyColor(
                                      theme,
                                      widget.quizSet.difficultyLevel,
                                    ),
                                    width: 1,
                                  ),
                                ),
                                child: Text(
                                  _getDifficultyText(
                                    widget.quizSet.difficultyLevel,
                                  ),
                                  style: theme.typography.sm.copyWith(
                                    color: _getDifficultyColor(
                                      theme,
                                      widget.quizSet.difficultyLevel,
                                    ),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          if (widget.quizSet.description != null) ...[
                            const SizedBox(height: 12),
                            Text(
                              widget.quizSet.description!,
                              style: theme.typography.base.copyWith(
                                color: theme.colors.mutedForeground,
                              ),
                            ),
                          ],
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Icon(
                                Icons.quiz,
                                size: 16,
                                color: theme.colors.mutedForeground,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${widget.quizSet.kanjiIds.length}문제',
                                style: theme.typography.sm.copyWith(
                                  color: theme.colors.mutedForeground,
                                ),
                              ),
                              if (widget.quizSet.category != null) ...[
                                const SizedBox(width: 16),
                                Icon(
                                  Icons.category,
                                  size: 16,
                                  color: theme.colors.mutedForeground,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  widget.quizSet.category!,
                                  style: theme.typography.sm.copyWith(
                                    color: theme.colors.mutedForeground,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Statistics
                  if (_previousAttempts.isNotEmpty) ...[
                    Text(
                      '나의 기록',
                      style: theme.typography.lg.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),

                    Row(
                      children: [
                        Expanded(
                          child: _buildStatCard(
                            '시도 횟수',
                            '${_previousAttempts.length}회',
                            Icons.play_arrow,
                            Colors.blue,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildStatCard(
                            '최고 점수',
                            '${_previousAttempts.map((a) => a.score ?? 0).reduce((a, b) => a > b ? a : b)}점',
                            Icons.star,
                            Colors.orange,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildStatCard(
                            '평균 점수',
                            '${(_previousAttempts.map((a) => a.score ?? 0).reduce((a, b) => a + b) / _previousAttempts.length).round()}점',
                            Icons.trending_up,
                            Colors.green,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Kanji Preview
                  if (_previewKanji.isNotEmpty) ...[
                    Text(
                      '포함된 한자 미리보기',
                      style: theme.typography.lg.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),

                    FCard(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: _previewKanji.map((kanji) {
                                return Column(
                                  children: [
                                    Text(
                                      kanji['character'],
                                      style: GoogleFonts.notoSerifJp(
                                        fontSize: 32,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      (kanji['meanings'] as List<dynamic>)
                                          .first,
                                      style: theme.typography.xs,
                                    ),
                                  ],
                                );
                              }).toList(),
                            ),
                            if (widget.quizSet.kanjiIds.length > 5) ...[
                              const SizedBox(height: 12),
                              Text(
                                '외 ${widget.quizSet.kanjiIds.length - 5}개',
                                style: theme.typography.sm.copyWith(
                                  color: theme.colors.mutedForeground,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Recent Attempts
                  if (_previousAttempts.isNotEmpty) ...[
                    Text(
                      '최근 시도',
                      style: theme.typography.lg.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),

                    FCard(
                      child: Column(
                        children: _previousAttempts.take(3).map((attempt) {
                          final completedAt = attempt.completedAt;
                          final score = attempt.score ?? 0;
                          final totalPoints =
                              attempt.totalPoints ??
                              widget.quizSet.kanjiIds.length;
                          final percentage = totalPoints > 0
                              ? (score / totalPoints * 100).round()
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
                              '$score/$totalPoints점',
                              style: theme.typography.base.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            subtitle: Text(
                              completedAt != null
                                  ? '${completedAt.month}/${completedAt.day} ${completedAt.hour}:${completedAt.minute.toString().padLeft(2, '0')}'
                                  : '진행 중',
                              style: theme.typography.sm.copyWith(
                                color: theme.colors.mutedForeground,
                              ),
                            ),
                            trailing: completedAt != null
                                ? Icon(
                                    Icons.check_circle,
                                    color: theme.colors.primary,
                                    size: 20,
                                  )
                                : Icon(
                                    Icons.hourglass_empty,
                                    color: theme.colors.mutedForeground,
                                    size: 20,
                                  ),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],

                  // Start Quiz Button
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: FButton(
                      onPress: _startQuiz,
                      child: const Text('퀴즈 시작'),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
