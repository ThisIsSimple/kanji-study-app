import 'package:flutter_test/flutter_test.dart';
import 'package:konnakanji/models/kanji_model.dart';
import 'package:konnakanji/models/language_settings.dart';
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
          'meaning': 'school',
          'source': 'jmdict',
          'quality_status': 'ai_draft',
        },
      ],
      'meanings_ko': [
        {
          'part_of_speech': 'n',
          'meaning': '학교',
          'source': 'ai_translation',
          'quality_status': 'ai_draft',
        },
      ],
      'meanings_en': [
        {
          'part_of_speech': 'n',
          'meaning': 'school',
          'source': 'jmdict',
          'quality_status': 'ai_draft',
        },
      ],
      'meanings_jp': [
        {
          'part_of_speech': '名詞',
          'meaning': '学問を教えるための施設',
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
    expect(expandedWord.meaningsText, '학교');
    expect(expandedWord.meaningsEn.single.meaning, 'school');
    expect(expandedWord.meaningsJp.single.meaning, '学問を教えるための施設');
    expect(expandedWord.isCommon, isTrue);
    expect(expandedWord.toJson()['meanings_ko'], isNotEmpty);
    expect(expandedWord.toJson()['meanings_en'], isNotEmpty);
    expect(expandedWord.toJson()['meanings_jp'], isNotEmpty);
    expect(expandedWord.toJson()['tags'], ['ichi1']);
  });

  test(
    'Word falls back to Korean-only meanings from legacy mixed meanings',
    () {
      final word = Word.fromJson({
        'id': 3,
        'word': '声',
        'reading': 'こえ',
        'meanings': [
          {'part_of_speech': '명사', 'meaning': '소리'},
          {'part_of_speech': 'n', 'meaning': 'voice', 'source': 'jmdict'},
        ],
        'jlpt_level': 5,
      });

      expect(word.meaningsText, '소리');
      expect(word.meaningsEn.single.meaning, 'voice');
      expect(word.matchesQuery('voice'), isFalse);
      expect(word.matchesQuery('소리'), isTrue);
    },
  );

  test(
    'Word displayMeanings selects requested language with Korean fallback',
    () {
      final word = Word.fromJson({
        'id': 4,
        'word': '確認',
        'reading': 'かくにん',
        'meanings': [
          {'part_of_speech': '명사', 'meaning': '확인'},
        ],
        'meanings_ko': [
          {'part_of_speech': '명사', 'meaning': '확인'},
        ],
        'meanings_en': [
          {'part_of_speech': 'n', 'meaning': 'confirmation'},
        ],
        'meanings_jp': [
          {'part_of_speech': '名詞', 'meaning': 'はっきり確かめること'},
        ],
        'jlpt_level': 3,
      });

      expect(word.displayMeaningsText(WordMeaningLanguage.ko), '확인');
      expect(word.displayMeaningsText(WordMeaningLanguage.en), 'confirmation');
      expect(word.displayMeaningsText(WordMeaningLanguage.ja), 'はっきり確かめること');
      expect(word.matchesQuery('confirmation'), isFalse);
      expect(
        word.matchesQuery(
          'confirmation',
          meaningLanguage: WordMeaningLanguage.en,
        ),
        isTrue,
      );

      final fallbackWord = Word.fromJson({
        'id': 5,
        'word': '声',
        'reading': 'こえ',
        'meanings': [
          {'part_of_speech': '명사', 'meaning': '소리'},
        ],
        'meanings_ko': [
          {'part_of_speech': '명사', 'meaning': '소리'},
        ],
        'meanings_jp': [],
        'jlpt_level': 5,
      });

      expect(fallbackWord.displayMeaningsText(WordMeaningLanguage.ja), '소리');
    },
  );

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
      'meanings': ['꾸짖을', 'scold'],
      'meanings_ko': ['꾸짖을'],
      'meanings_en': ['scold'],
      'kr_meanings': ['꾸짖을'],
      'jp_meanings': ['しかること'],
      'en_meanings': ['scold'],
      'readings': {
        'on': [],
        'kun': ['しか.る'],
      },
      'jp_on_readings': [],
      'jp_kun_readings': ['しか.る'],
      'kr_on_readings': [],
      'kr_kun_readings': ['꾸짖을'],
      'grade': 0,
      'jlpt': 0,
      'strokeCount': 5,
      'examples': [],
      'commentary': '꾸짖는다는 뜻의 한자',
      'kr_commentary': '꾸짖는다는 뜻의 한자',
      'jp_commentary': '叱る意味を表す漢字です。',
      'en_commentary': 'A kanji used for the idea of scolding.',
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
    expect(expandedKanji.meanings, ['꾸짖을']);
    expect(expandedKanji.meaningsEn, ['scold']);
    expect(expandedKanji.krMeanings, ['꾸짖을']);
    expect(expandedKanji.jpMeanings, ['しかること']);
    expect(expandedKanji.enMeanings, ['scold']);
    expect(expandedKanji.jpKunReadings, ['しか.る']);
    expect(expandedKanji.krKunReadings, ['꾸짖을']);
    expect(expandedKanji.krCommentary, '꾸짖는다는 뜻의 한자');
    expect(expandedKanji.jpCommentary, '叱る意味を表す漢字です。');
    expect(
      expandedKanji.enCommentary,
      'A kanji used for the idea of scolding.',
    );
    expect(expandedKanji.tags, ['kanjidic2']);
    expect(expandedKanji.toJson()['quality_status'], 'ai_draft');
    expect(expandedKanji.toJson()['meanings_en'], ['scold']);
    expect(expandedKanji.toJson()['jp_meanings'], ['しかること']);
  });

  test('Kanji display helpers select language fields with Korean fallback', () {
    final kanji = Kanji.fromJson({
      'id': 3,
      'character': '海',
      'meanings': ['바다'],
      'meanings_ko': ['바다'],
      'meanings_en': ['sea'],
      'kr_meanings': ['바다'],
      'en_meanings': ['sea', 'ocean'],
      'readings': {
        'on': ['カイ'],
        'kun': ['うみ'],
      },
      'grade': 2,
      'jlpt': 4,
      'strokeCount': 9,
      'examples': [],
      'commentary': '물을 뜻하는 한자',
      'kr_commentary': '물을 뜻하는 한자',
      'jp_commentary': '水や海を表す漢字です。',
      'en_commentary': 'A kanji used for the sea.',
    });

    expect(kanji.displayMeaningsText(KanjiMeaningLanguage.ko), '바다');
    expect(kanji.displayMeaningsText(KanjiMeaningLanguage.en), 'sea, ocean');
    expect(kanji.displayCommentary(AppLanguage.ko), '물을 뜻하는 한자');
    expect(kanji.displayCommentary(AppLanguage.ja), '水や海を表す漢字です。');
    expect(
      kanji.displayCommentary(AppLanguage.en),
      'A kanji used for the sea.',
    );

    final fallbackKanji = Kanji.fromJson({
      'id': 4,
      'character': '山',
      'meanings': ['산'],
      'meanings_ko': ['산'],
      'meanings_en': [],
      'kr_meanings': ['산'],
      'readings': {
        'on': ['サン'],
        'kun': ['やま'],
      },
      'grade': 1,
      'jlpt': 5,
      'strokeCount': 3,
      'examples': [],
      'commentary': '산을 뜻하는 한자',
    });

    expect(fallbackKanji.displayMeaningsText(KanjiMeaningLanguage.en), '산');
    expect(fallbackKanji.displayCommentary(AppLanguage.en), '산을 뜻하는 한자');
  });
}
