import 'package:flutter/material.dart';
import 'package:forui/forui.dart';

/// Enhanced progress card with circular progress ring and detailed stats
class EnhancedProgressCard extends StatelessWidget {
  final int studiedCount;
  final int masteredCount;
  final int weeklyCount;
  final double weeklyAverage;
  final int nextMilestone;
  final int remainingToMilestone;

  const EnhancedProgressCard({
    super.key,
    required this.studiedCount,
    required this.masteredCount,
    required this.weeklyCount,
    required this.weeklyAverage,
    required this.nextMilestone,
    required this.remainingToMilestone,
  });

  @override
  Widget build(BuildContext context) {
    final theme = FTheme.of(context);
    const totalKanji = 2136;
    final progressPercentage = (masteredCount / totalKanji * 100).toStringAsFixed(1);

    return FCard(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title
            Text(
              '학습 진도',
              style: theme.typography.lg.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),

            // Main progress display
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Circular progress
                SizedBox(
                  width: 100,
                  height: 100,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Background circle
                      SizedBox(
                        width: 100,
                        height: 100,
                        child: CircularProgressIndicator(
                          value: 1.0,
                          strokeWidth: 8,
                          backgroundColor: Colors.transparent,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            theme.colors.secondary,
                          ),
                        ),
                      ),
                      // Progress circle
                      SizedBox(
                        width: 100,
                        height: 100,
                        child: CircularProgressIndicator(
                          value: masteredCount / totalKanji,
                          strokeWidth: 8,
                          backgroundColor: Colors.transparent,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            theme.colors.primary,
                          ),
                        ),
                      ),
                      // Percentage text
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '$progressPercentage%',
                            style: theme.typography.base.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 24),

                // Stats
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _StatRow(
                        label: '마스터',
                        value: '$masteredCount / $totalKanji',
                        theme: theme,
                      ),
                      const SizedBox(height: 8),
                      _StatRow(
                        label: '학습한 한자',
                        value: '$studiedCount개',
                        theme: theme,
                      ),
                      const SizedBox(height: 8),
                      _StatRow(
                        label: '이번 주',
                        value: '+$weeklyCount개',
                        theme: theme,
                        valueColor: theme.colors.primary,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Additional stats
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colors.muted,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '주간 평균',
                        style: theme.typography.sm.copyWith(
                          color: theme.colors.mutedForeground,
                        ),
                      ),
                      Text(
                        '${weeklyAverage.toStringAsFixed(1)}개/일',
                        style: theme.typography.sm.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '다음 마일스톤',
                        style: theme.typography.sm.copyWith(
                          color: theme.colors.mutedForeground,
                        ),
                      ),
                      Text(
                        '$nextMilestone개 ($remainingToMilestone개 남음)',
                        style: theme.typography.sm.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  final String label;
  final String value;
  final FThemeData theme;
  final Color? valueColor;

  const _StatRow({
    required this.label,
    required this.value,
    required this.theme,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: theme.typography.sm.copyWith(
            color: theme.colors.mutedForeground,
          ),
        ),
        Text(
          value,
          style: theme.typography.sm.copyWith(
            fontWeight: FontWeight.bold,
            color: valueColor,
          ),
        ),
      ],
    );
  }
}
