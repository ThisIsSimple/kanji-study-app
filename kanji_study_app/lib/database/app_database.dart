import 'dart:io';
import 'dart:convert';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

part 'app_database.g.dart';

/// 한자 테이블 - Supabase kanji 테이블과 동일한 구조
class KanjiTable extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get character => text()();
  TextColumn get meanings =>
      text().map(const StringListConverter())(); // JSON array
  TextColumn get meaningsKo => text()
      .map(const StringListConverter())
      .withDefault(const Constant('[]'))();
  TextColumn get meaningsEn => text()
      .map(const StringListConverter())
      .withDefault(const Constant('[]'))();
  TextColumn get krMeanings => text()
      .map(const StringListConverter())
      .withDefault(const Constant('[]'))();
  TextColumn get jpMeanings => text()
      .map(const StringListConverter())
      .withDefault(const Constant('[]'))();
  TextColumn get enMeanings => text()
      .map(const StringListConverter())
      .withDefault(const Constant('[]'))();
  TextColumn get readingsOn =>
      text().map(const StringListConverter())(); // readings.on
  TextColumn get readingsKun =>
      text().map(const StringListConverter())(); // readings.kun
  TextColumn get jpOnReadings => text()
      .map(const StringListConverter())
      .withDefault(const Constant('[]'))();
  TextColumn get jpKunReadings => text()
      .map(const StringListConverter())
      .withDefault(const Constant('[]'))();
  TextColumn get krOnReadings => text()
      .map(const StringListConverter())
      .withDefault(const Constant('[]'))();
  TextColumn get krKunReadings => text()
      .map(const StringListConverter())
      .withDefault(const Constant('[]'))();
  TextColumn get koreanOnReadings => text().map(const StringListConverter())();
  TextColumn get koreanKunReadings => text().map(const StringListConverter())();
  IntColumn get grade => integer()();
  IntColumn get jlpt => integer()();
  IntColumn get strokeCount => integer()();
  TextColumn get examples => text()
      .map(const StringListConverter())
      .withDefault(const Constant('[]'))();
  TextColumn get radical => text().nullable()(); // 부수
  TextColumn get commentary => text().nullable()(); // 한자 해설
  TextColumn get krCommentary => text().nullable()();
  TextColumn get jpCommentary => text().nullable()();
  TextColumn get enCommentary => text().nullable()();
  TextColumn get source => text().withDefault(const Constant('legacy_excel'))();
  TextColumn get externalId => text().nullable()();
  TextColumn get sourceVersion => text().nullable()();
  TextColumn get qualityStatus =>
      text().withDefault(const Constant('reviewed'))();
  TextColumn get meaningSource =>
      text().withDefault(const Constant('legacy_excel'))();
  BoolColumn get isCommon => boolean().withDefault(const Constant(false))();
  IntColumn get priorityRank => integer().nullable()();
  TextColumn get tags => text()
      .map(const StringListConverter())
      .withDefault(const Constant('[]'))();
  DateTimeColumn get updatedAt => dateTime().nullable()();
}

/// 단어 테이블 - Supabase words 테이블과 동일한 구조
class WordsTable extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get word => text()();
  TextColumn get reading => text()();
  TextColumn get meanings =>
      text().map(const JsonStringConverter())(); // JSON array of objects
  TextColumn get meaningsKo => text()
      .map(const JsonStringConverter())
      .withDefault(const Constant('[]'))();
  TextColumn get meaningsEn => text()
      .map(const JsonStringConverter())
      .withDefault(const Constant('[]'))();
  TextColumn get meaningsJp => text()
      .map(const JsonStringConverter())
      .withDefault(const Constant('[]'))();
  IntColumn get jlptLevel => integer()();
  TextColumn get source => text().withDefault(const Constant('legacy_naver'))();
  TextColumn get externalId => text().nullable()();
  TextColumn get sourceVersion => text().nullable()();
  TextColumn get qualityStatus =>
      text().withDefault(const Constant('reviewed'))();
  TextColumn get meaningSource =>
      text().withDefault(const Constant('legacy_naver'))();
  BoolColumn get isCommon => boolean().withDefault(const Constant(false))();
  IntColumn get priorityRank => integer().nullable()();
  TextColumn get tags => text()
      .map(const StringListConverter())
      .withDefault(const Constant('[]'))();
  DateTimeColumn get updatedAt => dateTime().nullable()();
}

