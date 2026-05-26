import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/learning_goal.dart';
import 'supabase_service.dart';

class LearningGoalSaveResult {
  final LearningGoal goal;
  final bool syncedRemotely;

  const LearningGoalSaveResult({
    required this.goal,
    required this.syncedRemotely,
  });
}

abstract class LearningGoalRemoteStore {
  bool get isLoggedIn;
  Future<LearningGoal?> getGoal();
  Future<void> updateGoal(LearningGoal goal);
}

class SupabaseLearningGoalRemoteStore implements LearningGoalRemoteStore {
  final SupabaseService _supabaseService;

  const SupabaseLearningGoalRemoteStore(this._supabaseService);

  @override
  bool get isLoggedIn => _supabaseService.isLoggedIn;

  @override
  Future<LearningGoal?> getGoal() async {
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
  }

  @override
  Future<void> updateGoal(LearningGoal goal) {
    return _supabaseService.updateUserProfile(
      dailyGoal: goal.dailyGoal,
      targetJlptLevel: goal.targetJlptLevel,
    );
  }

  static int? _asInt(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return null;
  }
}

class LearningGoalService extends ChangeNotifier {
  static final LearningGoalService _instance = LearningGoalService._internal();
  static LearningGoalService get instance => _instance;

  LearningGoalService._internal({LearningGoalRemoteStore? remoteStore})
    : _remoteStore =
          remoteStore ??
          SupabaseLearningGoalRemoteStore(SupabaseService.instance);

  @visibleForTesting
  LearningGoalService.test({required LearningGoalRemoteStore remoteStore})
    : this._internal(remoteStore: remoteStore);

  static const String _dailyGoalKey = 'learning_goal_daily_goal';
  static const String _targetJlptKey = 'learning_goal_target_jlpt_level';
  static const String _pendingSyncKey = 'learning_goal_pending_sync';

  final LearningGoalRemoteStore _remoteStore;

  Future<LearningGoal?> getGoal() async {
    final pendingGoal = await _getPendingGoal();
    if (pendingGoal != null) {
      await _syncGoalToRemote(pendingGoal);
      return pendingGoal;
    }

    final remoteGoal = await _remoteStoreGoal();
    if (remoteGoal != null) {
      await _cacheGoal(remoteGoal);
      return remoteGoal;
    }
    return _getCachedGoal();
  }

  Future<LearningGoalSaveResult> saveGoal({
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
    if (_remoteStore.isLoggedIn) {
      await _setPendingSync(true);
    }
    notifyListeners();

    final syncedRemotely = await _syncGoalToRemote(goal);
    return LearningGoalSaveResult(goal: goal, syncedRemotely: syncedRemotely);
  }

  Future<LearningGoal?> _remoteStoreGoal() async {
    try {
      return _remoteStore.getGoal();
    } catch (e) {
      debugPrint('LearningGoalService: failed to load remote goal: $e');
      return null;
    }
  }

  Future<LearningGoal?> _getPendingGoal() async {
    if (!await _hasPendingSync()) return null;
    final cachedGoal = await _getCachedGoal();
    if (cachedGoal == null) {
      await _setPendingSync(false);
    }
    return cachedGoal;
  }

  Future<bool> _syncGoalToRemote(LearningGoal goal) async {
    if (!_remoteStore.isLoggedIn) {
      await _setPendingSync(false);
      return true;
    }

    try {
      await _remoteStore.updateGoal(goal);
      await _setPendingSync(false);
      return true;
    } catch (e) {
      debugPrint('LearningGoalService: failed to sync remote goal: $e');
      await _setPendingSync(true);
      return false;
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

  Future<bool> _hasPendingSync() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_pendingSyncKey) ?? false;
  }

  Future<void> _setPendingSync(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    if (value) {
      await prefs.setBool(_pendingSyncKey, true);
    } else {
      await prefs.remove(_pendingSyncKey);
    }
  }
}
