import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import '../services/supabase_service.dart';
import '../models/daily_study_stats.dart';
import 'study_calendar_detail_screen.dart';

class StudyCalendarScreen extends StatefulWidget {
  const StudyCalendarScreen({super.key});

  @override
  State<StudyCalendarScreen> createState() => _StudyCalendarScreenState();
}

class _StudyCalendarScreenState extends State<StudyCalendarScreen> {
  final SupabaseService _supabaseService = SupabaseService.instance;
  
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  Map<DateTime, DailyStudyStats> _monthlyStats = {};
  bool _isLoading = true;
  
  @override
  void initState() {
    super.initState();
    final today = DateTime.now();
    _focusedDay = DateTime(today.year, today.month, today.day);
    _selectedDay = _focusedDay;
    _loadMonthlyStats();
  }
  
  Future<void> _loadMonthlyStats() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final stats = await _supabaseService.getMonthlyStudyStats(
        year: _focusedDay.year,
        month: _focusedDay.month,
      );
      
      setState(() {
        _monthlyStats = stats;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading monthly stats: $e');
      setState(() {
        _isLoading = false;
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
        title: const Text(
          '학습 캘린더',
          style: TextStyle(fontFamily: 'SUITE'),
        ),
        prefixes: [
          FHeaderAction.back(
            onPress: () => Navigator.of(context).pop(),
          ),
        ],
      ),
      child: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Calendar Card
                  FCard(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
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
                          defaultTextStyle: const TextStyle(
                            fontSize: 14,
                          ),
                        ),
                        headerStyle: HeaderStyle(
                          formatButtonVisible: false,  // formatButton 숨기기
                          titleCentered: true,
                          formatButtonShowsNext: false,
                          leftChevronVisible: true,
                          rightChevronVisible: true,
                          headerMargin: const EdgeInsets.only(bottom: 8),
                          headerPadding: const EdgeInsets.symmetric(vertical: 8),
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
                                builder: (context) => StudyCalendarDetailScreen(date: selectedDay),
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
                          _focusedDay = focusedDay;
                          _loadMonthlyStats();
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
                        padding: const EdgeInsets.all(20.0),
                        child: _buildDaySummary(theme),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  
                  // Monthly Statistics
                  FCard(
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: _buildMonthlyStatistics(theme),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
  
  Widget _buildDaySummary(FThemeData theme) {
    final normalizedDay = DateTime(_selectedDay!.year, _selectedDay!.month, _selectedDay!.day);
    final stats = _monthlyStats[normalizedDay];
    
    if (stats == null || stats.totalStudied == 0) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                DateFormat('yyyy년 MM월 dd일').format(_selectedDay!),
                style: theme.typography.lg.copyWith(
                  fontWeight: FontWeight.bold,
                  fontFamily: 'SUITE',
                ),
              ),
              if (DateUtils.isSameDay(_selectedDay!, DateTime.now()))
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: theme.colors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '오늘',
                    style: theme.typography.xs.copyWith(
                      color: theme.colors.primary,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'SUITE',
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '학습 기록이 없습니다',
            style: theme.typography.base.copyWith(
              color: theme.colors.mutedForeground,
              fontFamily: 'SUITE',
            ),
          ),
        ],
      );
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              DateFormat('yyyy년 MM월 dd일').format(_selectedDay!),
              style: theme.typography.lg.copyWith(
                fontWeight: FontWeight.bold,
                fontFamily: 'SUITE',
              ),
            ),
            if (DateUtils.isSameDay(_selectedDay!, DateTime.now()))
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: theme.colors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '오늘',
                  style: theme.typography.xs.copyWith(
                    color: theme.colors.primary,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'SUITE',
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                icon: PhosphorIconsRegular.translate,
                label: '한자',
                value: '${stats.kanjiStudied}개',
                color: theme.colors.primary,
                theme: theme,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                icon: PhosphorIconsRegular.bookOpen,
                label: '단어',
                value: '${stats.wordsStudied}개',
                color: theme.colors.secondary,
                theme: theme,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                icon: PhosphorIconsRegular.checkCircle,
                label: '완료',
                value: '${stats.totalCompleted}회',
                color: Colors.green,
                theme: theme,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                icon: PhosphorIconsRegular.warningCircle,
                label: '까먹음',
                value: '${stats.totalForgot}회',
                color: Colors.orange,
                theme: theme,
              ),
            ),
          ],
        ),
        if (stats.successRate > 0) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colors.secondary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  PhosphorIconsRegular.chartLine,
                  size: 20,
                  color: theme.colors.secondary,
                ),
                const SizedBox(width: 8),
                Text(
                  '성공률: ${(stats.successRate * 100).toStringAsFixed(1)}%',
                  style: theme.typography.base.copyWith(
                    fontWeight: FontWeight.w600,
                    color: theme.colors.secondary,
                    fontFamily: 'SUITE',
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
  
  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    required FThemeData theme,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(height: 8),
          Text(
            label,
            style: theme.typography.xs.copyWith(
              color: theme.colors.mutedForeground,
              fontFamily: 'SUITE',
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: theme.typography.base.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
              fontFamily: 'SUITE',
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
            fontFamily: 'SUITE',
          ),
        ),
        const SizedBox(height: 16),
        _buildMonthlyStatRow('학습일', '$studyDays일', theme),
        const SizedBox(height: 12),
        _buildMonthlyStatRow('한자', '$totalKanji개', theme),
        const SizedBox(height: 12),
        _buildMonthlyStatRow('단어', '$totalWords개', theme),
        const SizedBox(height: 12),
        _buildMonthlyStatRow('성공률', '${successRate.toStringAsFixed(1)}%', theme),
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
            fontFamily: 'SUITE',
          ),
        ),
        Text(
          value,
          style: theme.typography.base.copyWith(
            fontWeight: FontWeight.w600,
            fontFamily: 'SUITE',
          ),
        ),
      ],
    );
  }
}