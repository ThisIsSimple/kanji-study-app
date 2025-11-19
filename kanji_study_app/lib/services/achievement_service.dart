import 'package:flutter/foundation.dart';
import '../models/achievement_model.dart';
import '../config/supabase_config.dart';
import 'supabase_service.dart';
import 'analytics_service.dart';
import 'kanji_service.dart';

/// Achievement service for managing user achievements and badges
class AchievementService {
  static final AchievementService _instance = AchievementService._internal();
  static AchievementService get instance => _instance;

  AchievementService._internal();

  final SupabaseService _supabase = SupabaseService.instance;
  final AnalyticsService _analytics = AnalyticsService.instance;
  final KanjiService _kanji = KanjiService.instance;

  /// Get all available achievements
  Future<List<Achievement>> getAllAchievements() async {
    try {
      final response = await _supabase.client
          .from(SupabaseConfig.achievementsTable)
          .select()
          .order('required_count');

      return response.map((json) => Achievement.fromJson(json)).toList();
    } catch (e) {
      debugPrint('Error getting achievements: $e');
      return [];
    }
  }

  /// Get user's unlocked achievements
  Future<List<UserAchievement>> getUserAchievements() async {
    final userId = _supabase.currentUser?.id;
    if (userId == null) return [];

    try {
      final response = await _supabase.client
          .from(SupabaseConfig.userAchievementsTable)
          .select()
          .eq('user_id', userId)
          .order('unlocked_at', ascending: false);

      return response.map((json) => UserAchievement.fromJson(json)).toList();
    } catch (e) {
      debugPrint('Error getting user achievements: $e');
      return [];
    }
  }

  /// Get achievements with user progress
  Future<List<AchievementWithProgress>> getAchievementsWithProgress() async {
    try {
      final allAchievements = await getAllAchievements();
      final userAchievements = await getUserAchievements();

      // Create map for quick lookup
      final Map<String, UserAchievement> userAchievementMap = {
        for (final ua in userAchievements) ua.achievementId: ua
      };

      return allAchievements.map((achievement) {
        return AchievementWithProgress(
          achievement: achievement,
          userAchievement: userAchievementMap[achievement.id],
        );
      }).toList();
    } catch (e) {
      debugPrint('Error getting achievements with progress: $e');
      return [];
    }
  }

  /// Check and unlock new achievements
  Future<List<Achievement>> checkAndUnlockAchievements() async {
    final userId = _supabase.currentUser?.id;
    if (userId == null) return [];

    try {
      final allAchievements = await getAllAchievements();
      final userAchievements = await getUserAchievements();

      final unlockedIds = userAchievements
          .map((ua) => ua.achievementId)
          .toSet();

      final newlyUnlocked = <Achievement>[];

      for (final achievement in allAchievements) {
        // Skip if already unlocked
        if (unlockedIds.contains(achievement.id)) continue;

        // Calculate current progress
        final progress = await _calculateProgress(achievement);

        // Check if achievement is now unlocked
        if (progress >= achievement.requiredCount) {
          // Unlock the achievement
          await _unlockAchievement(achievement.id, progress);
          newlyUnlocked.add(achievement);
        } else {
          // Update progress even if not unlocked
          await _updateProgress(achievement.id, progress);
        }
      }

      return newlyUnlocked;
    } catch (e) {
      debugPrint('Error checking achievements: $e');
      return [];
    }
  }

  /// Calculate progress for a specific achievement
  Future<int> _calculateProgress(Achievement achievement) async {
    switch (achievement.type) {
      case AchievementType.kanjiCount:
        return _kanji.getMasteredCount();

      case AchievementType.streak:
        return await _analytics.calculateStreak();

      case AchievementType.weeklyCount:
        final weeklyStats = await _analytics.getWeeklyStats();
        return weeklyStats.fold<int>(
          0,
          (sum, stat) => sum + stat.kanjiStudied,
        );

      case AchievementType.masteryRate:
        final studied = _kanji.getStudiedCount();
        final mastered = _kanji.getMasteredCount();
        if (studied == 0) return 0;
        return ((mastered / studied) * 100).round();
    }
  }

  /// Unlock an achievement for the user
  Future<void> _unlockAchievement(String achievementId, int progress) async {
    final userId = _supabase.currentUser?.id;
    if (userId == null) return;

    try {
      await _supabase.client
          .from(SupabaseConfig.userAchievementsTable)
          .upsert({
            'user_id': userId,
            'achievement_id': achievementId,
            'progress': progress,
          });

      debugPrint('Achievement unlocked: $achievementId');
    } catch (e) {
      debugPrint('Error unlocking achievement: $e');
      rethrow;
    }
  }

  /// Update achievement progress without unlocking
  Future<void> _updateProgress(String achievementId, int progress) async {
    final userId = _supabase.currentUser?.id;
    if (userId == null) return;

    try {
      // Check if record exists
      final existing = await _supabase.client
          .from(SupabaseConfig.userAchievementsTable)
          .select()
          .eq('user_id', userId)
          .eq('achievement_id', achievementId)
          .maybeSingle();

      if (existing != null) {
        // Update existing progress
        await _supabase.client
            .from(SupabaseConfig.userAchievementsTable)
            .update({'progress': progress})
            .eq('user_id', userId)
            .eq('achievement_id', achievementId);
      } else {
        // Insert new progress record
        await _supabase.client
            .from(SupabaseConfig.userAchievementsTable)
            .insert({
              'user_id': userId,
              'achievement_id': achievementId,
              'progress': progress,
            });
      }
    } catch (e) {
      debugPrint('Error updating achievement progress: $e');
    }
  }

  /// Get next achievable achievement (closest to unlock)
  Future<AchievementWithProgress?> getNextAchievement() async {
    try {
      final achievementsWithProgress = await getAchievementsWithProgress();

      // Filter unlocked achievements
      final locked = achievementsWithProgress
          .where((awp) => !awp.isUnlocked)
          .toList();

      if (locked.isEmpty) return null;

      // Sort by progress percentage (closest to completion first)
      locked.sort((a, b) {
        return b.progressPercentage.compareTo(a.progressPercentage);
      });

      return locked.first;
    } catch (e) {
      debugPrint('Error getting next achievement: $e');
      return null;
    }
  }

  /// Get unlocked achievements count
  Future<int> getUnlockedCount() async {
    final userAchievements = await getUserAchievements();
    final allAchievements = await getAllAchievements();

    if (allAchievements.isEmpty) return 0;

    return userAchievements
        .where((ua) {
          final achievement = allAchievements.firstWhere(
            (a) => a.id == ua.achievementId,
            orElse: () => Achievement(
              id: '',
              title: '',
              description: '',
              icon: '',
              requiredCount: 0,
              type: AchievementType.kanjiCount,
            ),
          );
          return ua.isUnlocked(achievement.requiredCount);
        })
        .length;
  }

  /// Get achievements grouped by type
  Future<Map<AchievementType, List<AchievementWithProgress>>> getAchievementsByType() async {
    final achievementsWithProgress = await getAchievementsWithProgress();

    final Map<AchievementType, List<AchievementWithProgress>> grouped = {};

    for (final awp in achievementsWithProgress) {
      grouped.putIfAbsent(awp.achievement.type, () => []);
      grouped[awp.achievement.type]!.add(awp);
    }

    return grouped;
  }
}
