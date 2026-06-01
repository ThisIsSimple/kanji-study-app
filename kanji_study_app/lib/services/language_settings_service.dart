import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/language_settings.dart';

class LanguageSettingsService extends ChangeNotifier {
  static final LanguageSettingsService instance =
      LanguageSettingsService._internal();

  LanguageSettingsService._internal();

  static const _appLanguageKey = 'app_language';
  static const _kanjiMeaningLanguageKey = 'kanji_meaning_language';
  static const _wordMeaningLanguageKey = 'word_meaning_language';

  bool _isInitialized = false;
  late AppLanguage _appLanguage;
  late KanjiMeaningLanguage _kanjiMeaningLanguage;
  late WordMeaningLanguage _wordMeaningLanguage;

  bool get isInitialized => _isInitialized;
  AppLanguage get appLanguage => _appLanguage;
  KanjiMeaningLanguage get kanjiMeaningLanguage => _kanjiMeaningLanguage;
  WordMeaningLanguage get wordMeaningLanguage => _wordMeaningLanguage;

  Future<void> initialize({Locale? deviceLocale}) async {
    if (_isInitialized) return;

    final prefs = await SharedPreferences.getInstance();
    final savedAppLanguage = prefs.getString(_appLanguageKey);
    final savedKanjiLanguage = prefs.getString(_kanjiMeaningLanguageKey);
    final savedWordLanguage = prefs.getString(_wordMeaningLanguageKey);

    _appLanguage = savedAppLanguage != null
        ? AppLanguage.fromCode(savedAppLanguage)
        : AppLanguage.fromLocale(
            deviceLocale ?? PlatformDispatcher.instance.locale,
          );

    _kanjiMeaningLanguage = savedKanjiLanguage != null
        ? KanjiMeaningLanguage.fromCode(savedKanjiLanguage)
        : _defaultKanjiMeaningLanguage(_appLanguage);
    _wordMeaningLanguage = savedWordLanguage != null
        ? WordMeaningLanguage.fromCode(savedWordLanguage)
        : _defaultWordMeaningLanguage(_appLanguage);

    await prefs.setString(_appLanguageKey, _appLanguage.code);
    await prefs.setString(_kanjiMeaningLanguageKey, _kanjiMeaningLanguage.code);
    await prefs.setString(_wordMeaningLanguageKey, _wordMeaningLanguage.code);

    _isInitialized = true;
  }

  Future<void> setAppLanguage(AppLanguage language) async {
    await initialize();
    if (_appLanguage == language) return;

    _appLanguage = language;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_appLanguageKey, language.code);
    notifyListeners();
  }

  Future<void> setKanjiMeaningLanguage(KanjiMeaningLanguage language) async {
    await initialize();
    if (_kanjiMeaningLanguage == language) return;

    _kanjiMeaningLanguage = language;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kanjiMeaningLanguageKey, language.code);
    notifyListeners();
  }

  Future<void> setWordMeaningLanguage(WordMeaningLanguage language) async {
    await initialize();
    if (_wordMeaningLanguage == language) return;

    _wordMeaningLanguage = language;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_wordMeaningLanguageKey, language.code);
    notifyListeners();
  }

  KanjiMeaningLanguage _defaultKanjiMeaningLanguage(AppLanguage appLanguage) {
    return switch (appLanguage) {
      AppLanguage.en => KanjiMeaningLanguage.en,
      AppLanguage.ja => KanjiMeaningLanguage.ja,
      AppLanguage.ko => KanjiMeaningLanguage.ko,
    };
  }

  WordMeaningLanguage _defaultWordMeaningLanguage(AppLanguage appLanguage) {
    return switch (appLanguage) {
      AppLanguage.en => WordMeaningLanguage.en,
      AppLanguage.ja => WordMeaningLanguage.ja,
      AppLanguage.ko => WordMeaningLanguage.ko,
    };
  }

  @visibleForTesting
  void resetForTesting() {
    _isInitialized = false;
    _appLanguage = AppLanguage.ko;
    _kanjiMeaningLanguage = KanjiMeaningLanguage.ko;
    _wordMeaningLanguage = WordMeaningLanguage.ko;
  }
}
