import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forui/forui.dart';
import 'package:konnakanji/models/flashcard_item.dart';
import 'package:konnakanji/screens/flashcard_screen.dart';
import 'package:konnakanji/services/flashcard_service.dart';
import 'package:konnakanji/theme/app_theme.dart';
import 'package:konnakanji/utils/study_session_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await FlashcardService.instance.clearAllSessions();
  });

  testWidgets('launchFixed does not clear an existing session before choice', (
    tester,
  ) async {
    await FlashcardService.instance.createSession('word', [99]);

    await tester.pumpWidget(
      _LauncherHarness(
        items: const [_TestFlashcardItem(1), _TestFlashcardItem(2)],
        resumeItems: const [_TestFlashcardItem(99)],
      ),
    );

    await tester.tap(find.text('Start'));
    await tester.pumpAndSettle();

    expect(find.text('진행 중인 단어 학습'), findsOneWidget);
    final session = await FlashcardService.instance.loadSessionByType('word');
    expect(session?.itemIds, [99]);
  });

  testWidgets('launchFixed clears existing session only after starting new', (
    tester,
  ) async {
    await FlashcardService.instance.createSession('word', [99]);

    await tester.pumpWidget(
      _LauncherHarness(
        items: const [_TestFlashcardItem(1), _TestFlashcardItem(2)],
        resumeItems: const [_TestFlashcardItem(99)],
      ),
    );

    await tester.tap(find.text('Start'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('오늘 학습 새로 시작'));
    await tester.pumpAndSettle();

    final session = await FlashcardService.instance.loadSessionByType('word');
    expect(session?.itemIds, [1, 2]);
  });

  testWidgets('launchFixed resumes existing session when selected', (
    tester,
  ) async {
    await FlashcardService.instance.createSession('word', [99]);

    await tester.pumpWidget(
      _LauncherHarness(
        items: const [_TestFlashcardItem(1), _TestFlashcardItem(2)],
        resumeItems: const [_TestFlashcardItem(99)],
      ),
    );

    await tester.tap(find.text('Start'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('이어하기'));
    await tester.pumpAndSettle();

    expect(find.byType(FlashcardScreen), findsOneWidget);
    final session = await FlashcardService.instance.loadSessionByType('word');
    expect(session?.itemIds, [99]);
  });
}

class _LauncherHarness extends StatelessWidget {
  const _LauncherHarness({required this.items, required this.resumeItems});

  final List<_TestFlashcardItem> items;
  final List<_TestFlashcardItem> resumeItems;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: AppTheme.getLightTheme(),
      home: FTheme(
        data: AppTheme.getFTheme(),
        child: FScaffold(
          child: Builder(
            builder: (context) => Center(
              child: FilledButton(
                onPressed: () {
                  StudySessionLauncher.launchFixed<_TestFlashcardItem>(
                    context: context,
                    itemType: 'word',
                    items: items,
                    flashcardService: FlashcardService.instance,
                    emptyMessage: 'empty',
                    toFlashcardItems: (items) => items,
                    resumeItems: resumeItems,
                    onComplete: () async {},
                  );
                },
                child: const Text('Start'),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TestFlashcardItem implements FlashcardItem {
  const _TestFlashcardItem(this.id);

  @override
  final int id;

  @override
  String get itemType => 'word';

  @override
  String get frontText => 'front $id';

  @override
  String? get frontBadge => null;

  @override
  int? get frontBadgeColor => null;

  @override
  String get backText => 'back $id';

  @override
  String? get backReading => null;

  @override
  List<FlashcardMeaning> get backMeanings => const [];
}
