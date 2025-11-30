import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:intl/intl.dart';
import '../models/daily_study_stats.dart';
import '../constants/app_spacing.dart';
import 'study_stat_card.dart';
import 'success_rate_indicator.dart';

/// Shared widget for displaying daily study summary
/// Used in both StudyCalendarScreen and StudyCalendarDetailScreen
class DailySummaryCard extends StatelessWidget {
  final DateTime date;
  final DailyStudyStats? stats;
  final bool showDetailButton;
  final VoidCallback? onDetailPressed;

  const DailySummaryCard({
    super.key,
    required this.date,
    this.stats,
    this.showDetailButton = false,
    this.onDetailPressed,
  });

  @override
  Widget build(BuildContext context) {
    final theme = FTheme.of(context);

    // Empty state
    if (stats == null || stats!.totalStudied == 0) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (showDetailButton) ...[
            _buildHeader(theme),
            const SizedBox(height: AppSpacing.md),
          ],
          Text(
            '학습 기록이 없습니다',
            style: theme.typography.base.copyWith(
              color: theme.colors.mutedForeground,
            ),
          ),
        ],
      );
    }

    // Summary with stats
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showDetailButton) ...[
          _buildHeader(theme),
          const SizedBox(height: AppSpacing.base),
        ],
        Row(
          children: [
            Expanded(
              child: StudyStatCard(
                icon: PhosphorIconsRegular.translate,
                label: '한자',
                value: '${stats!.kanjiStudied}개',
                color: theme.colors.primary,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: StudyStatCard(
                icon: PhosphorIconsRegular.bookOpen,
                label: '단어',
                value: '${stats!.wordsStudied}개',
                color: theme.colors.secondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        Row(
          children: [
            Expanded(
              child: StudyStatCard(
                icon: PhosphorIconsRegular.checkCircle,
                label: '완료',
                value: '${stats!.totalCompleted}회',
                color: Colors.green,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: StudyStatCard(
                icon: PhosphorIconsRegular.warningCircle,
                label: '까먹음',
                value: '${stats!.totalForgot}회',
                color: Colors.orange,
              ),
            ),
          ],
        ),
        if (stats!.successRate > 0) ...[
          const SizedBox(height: AppSpacing.base),
          SuccessRateIndicator(successRate: stats!.successRate),
        ],
      ],
    );
  }

  Widget _buildHeader(FThemeData theme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          DateFormat('yyyy년 MM월 dd일').format(date),
          style: theme.typography.lg.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        if (showDetailButton)
          GestureDetector(
            onTap: onDetailPressed,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '자세히 보기',
                  style: theme.typography.sm.copyWith(
                    color: theme.colors.primary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(width: 2),
                Icon(
                  PhosphorIconsRegular.caretRight,
                  size: 16,
                  color: theme.colors.primary,
                ),
              ],
            ),
          ),
      ],
    );
  }
}
