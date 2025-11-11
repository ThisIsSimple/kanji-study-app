import 'dart:convert';
import 'package:drift/drift.dart' hide JsonKey;
import '../database/app_database.dart';
import '../models/kanji_model.dart';
import '../models/word_model.dart';
import 'supabase_service.dart';

/// 로컬 데이터베이스 관리 서비스 (싱글톤)
class LocalDatabaseService {
  static final LocalDatabaseService _instance =
      LocalDatabaseService._internal();
  static LocalDatabaseService get instance => _instance;

  LocalDatabaseService._internal();

  late final AppDatabase _database;
  bool _isInitialized = false;

  AppDatabase get database => _database;
  bool get isInitialized => _isInitialized;

  /// 서비스 초기화
  Future<void> initialize() async {
    _database = AppDatabase();
    _isInitialized = await _database.isInitialized();
    print('LocalDatabaseService initialized: $_isInitialized');
  }

  /// Supabase에서 전체 한자 데이터 다운로드 및 저장
  Future<void> downloadAndCacheKanjiData() async {
    try {
      print('Downloading kanji data from Supabase...');
      final supabaseService = SupabaseService();
      final response = await supabaseService.client
          .from('kanji')
          .select()
          .order('id', ascending: true);

      final List<KanjiTableCompanion> kanjis = [];
      for (final json in response) {
        kanjis.add(_kanjiJsonToCompanion(json));
      }

      // 기존 데이터 삭제 후 새 데이터 삽입
      await _database.clearKanji();
      await _database.insertKanjiBatch(kanjis);

      _isInitialized = true;
      print('Successfully cached ${kanjis.length} kanji characters');
    } catch (e) {
      print('Error downloading kanji data: $e');
      rethrow;
    }
  }

  /// Supabase에서 전체 단어 데이터 다운로드 및 저장
  Future<void> downloadAndCacheWordsData() async {
    try {
      print('Downloading words data from Supabase...');
      final supabaseService = SupabaseService();
      final response = await supabaseService.client
          .from('words')
          .select()
          .order('id', ascending: true);

      final List<WordsTableCompanion> words = [];
      for (final json in response) {
        words.add(_wordJsonToCompanion(json));
      }

      // 기존 데이터 삭제 후 새 데이터 삽입
      await _database.clearWords();
      await _database.insertWordsBatch(words);

      print('Successfully cached ${words.length} words');
    } catch (e) {
      print('Error downloading words data: $e');
      rethrow;
    }
  }

  /// 한자 데이터 조회
  Future<List<Kanji>> getAllKanji() async {
    final kanjiData = await _database.getAllKanji();
    return kanjiData.map(_kanjiDataToModel).toList();
  }

  Future<Kanji?> getKanjiById(int id) async {
    final kanjiData = await _database.getKanjiById(id);
    return kanjiData != null ? _kanjiDataToModel(kanjiData) : null;
  }

  Future<Kanji?> getKanjiByCharacter(String character) async {
    final kanjiData = await _database.getKanjiByCharacter(character);
    return kanjiData != null ? _kanjiDataToModel(kanjiData) : null;
  }

  /// 단어 데이터 조회
  Future<List<Word>> getAllWords() async {
    final wordsData = await _database.getAllWords();
    return wordsData.map(_wordDataToModel).toList();
  }

  Future<Word?> getWordById(int id) async {
    final wordData = await _database.getWordById(id);
    return wordData != null ? _wordDataToModel(wordData) : null;
  }

  /// Drift 한자 데이터 → Kanji 모델 변환
  Kanji _kanjiDataToModel(KanjiTableData data) {
    return Kanji(
      id: data.id,
      character: data.character,
      meanings: data.meanings,
      readings: KanjiReadings(
        on: data.readingsOn,
        kun: data.readingsKun,
      ),
      koreanOnReadings: data.koreanOnReadings,
      koreanKunReadings: data.koreanKunReadings,
      grade: data.grade,
      jlpt: data.jlpt,
      strokeCount: data.strokeCount,
      frequency: data.frequency,
      examples: [], // 예문은 별도 로직으로 처리
    );
  }

  /// Supabase JSON → Drift Companion 변환 (한자)
  KanjiTableCompanion _kanjiJsonToCompanion(Map<String, dynamic> json) {
    final readings = json['readings'] as Map<String, dynamic>? ?? {};

    return KanjiTableCompanion.insert(
      id: Value(json['id'] as int),
      character: json['character'] as String,
      meanings: (json['meanings'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      readingsOn: (readings['on'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      readingsKun: (readings['kun'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      koreanOnReadings: (json['korean_on_readings'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      koreanKunReadings: (json['korean_kun_readings'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      grade: json['grade'] as int,
      jlpt: json['jlpt'] as int,
      strokeCount: json['strokeCount'] as int,
      frequency: json['frequency'] as int,
      examples: [], // 예문은 별도 테이블로 관리 예정
    );
  }

  /// Drift 단어 데이터 → Word 모델 변환
  Word _wordDataToModel(WordsTableData data) {
    final word = Word.fromJson({
      'id': data.id,
      'word': data.word,
      'reading': data.reading,
      'meanings': jsonDecode(data.meanings),
      'jlpt_level': data.jlptLevel,
    });
    return word;
  }

  /// Supabase JSON → Drift Companion 변환 (단어)
  WordsTableCompanion _wordJsonToCompanion(Map<String, dynamic> json) {
    return WordsTableCompanion.insert(
      id: Value(json['id'] as int),
      word: json['word'] as String,
      reading: json['reading'] as String,
      meanings: jsonEncode(json['meanings']),
      jlptLevel: json['jlpt_level'] as int,
    );
  }

  /// 데이터베이스 종료
  Future<void> dispose() async {
    await _database.close();
  }
}
