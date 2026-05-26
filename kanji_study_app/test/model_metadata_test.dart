import 'package:flutter_test/flutter_test.dart';
import 'package:konnakanji/models/kanji_model.dart';
import 'package:konnakanji/models/word_model.dart';

void main() {
  test('Word parses source metadata with legacy defaults', () {
    final legacyWord = Word.fromJson({
      'id': 1,
      'word': '声',
      'reading': 'こえ',
      'meanings': [
        {'part_of_speech': '명사', 'meaning': '소리'},
      ],
      'jlpt_level': 5,
    });

    expect(legacyWord.source, 'legacy_naver');
    expect(legacyWord.qualityStatus, 'reviewed');
    expect(legacyWord.tags, isEmpty);

    final expandedWord = Word.fromJson({
      'id': 2,
      'word': '学校',
      'reading': 'がっこう',
      'meanings': [
        {
          'part_of_speech': 'n',
          'meaning': '학교',
          'source': 'ai_translation',
          'quality_status': 'ai_draft',
        },
      ],
      'jlpt_level': 0,
      'source': 'jmdict',
      'external_id': 'jmdict:1000010:0',
      'source_version': 'sample',
      'quality_status': 'ai_draft',
      'meaning_source': 'ai_translation',
      'is_common': true,
      'priority_rank': 2,
      'tags': ['ichi1'],
      'updated_at': '2026-05-26T00:00:00Z',
    });

    expect(expandedWord.source, 'jmdict');
    expect(expandedWord.externalId, 'jmdict:1000010:0');
    expect(expandedWord.meanings.single.source, 'ai_translation');
    expect(expandedWord.isCommon, isTrue);
    expect(expandedWord.toJson()['tags'], ['ichi1']);
  });

  test('Kanji parses source metadata with legacy defaults', () {
    final legacyKanji = Kanji.fromJson({
      'id': 1,
      'character': '学',
      'meanings': ['학문'],
      'readings': {
        'on': ['ガク'],
        'kun': ['まな.ぶ'],
      },
      'grade': 1,
      'jlpt': 5,
      'strokeCount': 8,
      'examples': [],
    });

    expect(legacyKanji.source, 'legacy_excel');
    expect(legacyKanji.qualityStatus, 'reviewed');

    final expandedKanji = Kanji.fromJson({
      'id': 2,
      'character': '𠮟',
      'meanings': ['scold'],
      'readings': {
        'on': [],
        'kun': ['しか.る'],
      },
      'grade': 0,
      'jlpt': 0,
      'strokeCount': 5,
      'examples': [],
      'source': 'kanjidic2',
      'external_id': 'kanjidic2:U+20B9F',
      'source_version': 'sample',
      'quality_status': 'ai_draft',
      'meaning_source': 'kanjidic2_english_meaning',
      'is_common': false,
      'priority_rank': null,
      'tags': ['kanjidic2'],
    });

    expect(expandedKanji.source, 'kanjidic2');
    expect(expandedKanji.externalId, 'kanjidic2:U+20B9F');
    expect(expandedKanji.tags, ['kanjidic2']);
    expect(expandedKanji.toJson()['quality_status'], 'ai_draft');
  });
}
