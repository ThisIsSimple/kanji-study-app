import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:intl/intl.dart';
import '../models/daily_study_stats.dart';

/// Weekly activity heatmap showing last 7 days of study
class WeeklyHeatmap extends StatelessWidget {
  final List<DailyStudyStats> data;

  const WeeklyHeatmap({
    super.key,
    required this.data,
  });

  @override
  Widget build(BuildContext context) {
    final theme = FTheme.of(context);

    return FCard(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '주간 활동',
              style: theme.typography.base.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: data.map((stat) => _DayColumn(stat: stat, theme: theme)).toList(),
            ),
          ],
        ),
      ),
    );
  }
}

class _DayColumn extends StatelessWidget {
  final DailyStudyStats stat;
  final FThemeData theme;

  const _DayColumn({
    required this.stat,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    final dayLabel = DateFormat.E('ko').format(stat.date);
    final count = stat.totalStudied;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Bar
        Container(
          width: 32,
          height: _getBarHeight(count),
          decoration: BoxDecoration(
            color: _getColor(count),
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(height: 8),
        // Day label
        Text(
          dayLabel.substring(0, 1), // First letter only
          style: theme.typography.xs.copyWith(
            color: theme.colors.mutedForeground,
          ),
        ),
        // Count
        if (count > 0)
          Text(
            '$count',
            style: theme.typography.xs.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
      ],
    );
  }

  double _getBarHeight(int count) {
    if (count == 0) return 4;
    if (count < 5) return 20;
    if (count < 10) return 40;
    if (count < 20) return 60;
    return 80;
  }

  Color _getColor(int count) {
    if (count == 0) return theme.colors.secondary;
    if (count < 5) return const Color(0xFFBFDBFE); // blue-200
    if (count < 10) return const Color(0xFF93C5FD); // blue-300
    if (count < 20) return const Color(0xFF60A5FA); // blue-400
    return const Color(0xFF3B82F6); // blue-500
  }
}
