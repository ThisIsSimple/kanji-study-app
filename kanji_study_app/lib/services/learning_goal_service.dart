import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/learning_goal.dart';
import 'supabase_service.dart';

class LearningGoalService {
  static final LearningGoalService _instance = LearningGoalService._internal();
  static LearningGoalService get instance => _instance;

  LearningGoalService._internal();

  static const String _dailyGoalKey = 'learning_goal_daily_goal';
  static const String _targetJlptKey = 'learning_goal_target_jlpt_level';

  final SupabaseService _supabaseService = SupabaseService.instance;

  Future<LearningGoal?> getGoal() async {
    final remoteGoal = await _getRemoteGoal();
    if (remoteGoal != null) {
      await _cacheGoal(remoteGoal);
      return remoteGoal;
    }
    return _getCachedGoal();
  }

  Future<void> saveGoal({
    required int dailyGoal,
    required int targetJlptLevel,
  }) async {
    final goal = LearningGoal(
      dailyGoal: dailyGoal,
      targetJlptLevel: targetJlptLevel,
    );
    if (!goal.isValid) {
      throw ArgumentError('Invalid learning goal');
    }

    await _cacheGoal(goal);

    if (!_supabaseService.isLoggedIn) return;

    await _supabaseService.updateUserProfile(
      dailyGoal: goal.dailyGoal,
      targetJlptLevel: goal.targetJlptLevel,
    );
  }

  Future<LearningGoal?> _getRemoteGoal() async {
    try {
      final profile = await _supabaseService.getUserProfile();
      if (profile == null) return null;

      final dailyGoal = _asInt(profile['daily_goal']);
      final targetJlptLevel = _asInt(profile['target_jlpt_level']);
      if (dailyGoal == null || targetJlptLevel == null) return null;

      final goal = LearningGoal(
        dailyGoal: dailyGoal,
        targetJlptLevel: targetJlptLevel,
      );
      return goal.isValid ? goal : null;
    } catch (e) {
      debugPrint('LearningGoalService: failed to load remote goal: $e');
      return null;
    }
  }

  Future<LearningGoal?> _getCachedGoal() async {
    final prefs = await SharedPreferences.getInstance();
    final dailyGoal = prefs.getInt(_dailyGoalKey);
    final targetJlptLevel = prefs.getInt(_targetJlptKey);
    if (dailyGoal == null || targetJlptLevel == null) return null;

    final goal = LearningGoal(
      dailyGoal: dailyGoal,
      targetJlptLevel: targetJlptLevel,
    );
    return goal.isValid ? goal : null;
  }

  Future<void> _cacheGoal(LearningGoal goal) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_dailyGoalKey, goal.dailyGoal);
    await prefs.setInt(_targetJlptKey, goal.targetJlptLevel);
  }

  int? _asInt(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return null;
  }
}
