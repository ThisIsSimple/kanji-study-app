import 'package:flutter/foundation.dart';
import '../models/leaderboard_model.dart';
import '../config/supabase_config.dart';
import 'supabase_service.dart';

/// Social service for leaderboard and user rankings
class SocialService {
  static final SocialService _instance = SocialService._internal();
  static SocialService get instance => _instance;

  SocialService._internal();

  final SupabaseService _supabase = SupabaseService.instance;

  /// Get weekly leaderboard (top users)
  Future<List<LeaderboardEntry>> getWeeklyLeaderboard({int limit = 20}) async {
    try {
      final response = await _supabase.client
          .from(SupabaseConfig.leaderboardWeeklyView)
          .select()
          .order('rank')
          .limit(limit);

      return response.map((json) => LeaderboardEntry.fromJson(json)).toList();
    } catch (e) {
      debugPrint('Error getting weekly leaderboard: $e');
      return [];
    }
  }

  /// Get current user's rank
  Future<LeaderboardEntry?> getUserRank() async {
    final userId = _supabase.currentUser?.id;
    if (userId == null) return null;

    try {
      final response = await _supabase.client
          .from(SupabaseConfig.leaderboardWeeklyView)
          .select()
          .eq('user_id', userId)
          .maybeSingle();

      return response != null ? LeaderboardEntry.fromJson(response) : null;
    } catch (e) {
      debugPrint('Error getting user rank: $e');
      return null;
    }
  }

  /// Refresh the leaderboard view (call periodically)
  Future<void> refreshLeaderboard() async {
    try {
      await _supabase.client.rpc('refresh_leaderboard');
    } catch (e) {
      debugPrint('Error refreshing leaderboard: $e');
    }
  }

  /// Compare user performance with average
  Future<Map<String, dynamic>> compareWithAverage() async {
    final userId = _supabase.currentUser?.id;
    if (userId == null) {
      return {
        'user_weekly': 0,
        'average_weekly': 0,
        'percentile': 0,
        'better_than_average': false,
      };
    }

    try {
      final userRank = await getUserRank();
      final leaderboard = await getWeeklyLeaderboard(limit: 100);

      if (leaderboard.isEmpty) {
        return {
          'user_weekly': userRank?.weeklyKanji ?? 0,
          'average_weekly': 0,
          'percentile': 0,
          'better_than_average': false,
        };
      }

      final averageWeekly = leaderboard
          .map((e) => e.weeklyKanji)
          .reduce((a, b) => a + b) / leaderboard.length;

      final userWeekly = userRank?.weeklyKanji ?? 0;
      final userRankValue = userRank?.rank ?? leaderboard.length;

      // Calculate percentile (higher is better)
      final percentile = userRankValue > 0
          ? ((leaderboard.length - userRankValue) / leaderboard.length * 100).round()
          : 0;

      return {
        'user_weekly': userWeekly,
        'average_weekly': averageWeekly.round(),
        'percentile': percentile,
        'better_than_average': userWeekly > averageWeekly,
        'rank': userRankValue,
        'total_users': leaderboard.length,
      };
    } catch (e) {
      debugPrint('Error comparing with average: $e');
      return {
        'user_weekly': 0,
        'average_weekly': 0,
        'percentile': 0,
        'better_than_average': false,
      };
    }
  }

  /// Get leaderboard with user highlighted
  Future<List<LeaderboardEntry>> getLeaderboardWithUser({int topCount = 10}) async {
    try {
      final topUsers = await getWeeklyLeaderboard(limit: topCount);
      final userRank = await getUserRank();

      if (userRank == null) return topUsers;

      // Check if user is already in top list
      final userInTop = topUsers.any((entry) => entry.userId == userRank.userId);

      if (userInTop) {
        return topUsers;
      } else {
        // Add user to the list if not in top
        return [...topUsers, userRank];
      }
    } catch (e) {
      debugPrint('Error getting leaderboard with user: $e');
      return [];
    }
  }

  /// Get motivational message based on user's performance
  Future<String> getMotivationalMessage() async {
    try {
      final comparison = await compareWithAverage();
      final percentile = comparison['percentile'] as int;
      final betterThanAverage = comparison['better_than_average'] as bool;

      if (percentile >= 90) {
        return '상위 10%! 정말 대단해요! 🌟';
      } else if (percentile >= 75) {
        return '상위 25%! 훌륭하게 하고 있어요! 🎉';
      } else if (percentile >= 50) {
        return '평균 이상! 계속 열심히 해봐요! 💪';
      } else if (betterThanAverage) {
        return '평균보다 많이 학습했어요! 좋아요! ✨';
      } else {
        return '함께 학습해봐요! 화이팅! 🚀';
      }
    } catch (e) {
      return '오늘도 화이팅! 🎯';
    }
  }
}
