import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:intl/intl.dart';

import '../models/daily_study_stats.dart';

/// 7x4 heatmap for the last 28 days based on studied word count
class MonthlyWordHeatmap extends StatelessWidget {
  final List<DailyStudyStats> data;

  const MonthlyWordHeatmap({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final theme = FTheme.of(context);
    final normalizedData = _normalizeToLast28Days(data);
    final startDate = normalizedData.first.date;
    final endDate = normalizedData.last.date;

    return FCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '최근 한 달 단어 학습',
              style: theme.typography.base.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${DateFormat('M/d').format(startDate)} - ${DateFormat('M/d').format(endDate)} · 7 x 4',
              style: theme.typography.xs.copyWith(
                color: theme.colors.mutedForeground,
              ),
            ),
            const SizedBox(height: 16),
            GridView.builder(
              itemCount: normalizedData.length,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                crossAxisSpacing: 6,
                mainAxisSpacing: 6,
                childAspectRatio: 1,
              ),
              itemBuilder: (context, index) {
                final stat = normalizedData[index];
                final wordsStudied = stat.wordsStudied;

                return Tooltip(
                  message:
                      '${DateFormat('M/d(E)', 'ko').format(stat.date)}\n단어 $wordsStudied개',
                  child: Container(
                    decoration: BoxDecoration(
                      color: _colorForWords(wordsStudied),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color: theme.colors.border.withValues(alpha: 0.2),
                        width: 1,
                      ),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 12),
            _HeatmapLegend(theme: theme),
          ],
        ),
      ),
    );
  }

  List<DailyStudyStats> _normalizeToLast28Days(List<DailyStudyStats> source) {
    final sourceByDate = <String, DailyStudyStats>{};
    for (final item in source) {
      sourceByDate[_dateKey(item.date)] = item;
    }

    final now = DateTime.now();
    final endDate = DateTime(now.year, now.month, now.day);
    final startDate = endDate.subtract(const Duration(days: 27));

    return List<DailyStudyStats>.generate(28, (index) {
      final date = startDate.add(Duration(days: index));
      final key = _dateKey(date);
      return sourceByDate[key] ??
          DailyStudyStats(
            date: date,
            kanjiStudied: 0,
            wordsStudied: 0,
            totalCompleted: 0,
            totalForgot: 0,
            studyItems: const [],
          );
    });
  }

  String _dateKey(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  Color _colorForWords(int count) {
    if (count <= 0) return const Color(0xFFE5E7EB);
    if (count <= 2) return const Color(0xFFBFDBFE);
    if (count <= 5) return const Color(0xFF93C5FD);
    if (count <= 9) return const Color(0xFF60A5FA);
    return const Color(0xFF2563EB);
  }
}

class _HeatmapLegend extends StatelessWidget {
  final FThemeData theme;

  const _HeatmapLegend({required this.theme});

  @override
  Widget build(BuildContext context) {
    final levels = [
      const Color(0xFFE5E7EB),
      const Color(0xFFBFDBFE),
      const Color(0xFF93C5FD),
      const Color(0xFF60A5FA),
      const Color(0xFF2563EB),
    ];

    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Text(
          '적음',
          style: theme.typography.xs.copyWith(
            color: theme.colors.mutedForeground,
          ),
        ),
        const SizedBox(width: 8),
        ...levels.map(
          (color) => Padding(
            padding: const EdgeInsets.only(right: 4),
            child: Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          '많음',
          style: theme.typography.xs.copyWith(
            color: theme.colors.mutedForeground,
          ),
        ),
      ],
    );
  }
}
