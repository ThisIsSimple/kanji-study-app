import 'package:flutter/material.dart';
import 'package:forui/forui.dart';

class ProgressCard extends StatelessWidget {
  final double progress;
  final int studiedCount;
  final int masteredCount;

  const ProgressCard({
    super.key,
    required this.progress,
    required this.studiedCount,
    required this.masteredCount,
  });

  @override
  Widget build(BuildContext context) {
    final theme = FTheme.of(context);

    return FCard(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '학습 진도',
              style: theme.typography.lg.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            LinearProgressIndicator(
              value: progress,
              backgroundColor: theme.colors.secondary,
              valueColor: AlwaysStoppedAnimation<Color>(
                theme.colors.primary,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '학습한 한자: $studiedCount개',
                  style: theme.typography.sm.copyWith(
                  ),
                ),
                Text(
                  '마스터한 한자: $masteredCount개',
                  style: theme.typography.sm.copyWith(
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
