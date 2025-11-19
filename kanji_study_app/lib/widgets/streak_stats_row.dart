import 'package:flutter/material.dart';
import 'package:forui/forui.dart';

/// Compact row showing streak, XP, and daily goal progress
class StreakStatsRow extends StatelessWidget {
  final int streak;
  final int xp;
  final int todayProgress;
  final int dailyGoal;

  const StreakStatsRow({
    super.key,
    required this.streak,
    required this.xp,
    required this.todayProgress,
    required this.dailyGoal,
  });

  @override
  Widget build(BuildContext context) {
    final theme = FTheme.of(context);

    return Row(
      children: [
        // Streak card
        Expanded(
          child: _StatCard(
            icon: '🔥',
            value: '$streak',
            label: '일 연속',
            gradient: const LinearGradient(
              colors: [Color(0xFFF59E0B), Color(0xFFF97316)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            theme: theme,
            onTap: () => _showStreakDetail(context),
          ),
        ),
        const SizedBox(width: 12),

        // XP card
        Expanded(
          child: _StatCard(
            icon: '⭐',
            value: '$xp',
            label: 'XP',
            gradient: const LinearGradient(
              colors: [Color(0xFFA855F7), Color(0xFFEC4899)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            theme: theme,
            onTap: () => _showXPDetail(context),
          ),
        ),
        const SizedBox(width: 12),

        // Daily goal card
        Expanded(
          child: _StatCard(
            icon: '🎯',
            value: '$todayProgress/$dailyGoal',
            label: '오늘',
            gradient: const LinearGradient(
              colors: [Color(0xFF3B82F6), Color(0xFF8B5CF6)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            theme: theme,
            onTap: () => _showGoalDetail(context),
          ),
        ),
      ],
    );
  }

  void _showStreakDetail(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('🔥 연속 학습 기록'),
        content: Text(
          streak > 0
              ? '$streak일 연속으로 학습하고 있어요!\n매일 꾸준히 학습하면 실력이 쌓여요.'
              : '오늘부터 연속 학습을 시작해보세요!',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }

  void _showXPDetail(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('⭐ 경험치'),
        content: Text(
          '총 $xp XP를 획득했어요!\n한자 1개 마스터 = 10 XP',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }

  void _showGoalDetail(BuildContext context) {
    final remaining = dailyGoal - todayProgress;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('🎯 오늘의 목표'),
        content: Text(
          todayProgress >= dailyGoal
              ? '오늘의 목표를 달성했어요! 🎉'
              : '오늘의 목표: $dailyGoal개\n현재: $todayProgress개\n남은 학습: $remaining개',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String icon;
  final String value;
  final String label;
  final Gradient gradient;
  final FThemeData theme;
  final VoidCallback onTap;

  const _StatCard({
    required this.icon,
    required this.value,
    required this.label,
    required this.gradient,
    required this.theme,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          gradient: gradient.scale(0.1), // Very subtle gradient
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: theme.colors.border,
            width: 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              icon,
              style: const TextStyle(fontSize: 20),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: theme.typography.sm.copyWith(
                fontWeight: FontWeight.bold,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              label,
              style: theme.typography.xs.copyWith(
                color: theme.colors.mutedForeground,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
