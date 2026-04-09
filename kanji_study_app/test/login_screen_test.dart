import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forui/forui.dart';
import 'package:konnakanji/screens/login_screen.dart';
import 'package:konnakanji/theme/app_theme.dart';

void main() {
  testWidgets('renders login screen title', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: FTheme(data: AppTheme.getFTheme(), child: const LoginScreen()),
      ),
    );

    expect(find.text('콘나칸지'), findsOneWidget);
    expect(find.text('게스트로 시작하기'), findsOneWidget);
  });
}
