import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import '../services/supabase_service.dart';
import '../models/daily_study_stats.dart';
import '../constants/app_spacing.dart';
import '../widgets/daily_summary_card.dart';
import '../widgets/custom_header.dart';
import 'study_calendar_detail_screen.dart';

class StudyCalendarScreen extends StatefulWidget {
  const StudyCalendarScreen({super.key});

  @override
  State<StudyCalendarScreen> createState() => _StudyCalendarScreenState();
}

class _StudyCalendarScreenState extends State<StudyCalendarScreen> {
  final SupabaseService _supabaseService = SupabaseService.instance;

  FCalendarController<DateTime?>? _calendarController;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  Map<DateTime, DailyStudyStats> _monthlyStats = {};
  final Map<String, Map<DateTime, DailyStudyStats>> _monthlyStatsCache = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    final today = DateTime.now();
    _focusedDay = DateTime(today.year, today.month, today.day);
    _selectedDay = _focusedDay;
    _calendarController = FCalendarController.date(
      initialSelection: _selectedDay,
    );
    _loadMonthlyStats();
  }

  @override
  void dispose() {
    _calendarController?.dispose();
    super.dispose();
  }

  Future<void> _loadMonthlyStats({bool showLoading = true}) async {
    // Check cache first
    final cacheKey = '${_focusedDay.year}-${_focusedDay.month}';
    if (_monthlyStatsCache.containsKey(cacheKey)) {
      setState(() {
        _monthlyStats = _monthlyStatsCache[cacheKey]!;
        if (showLoading) {
          _isLoading = false;
        }
      });
      return;
    }

    if (showLoading) {
      setState(() {
        _isLoading = true;
      });
    }

    try {
      final stats = await _supabaseService.getMonthlyStudyStats(
        year: _focusedDay.year,
        month: _focusedDay.month,
      );

      // Cache the results
      _monthlyStatsCache[cacheKey] = stats;

      setState(() {
        _monthlyStats = stats;
        if (showLoading) {
          _isLoading = false;
        }
      });
    } catch (e) {
      debugPrint('Error loading monthly stats: $e');
      setState(() {
        if (showLoading) {
          _isLoading = false;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = FTheme.of(context);

    return Scaffold(
      backgroundColor: theme.colors.background,
      body: Column(
        children: [
          CustomHeader(
            title: const Text('학습 캘린더'),
            withBack: true,
          ),
          Expanded(
            child: _isLoading || _calendarController == null
                ? const Center(child: FCircularProgress())
                : SingleChildScrollView(
                    padding: AppSpacing.screenPadding,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // 1. Monthly Statistics (moved to top)
                        FCard(
                          child: _buildMonthlyStatistics(theme),
                        ),
                        const SizedBox(height: 16),

                        // 2. Calendar
                        Center(
                          child: FCalendar(
                            controller: _calendarController!,
                            start: DateTime(2024, 1, 1),
                            end: DateTime.now().add(const Duration(days: 365)),
                            today: DateTime.now(),
                            initialMonth: _focusedDay,
                            onPress: (date) {
                              setState(() {
                                _selectedDay = date;
                              });
                            },
                            onMonthChange: (date) {
                              setState(() {
                                _focusedDay = date;
                              });
                              _loadMonthlyStats(showLoading: false);
                            },
                            dayBuilder: (context, data, child) {
                              final normalizedDate = DateTime(
                                data.date.year,
                                data.date.month,
                                data.date.day,
                              );
                              final stats = _monthlyStats[normalizedDate];

                              // Custom day widget with number only (no '日')
                              final dayNumber = Text(
                                '${data.date.day}',
                                style: TextStyle(
                                  color: data.current
                                      ? (data.selected
                                          ? theme.colors.primaryForeground
                                          : theme.colors.foreground)
                                      : theme.colors.mutedForeground,
                                  fontWeight: data.today
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                ),
                              );

                              final dayWidget = Container(
                                alignment: Alignment.center,
                                decoration: data.selected
                                    ? BoxDecoration(
                                        color: theme.colors.primary,
                                        borderRadius: BorderRadius.circular(8),
                                      )
                                    : null,
                                child: dayNumber,
                              );

                              if (stats != null && stats.totalStudied > 0) {
                                final color = stats.getColorForCalendar();
                                if (color != Colors.transparent) {
                                  return Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      dayWidget,
                                      Positioned(
                                        bottom: 4,
                                        child: Container(
                                          decoration: BoxDecoration(
                                            color: color,
                                            shape: BoxShape.circle,
                                          ),
                                          width: 6,
                                          height: 6,
                                        ),
                                      ),
                                    ],
                                  );
                                }
                              }
                              return dayWidget;
                            },
                          ),
                        ),
                        const SizedBox(height: 16),

                        // 3. Summary Card
                        if (_selectedDay != null)
                          FCard(
                            child: DailySummaryCard(
                              date: _selectedDay!,
                              stats: _monthlyStats[DateTime(
                                _selectedDay!.year,
                                _selectedDay!.month,
                                _selectedDay!.day,
                              )],
                              showDetailButton: true,
                              onDetailPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        StudyCalendarDetailScreen(
                                      date: _selectedDay!,
                                    ),
                                  ),
                                );
                              },
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

  Widget _buildMonthlyStatistics(FThemeData theme) {
    int totalKanji = 0;
    int totalWords = 0;
    int totalCompleted = 0;
    int totalForgot = 0;
    int studyDays = 0;

    for (final stats in _monthlyStats.values) {
      if (stats.totalStudied > 0) {
        studyDays++;
        totalKanji += stats.kanjiStudied;
        totalWords += stats.wordsStudied;
        totalCompleted += stats.totalCompleted;
        totalForgot += stats.totalForgot;
      }
    }

    final successRate = (totalCompleted + totalForgot) > 0
        ? (totalCompleted / (totalCompleted + totalForgot) * 100)
        : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${_focusedDay.month}월 통계',
          style: theme.typography.lg.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        _buildMonthlyStatRow('학습일', '$studyDays일', theme),
        const SizedBox(height: 12),
        _buildMonthlyStatRow('한자', '$totalKanji개', theme),
        const SizedBox(height: 12),
        _buildMonthlyStatRow('단어', '$totalWords개', theme),
        const SizedBox(height: 12),
        _buildMonthlyStatRow(
          '성공률',
          '${successRate.toStringAsFixed(1)}%',
          theme,
        ),
      ],
    );
  }

  Widget _buildMonthlyStatRow(String label, String value, FThemeData theme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: theme.typography.base.copyWith(
            color: theme.colors.mutedForeground,
          ),
        ),
        Text(
          value,
          style: theme.typography.base.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
