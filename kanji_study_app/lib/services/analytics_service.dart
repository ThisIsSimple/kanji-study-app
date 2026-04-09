import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/user_stats_model.dart';
import '../models/daily_study_stats.dart';
import '../models/study_record_model.dart';
import 'study_record_service.dart';

/// Analytics service for calculating user statistics and progress
class AnalyticsService {
  static final AnalyticsService _instance = AnalyticsService._internal();
  static AnalyticsService get instance => _instance;

  AnalyticsService._internal();

  final StudyRecordService _studyRecords = StudyRecordService.instance;

  // Cache duration
  static const Duration _cacheDuration = Duration(minutes: 5);

  // Cache keys
  static const String _cacheKeyStreak = 'analytics_streak';
  static const String _cacheKeyStreakTime = 'analytics_streak_time';
  static const String _cacheKeyWeeklyStats = 'analytics_weekly_stats';
  static const String _cacheKeyWeeklyStatsTime = 'analytics_weekly_stats_time';
  static const String _cacheKeyMonthlyStats = 'analytics_monthly_stats';
  static const String _cacheKeyMonthlyStatsTime =
      'analytics_monthly_stats_time';

  /// Calculate consecutive study days (streak)
  Future<int> calculateStreak() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedTime = prefs.getString(_cacheKeyStreakTime);
      final cachedStreak = prefs.getInt(_cacheKeyStreak);

      if (cachedTime != null && cachedStreak != null) {
        final cacheAge = DateTime.now().difference(DateTime.parse(cachedTime));
        if (cacheAge < _cacheDuration) {
          return cachedStreak;
        }
      }

      final records = await _studyRecords.getStudyRecords(
        startDate: DateTime.now().subtract(const Duration(days: 365)),
      );

      if (records.isEmpty) {
        await _cacheStreak(0);
        return 0;
      }

      final studyDates = <DateTime>{};
      for (final record in records) {
        final date = record.createdAt?.toLocal();
        if (date == null) continue;
        final dateOnly = DateTime(date.year, date.month, date.day);
        studyDates.add(dateOnly);
      }

      final sortedDates = studyDates.toList()..sort((a, b) => b.compareTo(a));

      int streak = 0;
      final today = DateTime.now();
      final todayDate = DateTime(today.year, today.month, today.day);

