import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

import '../models/user_stats_model.dart';
import '../models/daily_study_stats.dart';
import '../models/study_record_model.dart';
import '../config/supabase_config.dart';
import 'supabase_service.dart';
import 'kanji_service.dart';

/// Analytics service for calculating user statistics and progress
class AnalyticsService {
  static final AnalyticsService _instance = AnalyticsService._internal();
  static AnalyticsService get instance => _instance;

  AnalyticsService._internal();

  final SupabaseService _supabase = SupabaseService.instance;
  final KanjiService _kanji = KanjiService.instance;

  // Cache duration
  static const Duration _cacheDuration = Duration(minutes: 5);

  // Cache keys
  static const String _cacheKeyStreak = 'analytics_streak';
  static const String _cacheKeyStreakTime = 'analytics_streak_time';
  static const String _cacheKeyWeeklyStats = 'analytics_weekly_stats';
  static const String _cacheKeyWeeklyStatsTime = 'analytics_weekly_stats_time';

  /// Calculate consecutive study days (streak)
  Future<int> calculateStreak() async {
    final userId = _supabase.currentUser?.id;
    if (userId == null) return 0;

    try {
      // Check cache first
      final prefs = await SharedPreferences.getInstance();
      final cachedTime = prefs.getString(_cacheKeyStreakTime);
      final cachedStreak = prefs.getInt(_cacheKeyStreak);

      if (cachedTime != null && cachedStreak != null) {
        final cacheAge = DateTime.now().difference(DateTime.parse(cachedTime));
        if (cacheAge < _cacheDuration) {
          return cachedStreak;
        }
      }

      // Fetch study records grouped by date
      final records = await _supabase.client
          .from(SupabaseConfig.studyRecordsTable)
          .select('created_at')
          .eq('user_id', userId)
          .order('created_at', ascending: false)
          .limit(365); // Last year

      if (records.isEmpty) {
        await _cacheStreak(0);
        return 0;
      }

      // Group by date and count consecutive days
      final studyDates = <DateTime>{};
      for (final record in records) {
        final date = DateTime.parse(record['created_at'] as String).toLocal();
        final dateOnly = DateTime(date.year, date.month, date.day);
        studyDates.add(dateOnly);
      }

      // Sort dates in descending order
      final sortedDates = studyDates.toList()..sort((a, b) => b.compareTo(a));

      // Calculate streak
      int streak = 0;
      final today = DateTime.now();
      final todayDate = DateTime(today.year, today.month, today.day);

      for (int i = 0; i < sortedDates.length; i++) {
        final expectedDate = todayDate.subtract(Duration(days: i));

        if (sortedDates[i].isAtSameMomentAs(expectedDate)) {
          streak++;
        } else if (sortedDates[i].isBefore(expectedDate)) {
          // Gap found, streak broken
          break;
        }
      }

      // Cache the result
      await _cacheStreak(streak);
      return streak;
    } catch (e) {
      debugPrint('Error calculating streak: $e');
      return 0;
    }
  }

