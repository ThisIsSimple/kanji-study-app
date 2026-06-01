import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forui/forui.dart';
import 'package:konnakanji/l10n/app_localizations.dart';
import 'package:konnakanji/screens/login_screen.dart';
import 'package:konnakanji/theme/app_theme.dart';

void main() {
  Future<void> pumpLoginScreen(WidgetTester tester, {Locale? locale}) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: locale,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: FTheme(data: AppTheme.getFTheme(), child: const LoginScreen()),
      ),
    );
  }

  testWidgets('renders Korean login screen text', (tester) async {
    await pumpLoginScreen(tester, locale: const Locale('ko'));

    expect(find.text('콘나칸지'), findsOneWidget);
    expect(find.text('게스트로 시작하기'), findsOneWidget);
  });

  testWidgets('renders English login screen text', (tester) async {
    await pumpLoginScreen(tester, locale: const Locale('en'));

    expect(find.text('Konna Kanji'), findsOneWidget);
    expect(find.text('Continue with Google'), findsOneWidget);
    expect(find.text('Start as guest'), findsOneWidget);
  });
}