/// 학습 기록 테이블 - 로컬 + 동기화 상태
class StudyRecordsTable extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get userId => text()();
  TextColumn get studyType => text()(); // 'kanji' or 'word'
  IntColumn get targetId => integer()();
  TextColumn get status => text()(); // 'reviewing', 'familiar', 'mastered'
  DateTimeColumn get studyDate => dateTime()();
  TextColumn get notes => text().nullable()();
  BoolColumn get isSynced => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

/// 즐겨찾기 테이블 - 로컬 + Supabase 동기화
class FavoritesTable extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get userId => text()();
  TextColumn get type => text()(); // 'kanji' or 'word'
  IntColumn get targetId => integer()();
  TextColumn get note => text().nullable()();
  BoolColumn get isSynced => boolean().withDefault(const Constant(false))();
  BoolColumn get isDeleted =>
      boolean().withDefault(const Constant(false))(); // 서버 tombstone 동기화 대기
  DateTimeColumn get operationTimestamp =>
      dateTime().withDefault(currentDateAndTime)();
  TextColumn get operationId => text().withDefault(const Constant('legacy'))();
  TextColumn get deviceId => text().withDefault(const Constant('legacy'))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  List<Set<Column<Object>>> get uniqueKeys => [
    {userId, type, targetId},
  ];
}

/// String List <-> JSON 변환기
class StringListConverter extends TypeConverter<List<String>, String> {
  const StringListConverter();

  @override
  List<String> fromSql(String fromDb) {
    if (fromDb.isEmpty || fromDb == '[]') return [];
    try {
      final decoded = jsonDecode(fromDb);
      if (decoded is List) {
        return decoded.map((e) => e.toString()).toList();
      }
    } catch (e) {
      if (fromDb.startsWith('[') && fromDb.endsWith(']')) {
        final legacy = fromDb.substring(1, fromDb.length - 1).trim();
        if (legacy.isEmpty) return [];
        return legacy
            .split(',')
            .map((s) => s.trim().replaceAll('"', ''))
            .where((s) => s.isNotEmpty)
            .toList();
      }
      return fromDb
          .split(',')
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList();
    }
    return [];
  }

  @override
  String toSql(List<String> value) {
    return jsonEncode(value);
  }
}

/// JSON String 변환기 (meanings 등)
class JsonStringConverter extends TypeConverter<String, String> {
  const JsonStringConverter();

  @override
  String fromSql(String fromDb) => fromDb;

  @override
  String toSql(String value) => value;
}

class _SqlWhere {
  final String sql;
  final List<Variable<Object>> variables;

  const _SqlWhere(this.sql, this.variables);
}

