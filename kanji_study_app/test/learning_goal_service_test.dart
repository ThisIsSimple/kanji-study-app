import 'package:konnakanji/models/learning_goal.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:konnakanji/services/learning_goal_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('saveGoal notifies listeners after local save', () async {
    final service = LearningGoalService.test(
      remoteStore: _FakeLearningGoalRemoteStore(isLoggedIn: false),
    );
    var notificationCount = 0;

    void listener() {
      notificationCount++;
    }

    service.addListener(listener);
    addTearDown(() => service.removeListener(listener));

    final result = await service.saveGoal(dailyGoal: 12, targetJlptLevel: 3);

    expect(result.syncedRemotely, isTrue);
    expect(notificationCount, 1);
    final goal = await service.getGoal();
    expect(goal?.dailyGoal, 12);
    expect(goal?.targetJlptLevel, 3);
  });

  test(
    'saveGoal keeps local goal and reports unsynced on remote failure',
    () async {
      final remoteStore = _FakeLearningGoalRemoteStore(
        isLoggedIn: true,
        failUpdate: true,
      );
      final service = LearningGoalService.test(remoteStore: remoteStore);
      var notificationCount = 0;
      service.addListener(() => notificationCount++);

      final result = await service.saveGoal(dailyGoal: 12, targetJlptLevel: 3);

      expect(result.syncedRemotely, isFalse);
      expect(notificationCount, 1);
      final goal = await service.getGoal();
      expect(goal?.dailyGoal, 12);
      expect(goal?.targetJlptLevel, 3);
      expect(remoteStore.remoteGoal, isNull);
    },
  );

  test(
    'getGoal prioritizes pending local goal until remote sync succeeds',
    () async {
      final remoteStore = _FakeLearningGoalRemoteStore(
        isLoggedIn: true,
        failUpdate: true,
        remoteGoal: const LearningGoal(dailyGoal: 30, targetJlptLevel: 1),
      );
      final service = LearningGoalService.test(remoteStore: remoteStore);

      await service.saveGoal(dailyGoal: 12, targetJlptLevel: 3);

      final pendingGoal = await service.getGoal();
      expect(pendingGoal?.dailyGoal, 12);
      expect(pendingGoal?.targetJlptLevel, 3);

      remoteStore.failUpdate = false;
      final syncedGoal = await service.getGoal();
      expect(syncedGoal?.dailyGoal, 12);
      expect(syncedGoal?.targetJlptLevel, 3);
      expect(remoteStore.remoteGoal?.dailyGoal, 12);
      expect(remoteStore.remoteGoal?.targetJlptLevel, 3);

      remoteStore.remoteGoal = const LearningGoal(
        dailyGoal: 20,
        targetJlptLevel: 2,
      );
      final remoteGoal = await service.getGoal();
      expect(remoteGoal?.dailyGoal, 20);
      expect(remoteGoal?.targetJlptLevel, 2);
    },
  );
}

class _FakeLearningGoalRemoteStore implements LearningGoalRemoteStore {
  _FakeLearningGoalRemoteStore({
    required this.isLoggedIn,
    this.failUpdate = false,
    this.remoteGoal,
  });

  @override
  bool isLoggedIn;

  bool failUpdate;
  LearningGoal? remoteGoal;

  @override
  Future<LearningGoal?> getGoal() async => remoteGoal;

  @override
  Future<void> updateGoal(LearningGoal goal) async {
    if (failUpdate) {
      throw Exception('remote update failed');
    }
    remoteGoal = goal;
  }
}
