import 'package:flutter/material.dart';
import 'package:forui/forui.dart';

enum QuickActionType {
  today,
  review,
  favorites,
}

/// Horizontal scrollable quick action cards
class QuickStudyCards extends StatelessWidget {
  final int reviewQueueSize;
  final VoidCallback onTodayTap;
  final VoidCallback onReviewTap;
  final VoidCallback onFavoritesTap;

  const QuickStudyCards({
    super.key,
    required this.reviewQueueSize,
    required this.onTodayTap,
    required this.onReviewTap,
    required this.onFavoritesTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = FTheme.of(context);

    return SizedBox(
      height: 100,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _QuickActionCard(
            icon: '📖',
            title: '오늘의 한자',
            subtitle: '새로운 학습',
            gradient: const LinearGradient(
              colors: [Color(0xFF3B82F6), Color(0xFF8B5CF6)],
            ),
            theme: theme,
            onTap: onTodayTap,
          ),
          const SizedBox(width: 12),
          _QuickActionCard(
            icon: '📝',
            title: '복습 큐',
            subtitle: '$reviewQueueSize개 대기중',
            gradient: const LinearGradient(
              colors: [Color(0xFFF59E0B), Color(0xFFF97316)],
            ),
            theme: theme,
            onTap: onReviewTap,
          ),
          const SizedBox(width: 12),
          _QuickActionCard(
            icon: '⭐',
            title: '즐겨찾기',
            subtitle: '내가 찜한 한자',
            gradient: const LinearGradient(
              colors: [Color(0xFFEC4899), Color(0xFFA855F7)],
            ),
            theme: theme,
            onTap: onFavoritesTap,
          ),
        ],
      ),
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  final String icon;
  final String title;
  final String subtitle;
  final Gradient gradient;
  final FThemeData theme;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.gradient,
    required this.theme,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 140,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: gradient.colors.map((c) => c.withAlpha(25)).toList(),
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: gradient.colors.first.withAlpha(100),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              icon,
              style: const TextStyle(fontSize: 24),
            ),
            const SizedBox(height: 4),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: theme.typography.sm.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    subtitle,
                    style: theme.typography.xs.copyWith(
                      color: theme.colors.mutedForeground,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
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