@DriftDatabase(
  tables: [KanjiTable, WordsTable, StudyRecordsTable, FavoritesTable],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor]) : super(executor ?? _openConnection());

  @override
  int get schemaVersion => 10;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (Migrator m) async {
      await m.createAll();
      await _createWordIndexes();
    },
    onUpgrade: (Migrator m, int from, int to) async {
      if (from < 2) {
        await m.createTable(favoritesTable);
      }
      if (from < 3) {
        // Add radical and commentary columns to kanji_table
        await m.addColumn(kanjiTable, kanjiTable.radical);
        await m.addColumn(kanjiTable, kanjiTable.commentary);
      }
      if (from < 4) {
        // Remove frequency column - recreate table without it
        await customStatement('ALTER TABLE kanji_table DROP COLUMN frequency');
      }
      if (from < 5) {
        await customStatement('DROP TABLE IF EXISTS sync_queue_table');
      }
      if (from < 6) {
        await m.addColumn(kanjiTable, kanjiTable.source);
        await m.addColumn(kanjiTable, kanjiTable.externalId);
        await m.addColumn(kanjiTable, kanjiTable.sourceVersion);
        await m.addColumn(kanjiTable, kanjiTable.qualityStatus);
        await m.addColumn(kanjiTable, kanjiTable.meaningSource);
        await m.addColumn(kanjiTable, kanjiTable.isCommon);
        await m.addColumn(kanjiTable, kanjiTable.priorityRank);
        await m.addColumn(kanjiTable, kanjiTable.tags);
        await m.addColumn(kanjiTable, kanjiTable.updatedAt);

        await m.addColumn(wordsTable, wordsTable.source);
        await m.addColumn(wordsTable, wordsTable.externalId);
        await m.addColumn(wordsTable, wordsTable.sourceVersion);
        await m.addColumn(wordsTable, wordsTable.qualityStatus);
        await m.addColumn(wordsTable, wordsTable.meaningSource);
        await m.addColumn(wordsTable, wordsTable.isCommon);
        await m.addColumn(wordsTable, wordsTable.priorityRank);
        await m.addColumn(wordsTable, wordsTable.tags);
        await m.addColumn(wordsTable, wordsTable.updatedAt);
      }
      if (from < 7) {
        await m.addColumn(kanjiTable, kanjiTable.meaningsKo);
        await m.addColumn(kanjiTable, kanjiTable.meaningsEn);
        await m.addColumn(wordsTable, wordsTable.meaningsKo);
        await m.addColumn(wordsTable, wordsTable.meaningsEn);
      }
      if (from < 8) {
        await m.addColumn(wordsTable, wordsTable.meaningsJp);

        await m.addColumn(kanjiTable, kanjiTable.krMeanings);
        await m.addColumn(kanjiTable, kanjiTable.jpMeanings);
        await m.addColumn(kanjiTable, kanjiTable.enMeanings);
        await m.addColumn(kanjiTable, kanjiTable.jpOnReadings);
        await m.addColumn(kanjiTable, kanjiTable.jpKunReadings);
        await m.addColumn(kanjiTable, kanjiTable.krOnReadings);
        await m.addColumn(kanjiTable, kanjiTable.krKunReadings);
        await m.addColumn(kanjiTable, kanjiTable.krCommentary);
        await m.addColumn(kanjiTable, kanjiTable.jpCommentary);
        await m.addColumn(kanjiTable, kanjiTable.enCommentary);

        await customStatement('''
          UPDATE kanji_table
          SET
            jp_on_readings = readings_on,
            jp_kun_readings = readings_kun,
            kr_on_readings = korean_on_readings,
            kr_kun_readings = korean_kun_readings,
            kr_meanings = CASE
              WHEN meanings_ko != '[]' THEN meanings_ko
              ELSE meanings
            END,
            en_meanings = meanings_en,
            kr_commentary = commentary
        ''');
      }
      if (from < 9) {
        await m.addColumn(favoritesTable, favoritesTable.operationTimestamp);
        await m.addColumn(favoritesTable, favoritesTable.operationId);
        await m.addColumn(favoritesTable, favoritesTable.deviceId);
        await customStatement('''
          UPDATE favorites_table
          SET operation_timestamp = created_at
          WHERE operation_timestamp IS NULL
        ''');
        await customStatement('''
          UPDATE favorites_table
          SET operation_id = 'legacy-' || id
          WHERE operation_id = 'legacy'
        ''');
        await customStatement('''
          UPDATE favorites_table
          SET device_id = 'legacy'
          WHERE device_id IS NULL OR device_id = ''
        ''');
        await customStatement('''
          DELETE FROM favorites_table
          WHERE id NOT IN (
            SELECT id
            FROM (
              SELECT
                id,
                ROW_NUMBER() OVER (
                  PARTITION BY user_id, type, target_id
                  ORDER BY operation_timestamp DESC, operation_id DESC, id DESC
                ) AS row_number
              FROM favorites_table
            )
            WHERE row_number = 1
          )
        ''');
        await customStatement('''
          CREATE UNIQUE INDEX IF NOT EXISTS favorites_table_user_type_target_idx
          ON favorites_table (user_id, type, target_id)
        ''');
      }
      if (from < 10) {
        await _createWordIndexes();
      }
    },
  );

  Future<void> _createWordIndexes() async {
    await customStatement(
      'CREATE INDEX IF NOT EXISTS words_table_word_idx ON words_table (word)',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS words_table_reading_idx ON words_table (reading)',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS words_table_jlpt_level_idx ON words_table (jlpt_level)',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS words_table_priority_rank_idx ON words_table (priority_rank)',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS words_table_updated_at_idx ON words_table (updated_at)',
    );
  }

  /// 한자 데이터 조회
  Future<List<KanjiTableData>> getAllKanji() => select(kanjiTable).get();

  Future<KanjiTableData?> getKanjiById(int id) =>
      (select(kanjiTable)..where((t) => t.id.equals(id))).getSingleOrNull();

  Future<KanjiTableData?> getKanjiByCharacter(String character) => (select(
    kanjiTable,
  )..where((t) => t.character.equals(character))).getSingleOrNull();

  /// 한자 데이터 삽입/업데이트
  Future<int> insertKanji(KanjiTableCompanion kanji) =>
      into(kanjiTable).insert(kanji);

  Future<void> insertKanjiBatch(List<KanjiTableCompanion> kanjis) async {
    await batch((batch) {
      batch.insertAll(kanjiTable, kanjis);
    });
  }

  Future<bool> updateKanji(KanjiTableCompanion kanji) =>
      update(kanjiTable).replace(kanji);

  Future<void> clearKanji() => delete(kanjiTable).go();

  /// 단어 데이터 조회
  Future<List<WordsTableData>> getAllWords() => select(wordsTable).get();

  Future<WordsTableData?> getWordById(int id) =>
      (select(wordsTable)..where((t) => t.id.equals(id))).getSingleOrNull();

  /// 단어 데이터 삽입/업데이트
  Future<int> insertWord(WordsTableCompanion word) =>
      into(wordsTable).insert(word);

  Future<void> insertWordsBatch(List<WordsTableCompanion> words) async {
    await batch((batch) {
      batch.insertAllOnConflictUpdate(wordsTable, words);
    });
  }

  Future<void> clearWords() => delete(wordsTable).go();

  Future<void> deleteWordsExceptIds(Set<int> ids) async {
    if (ids.isEmpty) return;

    await transaction(() async {
      await customStatement(
        'CREATE TEMP TABLE IF NOT EXISTS temp_synced_word_ids (id INTEGER PRIMARY KEY)',
      );
      await customStatement('DELETE FROM temp_synced_word_ids');

      final sortedIds = ids.toList()..sort();
      const chunkSize = 500;
      for (var start = 0; start < sortedIds.length; start += chunkSize) {
        final end = (start + chunkSize).clamp(0, sortedIds.length);
        final chunk = sortedIds.sublist(start, end);
        final placeholders = List.filled(chunk.length, '(?)').join(', ');
        await customStatement(
          'INSERT OR IGNORE INTO temp_synced_word_ids (id) VALUES $placeholders',
          chunk,
        );
      }

      await customStatement('''
        DELETE FROM words_table
        WHERE id NOT IN (SELECT id FROM temp_synced_word_ids)
      ''');
      await customStatement('DELETE FROM temp_synced_word_ids');
    });
  }

  Future<List<WordsTableData>> queryWords({
    String? query,
    Set<int> jlptLevels = const {},
    Set<int>? includeIds,
    Set<int> excludeIds = const {},
    int limit = 50,
    int offset = 0,
  }) {
    final where = _buildWordWhere(
      query: query,
      jlptLevels: jlptLevels,
      includeIds: includeIds,
      excludeIds: excludeIds,
    );
    final sql =
        '''
      SELECT *
      FROM words_table
      ${where.sql}
      ORDER BY
        CASE WHEN priority_rank IS NULL THEN 1 ELSE 0 END,
        priority_rank ASC,
        id ASC
      LIMIT ? OFFSET ?
    ''';
    return customSelect(
      sql,
      variables: [
        ...where.variables,
        Variable<Object>(limit),
        Variable<Object>(offset),
      ],
      readsFrom: {wordsTable},
    ).map((row) => wordsTable.map(row.data)).get();
  }

  Future<int> countWords({
    String? query,
    Set<int> jlptLevels = const {},
    Set<int>? includeIds,
    Set<int> excludeIds = const {},
  }) async {
    final where = _buildWordWhere(
      query: query,
      jlptLevels: jlptLevels,
      includeIds: includeIds,
      excludeIds: excludeIds,
    );
    final row = await customSelect(
      '''
        SELECT COUNT(*) AS word_count
        FROM words_table
        ${where.sql}
      ''',
      variables: where.variables,
      readsFrom: {wordsTable},
    ).getSingle();
    return row.read<int>('word_count');
  }

  Future<List<WordsTableData>> getWordsByIds(List<int> ids) {
    if (ids.isEmpty) return Future.value([]);
    final placeholders = List.filled(ids.length, '?').join(', ');
    return customSelect(
      '''
        SELECT *
        FROM words_table
        WHERE id IN ($placeholders)
      ''',
      variables: ids.map((id) => Variable<Object>(id)).toList(),
      readsFrom: {wordsTable},
    ).map((row) => wordsTable.map(row.data)).get().then((rows) {
      final byId = {for (final row in rows) row.id: row};
      return ids.map((id) => byId[id]).whereType<WordsTableData>().toList();
    });
  }

  Future<List<String>> getAllWordTexts() async {
    final rows = await customSelect(
      '''
        SELECT word
        FROM words_table
        ORDER BY id ASC
      ''',
      readsFrom: {wordsTable},
    ).get();
    return rows.map((row) => row.read<String>('word')).toList();
  }

  Future<List<int>> getWordIdsForSession({
    String? query,
    Set<int> jlptLevels = const {},
    Set<int>? includeIds,
    Set<int> excludeIds = const {},
    required int limit,
  }) async {
    final where = _buildWordWhere(
      query: query,
      jlptLevels: jlptLevels,
      includeIds: includeIds,
      excludeIds: excludeIds,
    );
    final rows = await customSelect(
      '''
        SELECT id
        FROM words_table
        ${where.sql}
        ORDER BY RANDOM()
        LIMIT ?
      ''',
      variables: [...where.variables, Variable<Object>(limit)],
      readsFrom: {wordsTable},
    ).get();
    return rows.map((row) => row.read<int>('id')).toList();
  }

  _SqlWhere _buildWordWhere({
    String? query,
    Set<int> jlptLevels = const {},
    Set<int>? includeIds,
    Set<int> excludeIds = const {},
  }) {
    final clauses = <String>[];
    final variables = <Variable<Object>>[];

    final normalizedQuery = query?.trim();
    if (normalizedQuery != null && normalizedQuery.isNotEmpty) {
      final like = '%${_escapeLike(normalizedQuery.toLowerCase())}%';
      clauses.add('''
        (
          lower(word) LIKE ? ESCAPE '\\' OR
          lower(reading) LIKE ? ESCAPE '\\' OR
          lower(meanings_ko) LIKE ? ESCAPE '\\' OR
          lower(meanings_en) LIKE ? ESCAPE '\\' OR
          lower(meanings_jp) LIKE ? ESCAPE '\\'
        )
      ''');
      variables.addAll(List.filled(5, Variable<Object>(like)));
    }

    if (jlptLevels.isNotEmpty) {
      clauses.add(
        'jlpt_level IN (${List.filled(jlptLevels.length, '?').join(', ')})',
      );
      variables.addAll(jlptLevels.map((level) => Variable<Object>(level)));
    }

    if (includeIds != null) {
      if (includeIds.isEmpty) {
        clauses.add('0 = 1');
      } else {
        clauses.add(
          'id IN (${List.filled(includeIds.length, '?').join(', ')})',
        );
        variables.addAll(includeIds.map((id) => Variable<Object>(id)));
      }
    }

    if (excludeIds.isNotEmpty) {
      clauses.add(
        'id NOT IN (${List.filled(excludeIds.length, '?').join(', ')})',
      );
      variables.addAll(excludeIds.map((id) => Variable<Object>(id)));
    }

    if (clauses.isEmpty) return const _SqlWhere('', []);
    return _SqlWhere('WHERE ${clauses.join(' AND ')}', variables);
  }

  String _escapeLike(String value) {
    return value
        .replaceAll(r'\', r'\\')
        .replaceAll('%', r'\%')
        .replaceAll('_', r'\_');
  }

  /// 학습 기록 조회
  Future<List<StudyRecordsTableData>> getStudyRecords(String userId) =>
      (select(studyRecordsTable)..where((t) => t.userId.equals(userId))).get();

  Future<List<StudyRecordsTableData>> getUnsyncedRecords() =>
      (select(studyRecordsTable)..where((t) => t.isSynced.equals(false))).get();

  /// 학습 기록 삽입/업데이트
  Future<int> insertStudyRecord(StudyRecordsTableCompanion record) =>
      into(studyRecordsTable).insert(record);

  Future<void> markRecordAsSynced(int id) =>
      (update(studyRecordsTable)..where((t) => t.id.equals(id))).write(
        const StudyRecordsTableCompanion(isSynced: Value(true)),
      );

  /// 데이터베이스 초기화 여부 확인
  Future<bool> isInitialized() async {
    final kanjiCount = await (selectOnly(
      kanjiTable,
    )..addColumns([kanjiTable.id.count()])).getSingle();
    return kanjiCount.read(kanjiTable.id.count())! > 0;
  }

  /// 즐겨찾기 조회
  Future<List<FavoritesTableData>> getFavorites(String userId) => (select(
    favoritesTable,
  )..where((t) => t.userId.equals(userId) & t.isDeleted.equals(false))).get();

  Future<List<FavoritesTableData>> getFavoriteStates(String userId) =>
      (select(favoritesTable)..where((t) => t.userId.equals(userId))).get();

  Future<List<FavoritesTableData>> getFavoritesByType(
    String userId,
    String type,
  ) =>
      (select(favoritesTable)..where(
            (t) =>
                t.userId.equals(userId) &
                t.type.equals(type) &
                t.isDeleted.equals(false),
          ))
          .get();

  Future<FavoritesTableData?> getFavorite(
    String userId,
    String type,
    int targetId,
  ) =>
      (select(favoritesTable)..where(
            (t) =>
                t.userId.equals(userId) &
                t.type.equals(type) &
                t.targetId.equals(targetId),
          ))
          .getSingleOrNull();

  Future<List<FavoritesTableData>> getUnsyncedFavorites([String? userId]) {
    final query = select(favoritesTable)
      ..where((t) => t.isSynced.equals(false));
    if (userId != null) {
      query.where((t) => t.userId.equals(userId));
    }
    return query.get();
  }

  Future<void> upsertFavoriteState(FavoritesTableCompanion favorite) async {
    final existing = await getFavorite(
      favorite.userId.value,
      favorite.type.value,
      favorite.targetId.value,
    );

    if (existing == null) {
      await into(favoritesTable).insert(favorite);
      return;
    }

    await (update(
      favoritesTable,
    )..where((t) => t.id.equals(existing.id))).write(
      FavoritesTableCompanion(
        note: favorite.note,
        isSynced: favorite.isSynced,
        isDeleted: favorite.isDeleted,
        operationTimestamp: favorite.operationTimestamp,
        operationId: favorite.operationId,
        deviceId: favorite.deviceId,
        createdAt: favorite.createdAt,
      ),
    );
  }

  Future<void> clearUserData(String userId) async {
    await transaction(() async {
      await (delete(
        studyRecordsTable,
      )..where((t) => t.userId.equals(userId))).go();
      await (delete(
        favoritesTable,
      )..where((t) => t.userId.equals(userId))).go();
    });
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'kanji_study.db'));
    return NativeDatabase(file);
  });
}
