import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:konnakanji/database/app_database.dart';

void main() {
  late AppDatabase database;

  setUp(() {
    database = AppDatabase(NativeDatabase.memory());
  });

  tearDown(() async {
    await database.close();
  });

  group('AppDatabase word queries', () {
    test('paginates words without duplicates', () async {
      await database.insertWordsBatch([
        _word(id: 1, word: '食べる', reading: 'たべる', priorityRank: 1),
        _word(id: 2, word: '見る', reading: 'みる', priorityRank: 2),
        _word(id: 3, word: '行く', reading: 'いく', priorityRank: 3),
      ]);

      final firstPage = await database.queryWords(limit: 2, offset: 0);
      final secondPage = await database.queryWords(limit: 2, offset: 2);

      expect(firstPage.map((word) => word.id), [1, 2]);
      expect(secondPage.map((word) => word.id), [3]);
    });

    test('combines search jlpt include and exclude filters', () async {
      await database.insertWordsBatch([
        _word(id: 1, word: '学校', reading: 'がっこう', meaning: '학교', jlptLevel: 5),
        _word(id: 2, word: '学生', reading: 'がくせい', meaning: '학생', jlptLevel: 5),
        _word(id: 3, word: '会社', reading: 'かいしゃ', meaning: '회사', jlptLevel: 4),
      ]);

      final rows = await database.queryWords(
        query: '학',
        jlptLevels: {5},
        includeIds: {1, 2, 3},
        excludeIds: {2},
      );
      final count = await database.countWords(
        query: '학',
        jlptLevels: {5},
        includeIds: {1, 2, 3},
        excludeIds: {2},
      );

      expect(rows.map((word) => word.id), [1]);
      expect(count, 1);
    });

    test('insertWordsBatch upserts by primary key', () async {
      await database.insertWordsBatch([
        _word(id: 1, word: '古い', reading: 'ふるい', meaning: '오래된'),
      ]);
      await database.insertWordsBatch([
        _word(id: 1, word: '新しい', reading: 'あたらしい', meaning: '새로운'),
      ]);

      final row = await database.getWordById(1);

      expect(row?.word, '新しい');
      expect(await database.countWords(), 1);
    });

    test('deleteWordsExceptIds removes stale rows only', () async {
      await database.insertWordsBatch([
        _word(id: 1, word: '残る', reading: 'のこる'),
        _word(id: 2, word: '消える', reading: 'きえる'),
        _word(id: 3, word: '残す', reading: 'のこす'),
      ]);

      await database.deleteWordsExceptIds({1, 3});

      final rows = await database.queryWords(limit: 10);
      expect(rows.map((word) => word.id), [1, 3]);
    });

    test('deleteWordsExceptIds ignores an empty id set', () async {
      await database.insertWordsBatch([
        _word(id: 1, word: '残る', reading: 'のこる'),
      ]);

      await database.deleteWordsExceptIds({});

      expect(await database.countWords(), 1);
    });
  });
}

WordsTableCompanion _word({
  required int id,
  required String word,
  required String reading,
  String meaning = '뜻',
  int jlptLevel = 5,
  int? priorityRank,
}) {
  final meanings = [
    {'meaning': meaning, 'part_of_speech': '명사'},
  ];
  return WordsTableCompanion.insert(
    id: Value(id),
    word: word,
    reading: reading,
    meanings: jsonEncode(meanings),
    meaningsKo: Value(jsonEncode(meanings)),
    meaningsEn: Value(jsonEncode([])),
    meaningsJp: Value(jsonEncode([])),
    jlptLevel: jlptLevel,
    priorityRank: Value(priorityRank),
  );
}
