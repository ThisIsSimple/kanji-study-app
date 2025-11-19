/// Leaderboard entry model representing a user's ranking and statistics
class LeaderboardEntry {
  final String userId;
  final String username;
  final int totalKanji;
  final int masteredKanji;
  final int weeklyKanji;
  final int rank;

  const LeaderboardEntry({
    required this.userId,
    required this.username,
    required this.totalKanji,
    required this.masteredKanji,
    required this.weeklyKanji,
    required this.rank,
  });

  factory LeaderboardEntry.fromJson(Map<String, dynamic> json) {
    return LeaderboardEntry(
      userId: json['user_id'] as String,
      username: json['username'] as String? ?? '익명',
      totalKanji: json['total_kanji'] as int? ?? 0,
      masteredKanji: json['mastered_kanji'] as int? ?? 0,
      weeklyKanji: json['weekly_kanji'] as int? ?? 0,
      rank: json['rank'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'username': username,
      'total_kanji': totalKanji,
      'mastered_kanji': masteredKanji,
      'weekly_kanji': weeklyKanji,
      'rank': rank,
    };
  }

  /// Get mastery percentage
  double get masteryPercentage {
    if (totalKanji == 0) return 0.0;
    return (masteredKanji / totalKanji) * 100;
  }

  /// Get rank badge emoji based on position
  String get rankBadge {
    switch (rank) {
      case 1:
        return '🥇';
      case 2:
        return '🥈';
      case 3:
        return '🥉';
      default:
        if (rank <= 10) {
          return '🏅';
        } else if (rank <= 50) {
          return '⭐';
        } else {
          return '';
        }
    }
  }

  /// Get rank display text
  String get rankDisplay {
    return '#$rank';
  }

  /// Get weekly progress summary
  String get weeklySummary {
    return '이번 주 $weeklyKanji개 학습';
  }

  /// Get total progress summary
  String get totalSummary {
    return '총 $totalKanji개 (마스터 $masteredKanji개)';
  }

  LeaderboardEntry copyWith({
    String? userId,
    String? username,
    int? totalKanji,
    int? masteredKanji,
    int? weeklyKanji,
    int? rank,
  }) {
    return LeaderboardEntry(
      userId: userId ?? this.userId,
      username: username ?? this.username,
      totalKanji: totalKanji ?? this.totalKanji,
      masteredKanji: masteredKanji ?? this.masteredKanji,
      weeklyKanji: weeklyKanji ?? this.weeklyKanji,
      rank: rank ?? this.rank,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is LeaderboardEntry &&
        other.userId == userId &&
        other.username == username &&
        other.totalKanji == totalKanji &&
        other.masteredKanji == masteredKanji &&
        other.weeklyKanji == weeklyKanji &&
        other.rank == rank;
  }

  @override
  int get hashCode {
    return userId.hashCode ^
        username.hashCode ^
        totalKanji.hashCode ^
        masteredKanji.hashCode ^
        weeklyKanji.hashCode ^
        rank.hashCode;
  }

  @override
  String toString() {
    return 'LeaderboardEntry(userId: $userId, username: $username, totalKanji: $totalKanji, masteredKanji: $masteredKanji, weeklyKanji: $weeklyKanji, rank: $rank)';
  }
}
