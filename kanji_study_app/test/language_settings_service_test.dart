import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:konnakanji/models/language_settings.dart';
import 'package:konnakanji/services/language_settings_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    LanguageSettingsService.instance.resetForTesting();
  });

  test(
    'initializes from supported device locale with derived defaults',
    () async {
      final service = LanguageSettingsService.instance;

      await service.initialize(deviceLocale: const Locale('ja', 'JP'));

      expect(service.appLanguage, AppLanguage.ja);
      expect(service.kanjiMeaningLanguage, KanjiMeaningLanguage.ja);
      expect(service.wordMeaningLanguage, WordMeaningLanguage.ja);
    },
  );

  test('falls back to Korean for unsupported device locale', () async {
    final service = LanguageSettingsService.instance;

    await service.initialize(deviceLocale: const Locale('fr', 'FR'));

    expect(service.appLanguage, AppLanguage.ko);
    expect(service.kanjiMeaningLanguage, KanjiMeaningLanguage.ko);
    expect(service.wordMeaningLanguage, WordMeaningLanguage.ko);
  });

  test(
    'keeps meaning languages independent after app language changes',
    () async {
      final service = LanguageSettingsService.instance;
      var notifications = 0;
      service.addListener(() => notifications++);

      await service.initialize(deviceLocale: const Locale('ko', 'KR'));
      await service.setKanjiMeaningLanguage(KanjiMeaningLanguage.en);
      await service.setWordMeaningLanguage(WordMeaningLanguage.ja);
      await service.setAppLanguage(AppLanguage.ja);

      expect(service.appLanguage, AppLanguage.ja);
      expect(service.kanjiMeaningLanguage, KanjiMeaningLanguage.en);
      expect(service.wordMeaningLanguage, WordMeaningLanguage.ja);
      expect(notifications, 3);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('app_language'), 'ja');
      expect(prefs.getString('kanji_meaning_language'), 'en');
      expect(prefs.getString('word_meaning_language'), 'ja');
    },
  );

  test(
    'loads previously saved languages without deriving new defaults',
    () async {
      SharedPreferences.setMockInitialValues({
        'app_language': 'en',
        'kanji_meaning_language': 'ko',
        'word_meaning_language': 'ja',
      });
      LanguageSettingsService.instance.resetForTesting();
      final service = LanguageSettingsService.instance;

      await service.initialize(deviceLocale: const Locale('ko', 'KR'));

      expect(service.appLanguage, AppLanguage.en);
      expect(service.kanjiMeaningLanguage, KanjiMeaningLanguage.ko);
      expect(service.wordMeaningLanguage, WordMeaningLanguage.ja);
    },
  );
}
