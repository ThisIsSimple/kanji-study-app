import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forui/forui.dart';
import 'package:konnakanji/theme/app_theme.dart';
import 'package:konnakanji/widgets/app_toast.dart';

class _ToastHarness extends StatefulWidget {
  const _ToastHarness();

  @override
  State<_ToastHarness> createState() => _ToastHarnessState();
}

class _ToastHarnessState extends State<_ToastHarness> {
  int _tapCount = 0;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: FTheme(
        data: AppTheme.getFTheme(),
        child: FScaffold(
          childPad: false,
          child: Builder(
            builder: (context) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    FilledButton(
                      onPressed: () {
                        showAppToast(
                          context,
                          message: '학습 완료를 기록했습니다!',
                          duration: const Duration(seconds: 10),
                        );
                      },
                      child: const Text('Show toast'),
                    ),
                    const SizedBox(height: 24),
                    FilledButton(
                      onPressed: () {
                        setState(() {
                          _tapCount += 1;
                        });
                      },
                      child: Text('Target $_tapCount'),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

void main() {
  testWidgets('toast does not block interactions outside the pill', (
    tester,
  ) async {
    await tester.pumpWidget(const _ToastHarness());

    await tester.tap(find.text('Show toast'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('학습 완료를 기록했습니다!'), findsOneWidget);

    await tester.tap(find.text('Target 0'));
    await tester.pump();

    expect(find.text('Target 1'), findsOneWidget);
    expect(find.text('학습 완료를 기록했습니다!'), findsOneWidget);
  });

  testWidgets('toast dismisses immediately when tapped', (tester) async {
    await tester.pumpWidget(const _ToastHarness());

    await tester.tap(find.text('Show toast'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('학습 완료를 기록했습니다!'), findsOneWidget);

    await tester.tap(find.text('학습 완료를 기록했습니다!'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('학습 완료를 기록했습니다!'), findsNothing);
  });
}
