import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forui/forui.dart';
import 'package:konnakanji/l10n/app_localizations.dart';
import 'package:konnakanji/services/handwriting_recognition_service.dart';
import 'package:konnakanji/theme/app_theme.dart';
import 'package:konnakanji/widgets/kanji_handwriting_sheet.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('loads model status after localizations are available', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: FTheme(
          data: AppTheme.getFTheme(),
          child: Material(
            child: KanjiHandwritingSheet(
              title: '손글씨로 한자 찾기',
              availableCandidates: const {'日'},
              emptyStrokesMessage: '먼저 한 글자를 써주세요.',
              noMatchingCandidatesMessage: '앱 데이터와 일치하는 한자 후보를 찾지 못했습니다.',
              recognizeCandidates:
                  ({
                    required List<HandwritingStrokeData> strokes,
                    required Size writingArea,
                  }) async => const [],
            ),
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
  });
}
