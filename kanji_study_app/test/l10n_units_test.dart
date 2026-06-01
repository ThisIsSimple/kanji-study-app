import 'package:flutter_test/flutter_test.dart';
import 'package:konnakanji/l10n/app_localizations_ja.dart';

void main() {
  test('Japanese localization keeps card and word count units separate', () {
    final l10n = AppLocalizationsJa();

    expect(l10n.countItems(6), '6枚');
    expect(l10n.countWords(6), '6語');
  });
}
