import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import '../models/leaderboard_model.dart';

/// Leaderboard card showing top users and current user
class LeaderboardCard extends StatelessWidget {
  final List<LeaderboardEntry> entries;
  final String? currentUserId;
  final VoidCallback onViewAll;

  const LeaderboardCard({
    super.key,
    required this.entries,
    this.currentUserId,
    required this.onViewAll,
  });

  @override
  Widget build(BuildContext context) {
    final theme = FTheme.of(context);

    if (entries.isEmpty) {
      return FCard(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Center(
            child: Text(
              '아직 리더보드 데이터가 없습니다',
              style: theme.typography.sm.copyWith(
                color: theme.colors.mutedForeground,
              ),
            ),
          ),
        ),
      );
    }

    return FCard(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '🏆 주간 리더보드',
                  style: theme.typography.base.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton(
                  onPressed: onViewAll,
                  child: Text(
                    '전체 보기',
                    style: theme.typography.sm,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...entries.take(5).map((entry) {
              final isCurrentUser = entry.userId == currentUserId;
              return _LeaderboardRow(
                entry: entry,
                theme: theme,
                isCurrentUser: isCurrentUser,
              );
            }),
          ],
        ),
      ),
    );
  }
}

class _LeaderboardRow extends StatelessWidget {
  final LeaderboardEntry entry;
  final FThemeData theme;
  final bool isCurrentUser;

  const _LeaderboardRow({
    required this.entry,
    required this.theme,
    required this.isCurrentUser,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: BoxDecoration(
        color: isCurrentUser ? theme.colors.primary.withAlpha(25) : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        border: isCurrentUser
            ? Border.all(color: theme.colors.primary.withAlpha(100))
            : null,
      ),
      child: Row(
        children: [
          // Rank badge
          SizedBox(
            width: 32,
            child: Text(
              entry.rankBadge.isNotEmpty ? entry.rankBadge : '#${entry.rank}',
              style: const TextStyle(fontSize: 18),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(width: 12),
          // Username
          Expanded(
            child: Text(
              isCurrentUser ? '${entry.username} (나)' : entry.username,
              style: theme.typography.sm.copyWith(
                fontWeight: isCurrentUser ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
          // Weekly count
          Text(
            '${entry.weeklyKanji}개',
            style: theme.typography.sm.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colors.primary,
            ),
          ),
        ],
      ),
    );
  }
}