  Future<void> _cacheStreak(int streak) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_cacheKeyStreak, streak);
    await prefs.setString(_cacheKeyStreakTime, DateTime.now().toIso8601String());
  }

  /// Get weekly statistics (last 7 days)
  Future<List<DailyStudyStats>> getWeeklyStats() async {
    final userId = _supabase.currentUser?.id;
    if (userId == null) return [];

    try {
      // Check cache
      final prefs = await SharedPreferences.getInstance();
      final cachedTime = prefs.getString(_cacheKeyWeeklyStatsTime);
      final cachedStats = prefs.getString(_cacheKeyWeeklyStats);

      if (cachedTime != null && cachedStats != null) {
        final cacheAge = DateTime.now().difference(DateTime.parse(cachedTime));
        if (cacheAge < _cacheDuration) {
          final List<dynamic> decoded = json.decode(cachedStats);
          return decoded.map((json) => DailyStudyStats.fromJson(json)).toList();
        }
      }

      final now = DateTime.now();
      final sevenDaysAgo = now.subtract(const Duration(days: 6));
      final startDate = DateTime(sevenDaysAgo.year, sevenDaysAgo.month, sevenDaysAgo.day);

      final records = await _supabase.client
          .from(SupabaseConfig.studyRecordsTable)
          .select('*')
          .eq('user_id', userId)
          .gte('created_at', startDate.toIso8601String())
          .order('created_at', ascending: true);

      // Group by date
      final Map<String, List<StudyRecord>> recordsByDate = {};
      for (final record in records) {
        final studyRecord = StudyRecord.fromJson(record);
        final date = studyRecord.createdAt!;
        final dateKey = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

        recordsByDate.putIfAbsent(dateKey, () => []);
        recordsByDate[dateKey]!.add(studyRecord);
      }

      // Create DailyStudyStats for last 7 days
      final List<DailyStudyStats> weeklyStats = [];
      for (int i = 0; i < 7; i++) {
        final date = startDate.add(Duration(days: i));
        final dateKey = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
        final dayRecords = recordsByDate[dateKey] ?? [];

        int kanjiStudied = 0;
        int wordsStudied = 0;
        int totalCompleted = 0;
        int totalForgot = 0;
        final List<StudyItem> studyItems = [];

        for (final record in dayRecords) {
          if (record.type == StudyType.kanji) {
            kanjiStudied++;
          } else if (record.type == StudyType.word) {
            wordsStudied++;
          }

          if (record.status == StudyStatus.completed || record.status == StudyStatus.mastered) {
            totalCompleted++;
          } else if (record.status == StudyStatus.forgot) {
            totalForgot++;
          }

          studyItems.add(StudyItem(
            id: record.targetId,
            type: record.type.value,
            name: '', // Will be filled by UI if needed
            status: record.status.value,
            studiedAt: record.createdAt!,
          ));
        }

        weeklyStats.add(DailyStudyStats(
          date: date,
          kanjiStudied: kanjiStudied,
          wordsStudied: wordsStudied,
          totalCompleted: totalCompleted,
          totalForgot: totalForgot,
          studyItems: studyItems,
        ));
      }

      // Cache the results
      await _cacheWeeklyStats(weeklyStats);
      return weeklyStats;
    } catch (e) {
      debugPrint('Error getting weekly stats: $e');
      return [];
    }
  }

  Future<void> _cacheWeeklyStats(List<DailyStudyStats> stats) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = json.encode(stats.map((s) => s.toJson()).toList());
    await prefs.setString(_cacheKeyWeeklyStats, encoded);
    await prefs.setString(_cacheKeyWeeklyStatsTime, DateTime.now().toIso8601String());
  }

  /// Get today's progress (number of items studied today)
  Future<int> getTodayProgress() async {
    final userId = _supabase.currentUser?.id;
    if (userId == null) return 0;

    try {
      final today = DateTime.now();
      final startOfDay = DateTime(today.year, today.month, today.day);

      final response = await _supabase.client
          .from(SupabaseConfig.studyRecordsTable)
          .select('id')
          .eq('user_id', userId)
          .eq('type', 'kanji')
          .gte('created_at', startOfDay.toIso8601String());

      return (response as List).length;
    } catch (e) {
      debugPrint('Error getting today progress: $e');
      return 0;
    }
  }

  /// Get user's daily goal
  Future<int> getDailyGoal() async {
    final userId = _supabase.currentUser?.id;
    if (userId == null) return 10; // Default goal

    try {
      final response = await _supabase.client
          .from(SupabaseConfig.dailyGoalsTable)
          .select('daily_target')
          .eq('user_id', userId)
          .maybeSingle();

      if (response != null) {
        return response['daily_target'] as int? ?? 10;
      }
      return 10;
    } catch (e) {
      debugPrint('Error getting daily goal: $e');
      return 10;
    }
  }

  /// Set user's daily goal
  Future<void> setDailyGoal(int goal) async {
    final userId = _supabase.currentUser?.id;
    if (userId == null) return;

    try {
      await _supabase.client
          .from(SupabaseConfig.dailyGoalsTable)
          .upsert({
            'user_id': userId,
            'daily_target': goal,
          });
    } catch (e) {
      debugPrint('Error setting daily goal: $e');
      rethrow;
    }
  }

  /// Get review queue size (items in reviewing status)
  Future<int> getReviewQueueSize() async {
    final userId = _supabase.currentUser?.id;
    if (userId == null) return 0;

    try {
      // Get unique kanji that need review
      final response = await _supabase.client
          .from(SupabaseConfig.studyRecordsTable)
          .select('target_id')
          .eq('user_id', userId)
          .eq('type', 'kanji')
          .eq('status', 'reviewing')
          .order('created_at', ascending: false);

      // Count unique target IDs
      final uniqueTargets = <int>{};
      for (final record in response) {
        uniqueTargets.add(record['target_id'] as int);
      }

      return uniqueTargets.length;
    } catch (e) {
      debugPrint('Error getting review queue size: $e');
      return 0;
    }
  }

  /// Calculate next milestone and remaining count
  Map<String, int> getNextMilestone(int currentCount) {
    const milestones = [10, 50, 100, 150, 200, 500, 1000, 1500, 2000, 2136];

    final next = milestones.firstWhere(
      (m) => m > currentCount,
      orElse: () => 2136,
    );

    return {
      'milestone': next,
      'remaining': next - currentCount,
    };
  }

  /// Get comprehensive user statistics
  Future<UserStats> getUserStats() async {
    try {
      // Fetch all data in parallel
      final results = await Future.wait([
        calculateStreak(),
        getTodayProgress(),
        getDailyGoal(),
        getWeeklyStats(),
        getReviewQueueSize(),
      ]);

      final streak = results[0] as int;
      final todayProgress = results[1] as int;
      final dailyGoal = results[2] as int;
      final weeklyStats = results[3] as List<DailyStudyStats>;
      final reviewQueueSize = results[4] as int;

      // Calculate weekly count and average
      final weeklyCount = weeklyStats.fold<int>(
        0,
        (sum, stat) => sum + stat.kanjiStudied,
      );
      final weeklyAverage = weeklyCount / 7.0;

      // Get total studied and mastered from KanjiService
      final totalStudied = _kanji.getStudiedCount();
      final totalMastered = _kanji.getMasteredCount();

      // Calculate next milestone
      final milestoneInfo = getNextMilestone(totalMastered);

      return UserStats(
        streak: streak,
        totalXP: totalMastered * 10, // 1 kanji = 10 XP (for future implementation)
        todayProgress: todayProgress,
        dailyGoal: dailyGoal,
        weeklyCount: weeklyCount,
        weeklyAverage: weeklyAverage,
        reviewQueueSize: reviewQueueSize,
        nextMilestone: milestoneInfo['milestone']!,
        remainingToMilestone: milestoneInfo['remaining']!,
        totalStudied: totalStudied,
        totalMastered: totalMastered,
      );
    } catch (e) {
      debugPrint('Error getting user stats: $e');
      return UserStats.empty();
    }
  }

  /// Clear all cached analytics data
  Future<void> clearCache() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_cacheKeyStreak);
    await prefs.remove(_cacheKeyStreakTime);
    await prefs.remove(_cacheKeyWeeklyStats);
    await prefs.remove(_cacheKeyWeeklyStatsTime);
  }
}
