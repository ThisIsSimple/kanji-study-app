import 'package:flutter_test/flutter_test.dart';
import 'package:konnakanji/services/tag_filter.dart';

void main() {
  group('TagFilter', () {
    test('matches all rows when empty', () {
      const filter = TagFilter();

      expect(filter.matches(['domain:medicine']), isTrue);
      expect(filter.matches([]), isTrue);
    });

    test('supports includeAny includeAll and exclude', () {
      const filter = TagFilter(
        includeAny: {'domain:medicine', 'domain:law'},
        includeAll: {'source:jmdict'},
        exclude: {'quality:deprecated'},
      );

      expect(
        filter.matches(['domain:medicine', 'source:jmdict', 'batch:kanji7_v2']),
        isTrue,
      );
      expect(filter.matches(['domain:food', 'source:jmdict']), isFalse);
      expect(filter.matches(['domain:medicine']), isFalse);
      expect(
        filter.matches([
          'domain:medicine',
          'source:jmdict',
          'quality:deprecated',
        ]),
        isFalse,
      );
    });

    test('filters iterables without changing default behavior', () {
      const rows = [
        _Tagged(1, ['domain:medicine']),
        _Tagged(2, ['domain:food']),
      ];

      expect(rows.whereTags(null, (row) => row.tags).map((row) => row.id), [
        1,
        2,
      ]);
      expect(
        rows
            .whereTags(
              const TagFilter(includeAny: {'domain:medicine'}),
              (row) => row.tags,
            )
            .map((row) => row.id),
        [1],
      );
    });
  });
}

class _Tagged {
  final int id;
  final List<String> tags;

  const _Tagged(this.id, this.tags);
}