      for (int i = 0; i < sortedDates.length; i++) {
        final expectedDate = todayDate.subtract(Duration(days: i));

        if (sortedDates[i].isAtSameMomentAs(expectedDate)) {
          streak++;
        } else if (sortedDates[i].isBefore(expectedDate)) {
          break;
        }
      }

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
    await prefs.setString(
      _cacheKeyStreakTime,
      DateTime.now().toIso8601String(),
    );
  }

  /// Get weekly statistics (last 7 days)
  Future<List<DailyStudyStats>> getWeeklyStats() async {
    final endDate = _dateOnly(DateTime.now());
    return getStudyStatsInRange(
      startDate: endDate.subtract(const Duration(days: 6)),
      endDate: endDate,
      cacheKey: _cacheKeyWeeklyStats,
      cacheTimeKey: _cacheKeyWeeklyStatsTime,
    );
  }

  Future<List<DailyStudyStats>> getMonthlyStats() async {
    final endDate = _dateOnly(DateTime.now());
    return getStudyStatsInRange(
      startDate: endDate.subtract(const Duration(days: 27)),
      endDate: endDate,
      cacheKey: _cacheKeyMonthlyStats,
      cacheTimeKey: _cacheKeyMonthlyStatsTime,
    );
  }

  Future<Map<DateTime, DailyStudyStats>> getMonthlyCalendarStats({
    required int year,
    required int month,
  }) async {
    final startDate = DateTime(year, month, 1);
    final endDate = DateTime(year, month + 1, 0);
    final stats = await getStudyStatsInRange(
      startDate: startDate,
      endDate: endDate,
    );
    return {for (final stat in stats) _dateOnly(stat.date): stat};
  }

  Future<DailyStudyStats?> getDailyStats(DateTime date) async {
    final stats = await getStudyStatsInRange(
      startDate: _dateOnly(date),
      endDate: _dateOnly(date),
    );
    return stats.isEmpty ? null : stats.first;
  }

  Future<List<DailyStudyStats>> getStudyStatsInRange({
    required DateTime startDate,
    required DateTime endDate,
    String? cacheKey,
    String? cacheTimeKey,
  }) async {
    try {
      if (cacheKey != null && cacheTimeKey != null) {
        final prefs = await SharedPreferences.getInstance();
        final cachedTime = prefs.getString(cacheTimeKey);
        final cachedStats = prefs.getString(cacheKey);

        if (cachedTime != null && cachedStats != null) {
          final cacheAge = DateTime.now().difference(
            DateTime.parse(cachedTime),
          );
          if (cacheAge < _cacheDuration) {
            final List<dynamic> decoded = json.decode(cachedStats);
            return decoded
                .map((json) => DailyStudyStats.fromJson(json))
                .toList();
          }
        }
      }

      final normalizedStart = _dateOnly(startDate);
      final normalizedEnd = _dateOnly(endDate);
      final records = await _studyRecords.getStudyRecords(
        startDate: normalizedStart,
        endDate: normalizedEnd.add(
          const Duration(hours: 23, minutes: 59, seconds: 59),
        ),
      );

      final recordsByDate = <String, List<StudyRecord>>{};
      for (final record in records) {
        final date = record.createdAt == null
            ? null
            : _dateOnly(record.createdAt!.toLocal());
        if (date == null) continue;
        final dateKey = _dateKey(date);
        recordsByDate.putIfAbsent(dateKey, () => []).add(record);
      }

      final List<DailyStudyStats> dailyStats = [];
      final days = normalizedEnd.difference(normalizedStart).inDays + 1;
      for (var i = 0; i < days; i++) {
        final date = normalizedStart.add(Duration(days: i));
        final dateKey = _dateKey(date);
        final dayRecords = recordsByDate[dateKey] ?? [];

        final uniqueKanji = <int>{};
        final uniqueWords = <int>{};
        int totalCompleted = 0;
        int totalForgot = 0;
        final List<StudyItem> studyItems = [];

        for (final record in dayRecords) {
          if (record.type == StudyType.kanji) {
            uniqueKanji.add(record.targetId);
          } else if (record.type == StudyType.word) {
            uniqueWords.add(record.targetId);
          }

          if (record.status.countsAsCompleted) {
            totalCompleted++;
          } else if (record.status == StudyStatus.forgot) {
            totalForgot++;
          }

          studyItems.add(
            StudyItem(
              id: record.targetId,
              type: record.type.value,
              name: '', // Will be filled by UI if needed
              status: record.status.value,
              studiedAt: record.createdAt!,
            ),
          );
        }

        dailyStats.add(
          DailyStudyStats(
            date: date,
            kanjiStudied: uniqueKanji.length,
            wordsStudied: uniqueWords.length,
            totalCompleted: totalCompleted,
            totalForgot: totalForgot,
            studyItems: studyItems,
          ),
        );
      }

      if (cacheKey != null && cacheTimeKey != null) {
        await _cacheStudyStats(
          stats: dailyStats,
          cacheKey: cacheKey,
          cacheTimeKey: cacheTimeKey,
        );
      }
      return dailyStats;
    } catch (e) {
      debugPrint('Error getting daily stats: $e');
      return [];
    }
  }

  Future<void> _cacheStudyStats({
    required List<DailyStudyStats> stats,
    required String cacheKey,
    required String cacheTimeKey,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = json.encode(stats.map((s) => s.toJson()).toList());
    await prefs.setString(cacheKey, encoded);
    await prefs.setString(cacheTimeKey, DateTime.now().toIso8601String());
  }

  /// Calculate next milestone and remaining count
  Map<String, int> getNextMilestone(int currentCount) {
    const milestones = [10, 50, 100, 150, 200, 500, 1000, 1500, 2000, 2136];

    final next = milestones.firstWhere(
      (m) => m > currentCount,
      orElse: () => 2136,
    );

    return {'milestone': next, 'remaining': next - currentCount};
  }

  /// Get comprehensive user statistics
  Future<UserStats> getUserStats() async {
    try {
      // Fetch all data in parallel
      final results = await Future.wait([calculateStreak(), getWeeklyStats()]);

      final streak = results[0] as int;
      final weeklyStats = results[1] as List<DailyStudyStats>;
      final todayProgress = _calculateTodayProgress(weeklyStats);

      // Calculate weekly count and average
      final weeklyCount = weeklyStats.fold<int>(
        0,
        (sum, stat) => sum + stat.totalStudied,
      );
      final weeklyAverage = weeklyCount / 7.0;

      final kanjiSummary = _studyRecords.getSummary(StudyType.kanji);
      final totalStudied = kanjiSummary.studiedItems;
      final totalMastered = kanjiSummary.masteredItems;

      // Calculate next milestone
      final milestoneInfo = getNextMilestone(totalMastered);

      return UserStats(
        streak: streak,
        totalXP: totalMastered * 10,
        todayProgress: todayProgress,
        dailyGoal: 10,
        weeklyCount: weeklyCount,
        weeklyAverage: weeklyAverage,
        reviewQueueSize: 0,
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
    await prefs.remove(_cacheKeyMonthlyStats);
    await prefs.remove(_cacheKeyMonthlyStatsTime);
  }

  int _calculateTodayProgress(List<DailyStudyStats> stats) {
    final today = DateTime.now();
    for (final stat in stats) {
      if (_isSameDate(stat.date, today)) {
        return stat.totalStudied;
      }
    }
    return 0;
  }

  bool _isSameDate(DateTime left, DateTime right) {
    return left.year == right.year &&
        left.month == right.month &&
        left.day == right.day;
  }

  static List<DailyStudyStats> buildDailyStats(
    List<StudyRecord> records, {
    required DateTime startDate,
    required DateTime endDate,
  }) {
    final service = AnalyticsService.instance;
    return service._buildDailyStats(
      records,
      startDate: startDate,
      endDate: endDate,
    );
  }

  List<DailyStudyStats> _buildDailyStats(
    List<StudyRecord> records, {
    required DateTime startDate,
    required DateTime endDate,
  }) {
    final recordsByDate = <String, List<StudyRecord>>{};
    for (final record in records) {
      final date = record.createdAt == null
          ? null
          : _dateOnly(record.createdAt!);
      if (date == null) continue;
      recordsByDate.putIfAbsent(_dateKey(date), () => []).add(record);
    }

    final dailyStats = <DailyStudyStats>[];
    final totalDays =
        _dateOnly(endDate).difference(_dateOnly(startDate)).inDays + 1;
    for (var i = 0; i < totalDays; i++) {
      final date = _dateOnly(startDate).add(Duration(days: i));
      final dayRecords = recordsByDate[_dateKey(date)] ?? const <StudyRecord>[];
      final uniqueKanji = <int>{};
      final uniqueWords = <int>{};
      var totalCompleted = 0;
      var totalForgot = 0;
      final studyItems = <StudyItem>[];

      for (final record in dayRecords) {
        if (record.type == StudyType.kanji) {
          uniqueKanji.add(record.targetId);
        } else if (record.type == StudyType.word) {
          uniqueWords.add(record.targetId);
        }

        if (record.status.countsAsCompleted) {
          totalCompleted++;
        } else if (record.status == StudyStatus.forgot) {
          totalForgot++;
        }

        studyItems.add(
          StudyItem(
            id: record.targetId,
            type: record.type.value,
            name: '',
            status: record.status.value,
            studiedAt: record.createdAt ?? date,
          ),
        );
      }

      dailyStats.add(
        DailyStudyStats(
          date: date,
          kanjiStudied: uniqueKanji.length,
          wordsStudied: uniqueWords.length,
          totalCompleted: totalCompleted,
          totalForgot: totalForgot,
          studyItems: studyItems,
        ),
      );
    }

    return dailyStats;
  }

  DateTime _dateOnly(DateTime date) =>
      DateTime(date.year, date.month, date.day);

  String _dateKey(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}
