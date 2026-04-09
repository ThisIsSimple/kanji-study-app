import 'package:flutter_test/flutter_test.dart';
import 'package:konnakanji/database/app_database.dart';

void main() {
  test('StringListConverter supports JSON and legacy formats', () {
    const converter = StringListConverter();

    expect(converter.fromSql('["한자","comma,inside","quote\\"value"]'), [
      '한자',
      'comma,inside',
      'quote"value',
    ]);
    expect(converter.fromSql('["legacy","value"]'), ['legacy', 'value']);
    expect(converter.fromSql('legacy, comma separated'), [
      'legacy',
      'comma separated',
    ]);
    expect(converter.toSql(['가', '나']), '["가","나"]');
  });
}
