import 'dart:io';
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
  TextColumn get readingsOn =>
      text().map(const StringListConverter())(); // readings.on
  TextColumn get readingsKun =>
      text().map(const StringListConverter())(); // readings.kun
  TextColumn get koreanOnReadings =>
      text().map(const StringListConverter())();
  TextColumn get koreanKunReadings =>
      text().map(const StringListConverter())();
  IntColumn get grade => integer()();
  IntColumn get jlpt => integer()();
  IntColumn get strokeCount => integer()();
  IntColumn get frequency => integer()();
  TextColumn get examples =>
      text().map(const StringListConverter()).withDefault(const Constant('[]'))();
}

/// 단어 테이블 - Supabase words 테이블과 동일한 구조
class WordsTable extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get word => text()();
  TextColumn get reading => text()();
  TextColumn get meanings =>
      text().map(const JsonStringConverter())(); // JSON array of objects
  IntColumn get jlptLevel => integer()();
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

/// 동기화 큐 테이블
class SyncQueueTable extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get operation => text()(); // 'insert', 'update', 'delete'
  TextColumn get tableName => text()();
  TextColumn get data => text()(); // JSON
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

/// String List <-> JSON 변환기
class StringListConverter extends TypeConverter<List<String>, String> {
  const StringListConverter();

  @override
  List<String> fromSql(String fromDb) {
    if (fromDb.isEmpty || fromDb == '[]') return [];
    try {
      final List<dynamic> decoded =
          (fromDb.startsWith('['))
              ? (fromDb
                  .substring(1, fromDb.length - 1)
                  .split(',')
                  .map((s) => s.trim().replaceAll('"', ''))
                  .toList())
              : fromDb.split(',').map((s) => s.trim()).toList();
      return decoded.map((e) => e.toString()).toList();
    } catch (e) {
      return [];
    }
  }

  @override
  String toSql(List<String> value) {
    if (value.isEmpty) return '[]';
    return '[${value.map((s) => '"$s"').join(',')}]';
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

@DriftDatabase(tables: [KanjiTable, WordsTable, StudyRecordsTable, SyncQueueTable])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;

  /// 한자 데이터 조회
  Future<List<KanjiTableData>> getAllKanji() => select(kanjiTable).get();

  Future<KanjiTableData?> getKanjiById(int id) =>
      (select(kanjiTable)..where((t) => t.id.equals(id))).getSingleOrNull();

  Future<KanjiTableData?> getKanjiByCharacter(String character) =>
      (select(kanjiTable)..where((t) => t.character.equals(character)))
          .getSingleOrNull();

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
      batch.insertAll(wordsTable, words);
    });
  }

  Future<void> clearWords() => delete(wordsTable).go();

  /// 학습 기록 조회
  Future<List<StudyRecordsTableData>> getStudyRecords(String userId) =>
      (select(studyRecordsTable)..where((t) => t.userId.equals(userId))).get();

  Future<List<StudyRecordsTableData>> getUnsyncedRecords() =>
      (select(studyRecordsTable)..where((t) => t.isSynced.equals(false))).get();

  /// 학습 기록 삽입/업데이트
  Future<int> insertStudyRecord(StudyRecordsTableCompanion record) =>
      into(studyRecordsTable).insert(record);

  Future<void> markRecordAsSynced(int id) =>
      (update(studyRecordsTable)..where((t) => t.id.equals(id)))
          .write(const StudyRecordsTableCompanion(isSynced: Value(true)));

  /// 동기화 큐 관리
  Future<List<SyncQueueTableData>> getSyncQueue() =>
      select(syncQueueTable).get();

  Future<int> addToSyncQueue(SyncQueueTableCompanion item) =>
      into(syncQueueTable).insert(item);

  Future<void> removeFromSyncQueue(int id) =>
      (delete(syncQueueTable)..where((t) => t.id.equals(id))).go();

  /// 데이터베이스 초기화 여부 확인
  Future<bool> isInitialized() async {
    final kanjiCount = await (selectOnly(kanjiTable)..addColumns([kanjiTable.id.count()])).getSingle();
    return kanjiCount.read(kanjiTable.id.count())! > 0;
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'kanji_study.db'));
    return NativeDatabase(file);
  });
}
