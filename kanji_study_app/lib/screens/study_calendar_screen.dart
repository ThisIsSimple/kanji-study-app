import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:table_calendar/table_calendar.dart';
import '../services/supabase_service.dart';
import '../models/daily_study_stats.dart';
import '../constants/app_spacing.dart';
import '../widgets/daily_summary_card.dart';
import 'study_calendar_detail_screen.dart';

class StudyCalendarScreen extends StatefulWidget {
  const StudyCalendarScreen({super.key});

  @override
  State<StudyCalendarScreen> createState() => _StudyCalendarScreenState();
}

class _StudyCalendarScreenState extends State<StudyCalendarScreen> {
  final SupabaseService _supabaseService = SupabaseService.instance;

  final CalendarFormat _calendarFormat = CalendarFormat.month;
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
    _loadMonthlyStats();
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

  List<DailyStudyStats> _getEventsForDay(DateTime day) {
    final normalizedDay = DateTime(day.year, day.month, day.day);
    final stats = _monthlyStats[normalizedDay];
    return stats != null ? [stats] : [];
  }

  @override
  Widget build(BuildContext context) {
    final theme = FTheme.of(context);

    return FScaffold(
      header: FHeader.nested(
        title: const Text('학습 캘린더'),
        prefixes: [
          FHeaderAction.back(onPress: () => Navigator.of(context).pop()),
        ],
      ),
      child: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: AppSpacing.screenPadding,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Calendar Card
                  FCard(
                    child: Padding(
                      padding: AppSpacing.cardPadding,
                      child: TableCalendar<DailyStudyStats>(
                        locale: 'ja_JP',
                        firstDay: DateTime(2024, 1, 1),
                        lastDay: DateTime.now().add(const Duration(days: 365)),
                        focusedDay: _focusedDay,
                        calendarFormat: _calendarFormat,
                        selectedDayPredicate: (day) {
                          return isSameDay(_selectedDay, day);
                        },
                        eventLoader: _getEventsForDay,
                        startingDayOfWeek: StartingDayOfWeek.monday,
                        availableGestures: AvailableGestures.none,
                        calendarStyle: CalendarStyle(
                          outsideDaysVisible: false,
                          cellMargin: const EdgeInsets.all(4),
                          weekendTextStyle: TextStyle(
                            color: theme.colors.foreground,
                          ),
                          todayTextStyle: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                          todayDecoration: BoxDecoration(
                            color: theme.colors.primary.withValues(alpha: 0.7),
                            shape: BoxShape.circle,
                          ),
                          selectedTextStyle: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                          selectedDecoration: BoxDecoration(
                            color: theme.colors.primary,
                            shape: BoxShape.circle,
                          ),
                          markerDecoration: BoxDecoration(
                            color: theme.colors.secondary,
                            shape: BoxShape.circle,
                          ),
                          defaultTextStyle: const TextStyle(fontSize: 14),
                        ),
                        headerStyle: HeaderStyle(
                          formatButtonVisible: false, // formatButton 숨기기
                          titleCentered: true,
                          formatButtonShowsNext: false,
                          leftChevronVisible: true,
                          rightChevronVisible: true,
                          headerMargin: const EdgeInsets.only(bottom: 8),
                          headerPadding: const EdgeInsets.symmetric(
                            vertical: 8,
                          ),
                          titleTextStyle: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        daysOfWeekStyle: const DaysOfWeekStyle(
                          weekdayStyle: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                          weekendStyle: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        onDaySelected: (selectedDay, focusedDay) {
                          if (!isSameDay(_selectedDay, selectedDay)) {
                            setState(() {
                              _selectedDay = selectedDay;
                              _focusedDay = focusedDay;
                            });

                            // Navigate to detail screen for any selected date
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => StudyCalendarDetailScreen(
                                  date: selectedDay,
                                ),
                              ),
                            );
                          }
                        },
                        availableCalendarFormats: const {
                          CalendarFormat.month: 'Month',
                        },
                        onFormatChanged: (format) {
                          // Format change disabled
                        },
                        onPageChanged: (focusedDay) {
                          setState(() {
                            _focusedDay = focusedDay;
                          });
                          _loadMonthlyStats(showLoading: false);
                        },
                        calendarBuilders: CalendarBuilders(
                          markerBuilder: (context, day, events) {
                            if (events.isEmpty) return null;

                            final stats = events.first;
                            final color = stats.getColorForCalendar();

                            if (color == Colors.transparent) return null;

                            return Positioned(
                              bottom: 1,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: color,
                                  shape: BoxShape.circle,
                                ),
                                width: 7,
                                height: 7,
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Summary Card
                  if (_selectedDay != null) ...[
                    FCard(
                      child: Padding(
                        padding: AppSpacing.cardPadding,
                        child: DailySummaryCard(
                          date: _selectedDay!,
                          stats: _monthlyStats[DateTime(
                            _selectedDay!.year,
                            _selectedDay!.month,
                            _selectedDay!.day,
                          )],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Monthly Statistics
                  FCard(
                    child: Padding(
                      padding: AppSpacing.cardPadding,
                      child: _buildMonthlyStatistics(theme),
                    ),
                  ),
                ],
              ),
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
