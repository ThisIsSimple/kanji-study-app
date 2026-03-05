import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/kanji_model.dart';
import '../models/user_stats_model.dart';

/// Main section that shows what user should do today
class TodayLearningGoalCard extends StatelessWidget {
  final UserStats stats;
  final Kanji todayKanji;
  final VoidCallback onStartStudy;
  final VoidCallback onReviewTap;

  const TodayLearningGoalCard({
    super.key,
    required this.stats,
    required this.todayKanji,
    required this.onStartStudy,
    required this.onReviewTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = FTheme.of(context);
    final progress = stats.dailyProgressPercentage.clamp(0.0, 1.0);
    final primaryText = todayKanji.meanings.isEmpty
        ? '오늘의 한자'
        : todayKanji.meanings.take(2).join(', ');

    return FCard(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '오늘 학습 목표',
              style: theme.typography.lg.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              '들어와서 뭘 할지 고민하지 않아도 되도록, 오늘 할 학습을 바로 시작하세요.',
              style: theme.typography.sm.copyWith(
                color: theme.colors.mutedForeground,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                gradient: const LinearGradient(
                  colors: [Color(0xFFF8FBFF), Color(0xFFEFF6FF)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                border: Border.all(color: const Color(0xFFBFDBFE), width: 1),
              ),
              child: Row(
                children: [
                  Text(
                    todayKanji.character,
                    style: GoogleFonts.notoSerifJp(
                      fontSize: 44,
                      fontWeight: FontWeight.w700,
                      color: theme.colors.foreground,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '오늘의 학습 한자',
                          style: theme.typography.xs.copyWith(
                            color: theme.colors.mutedForeground,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          primaryText,
                          style: theme.typography.base.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'JLPT N${todayKanji.jlpt}',
                          style: theme.typography.xs.copyWith(
                            color: theme.colors.mutedForeground,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '오늘 목표 진행도',
                  style: theme.typography.sm.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  stats.dailyGoalProgressText,
                  style: theme.typography.sm.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                minHeight: 10,
                value: progress,
                backgroundColor: theme.colors.secondary.withValues(alpha: 0.35),
                valueColor: const AlwaysStoppedAnimation(Color(0xFF2563EB)),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              stats.isDailyGoalAchieved
                  ? '오늘 목표를 달성했습니다.'
                  : '남은 목표 ${stats.remainingForDailyGoal}개',
              style: theme.typography.xs.copyWith(
                color: theme.colors.mutedForeground,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: FButton(
                    onPress: onStartStudy,
                    style: FButtonStyle.primary(),
                    child: const Text('오늘 학습 시작'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FButton(
                    onPress: onReviewTap,
                    style: FButtonStyle.outline(),
                    child: const Text('복습하기'),
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
