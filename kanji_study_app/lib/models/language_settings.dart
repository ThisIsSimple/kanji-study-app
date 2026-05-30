import 'dart:ui';

enum AppLanguage {
  ko('ko', Locale('ko', 'KR')),
  ja('ja', Locale('ja', 'JP')),
  en('en', Locale('en', 'US'));

  const AppLanguage(this.code, this.locale);

  final String code;
  final Locale locale;

  static AppLanguage fromCode(String? code) {
    return AppLanguage.values.firstWhere(
      (language) => language.code == code,
      orElse: () => AppLanguage.ko,
    );
  }

  static AppLanguage fromLocale(Locale locale) {
    return AppLanguage.values.firstWhere(
      (language) => language.code == locale.languageCode,
      orElse: () => AppLanguage.ko,
    );
  }
}

enum KanjiMeaningLanguage {
  ko('ko'),
  en('en'),
  ja('ja');

  const KanjiMeaningLanguage(this.code);

  final String code;

  static KanjiMeaningLanguage fromCode(String? code) {
    return KanjiMeaningLanguage.values.firstWhere(
      (language) => language.code == code,
      orElse: () => KanjiMeaningLanguage.ko,
    );
  }
}

enum WordMeaningLanguage {
  ko('ko'),
  en('en'),
  ja('ja');

  const WordMeaningLanguage(this.code);

  final String code;

  static WordMeaningLanguage fromCode(String? code) {
    return WordMeaningLanguage.values.firstWhere(
      (language) => language.code == code,
      orElse: () => WordMeaningLanguage.ko,
    );
  }
}
