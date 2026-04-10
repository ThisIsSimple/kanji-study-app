import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forui/forui.dart';
import 'package:konnakanji/models/study_record_model.dart';
import 'package:konnakanji/theme/app_theme.dart';
import 'package:konnakanji/widgets/study_button_bar.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

void main() {
  Future<void> pumpStudyButtonBar(
    WidgetTester tester, {
    required StudyStatus? currentStatus,
    required StudyStats? studyStats,
    bool isRecording = false,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: FTheme(
          data: AppTheme.getFTheme(),
          child: Material(
            child: StudyButtonBar(
              positioned: false,
              isLoading: false,
              isRecording: isRecording,
              studyStats: studyStats,
              currentStatus: currentStatus,
              onStudyComplete: () {},
              onForgot: () {},
              onShowTimeline: () {},
            ),
          ),
        ),
      ),
    );
  }

  StudyStats buildStudyStats(StudyStatus status) {
    return StudyStats(
      targetId: 1,
      type: StudyType.kanji,
      totalRecords: 1,
      completedCount: status == StudyStatus.completed ? 1 : 0,
      forgotCount: status == StudyStatus.forgot ? 1 : 0,
      reviewingCount: status == StudyStatus.reviewing ? 1 : 0,
      masteredCount: status == StudyStatus.mastered ? 1 : 0,
      firstStudied: DateTime(2026, 1, 1, 9),
      lastStudied: DateTime(2026, 1, 1, 9),
      recentRecords: [
        StudyRecord(
          type: StudyType.kanji,
          targetId: 1,
          status: status,
          createdAt: DateTime(2026, 1, 1, 9),
        ),
      ],
    );
  }

  testWidgets('shows only study complete when current status is null', (
    tester,
  ) async {
    await pumpStudyButtonBar(tester, currentStatus: null, studyStats: null);

    expect(find.text('학습 완료'), findsOneWidget);
    expect(find.text('까먹음'), findsNothing);
    expect(
      find.byIcon(PhosphorIconsRegular.clockCounterClockwise),
      findsNothing,
    );
  });

  testWidgets(
    'shows study complete and timeline when current status is forgot',
    (tester) async {
      await pumpStudyButtonBar(
        tester,
        currentStatus: StudyStatus.forgot,
        studyStats: buildStudyStats(StudyStatus.forgot),
      );

      expect(find.text('학습 완료'), findsOneWidget);
      expect(find.text('까먹음'), findsNothing);
      expect(
        find.byIcon(PhosphorIconsRegular.clockCounterClockwise),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'shows forgot and timeline when current status is completed or mastered',
    (tester) async {
      for (final status in [StudyStatus.completed, StudyStatus.mastered]) {
        await pumpStudyButtonBar(
          tester,
          currentStatus: status,
          studyStats: buildStudyStats(status),
        );

        expect(find.text('학습 완료'), findsNothing);
        expect(find.text('까먹음'), findsOneWidget);
        expect(
          find.byIcon(PhosphorIconsRegular.clockCounterClockwise),
          findsOneWidget,
        );
      }
    },
  );

  testWidgets('disables the visible action button while recording', (
    tester,
  ) async {
    await pumpStudyButtonBar(
      tester,
      currentStatus: StudyStatus.forgot,
      studyStats: buildStudyStats(StudyStatus.forgot),
      isRecording: true,
    );

    expect(find.text('기록 중...'), findsOneWidget);
    final buttons = tester.widgetList<FButton>(find.byType(FButton)).toList();
    final actionButton = buttons.last;
    expect(actionButton.onPress, isNull);
  });
}
