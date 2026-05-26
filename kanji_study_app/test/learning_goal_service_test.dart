import 'package:flutter_test/flutter_test.dart';
import 'package:konnakanji/services/learning_goal_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('saveGoal notifies listeners after local save', () async {
    final service = LearningGoalService.instance;
    var notificationCount = 0;

    void listener() {
      notificationCount++;
    }

    service.addListener(listener);
    addTearDown(() => service.removeListener(listener));

    await service.saveGoal(dailyGoal: 12, targetJlptLevel: 3);

    expect(notificationCount, 1);
    final goal = await service.getGoal();
    expect(goal?.dailyGoal, 12);
    expect(goal?.targetJlptLevel, 3);
  });
}
