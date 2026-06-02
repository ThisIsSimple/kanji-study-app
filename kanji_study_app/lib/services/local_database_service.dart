import 'dart:convert';
import 'package:drift/drift.dart' hide JsonKey;
import 'package:flutter/foundation.dart';
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
  static const int _wordDownloadPageSize = 1000;

  /// 서비스 초기화
  Future<void> initialize() async {
    _database = AppDatabase();
    _isInitialized = await _database.isInitialized();
    debugPrint('LocalDatabaseService initialized: $_isInitialized');
  }

  /// Supabase에서 전체 한자 데이터 다운로드 및 저장
  Future<void> downloadAndCacheKanjiData() async {
    try {
      debugPrint('Downloading kanji data from Supabase...');
      final supabaseService = SupabaseService.instance;
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
      debugPrint('Successfully cached ${kanjis.length} kanji characters');
    } catch (e) {
      debugPrint('Error downloading kanji data: $e');
      rethrow;
    }
  }

  /// Supabase에서 전체 단어 데이터 다운로드 및 저장
  Future<void> downloadAndCacheWordsData({
    void Function(int downloaded)? onProgress,
  }) async {
    try {
      debugPrint('Downloading words data from Supabase...');
      final supabaseService = SupabaseService.instance;
      var downloaded = 0;
      final downloadedIds = <int>{};

      while (true) {
        final pageStart = downloaded;
        final pageEnd = pageStart + _wordDownloadPageSize - 1;
        final response = await supabaseService.client
            .from('words')
            .select()
            .order('id', ascending: true)
            .range(pageStart, pageEnd);

        if (response.isEmpty) break;

        final words = <WordsTableCompanion>[];
        for (final json in response) {
          downloadedIds.add(json['id'] as int);
          words.add(_wordJsonToCompanion(json));
        }

        await _database.insertWordsBatch(words);

        downloaded += words.length;
        onProgress?.call(downloaded);
        debugPrint('Cached $downloaded words so far');

        if (response.length < _wordDownloadPageSize) break;
      }

      if (downloadedIds.isNotEmpty) {
        await _database.deleteWordsExceptIds(downloadedIds);
      }

      debugPrint('Successfully cached $downloaded words');
    } catch (e) {
      debugPrint('Error downloading words data: $e');
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

  Future<List<Word>> queryWords({
    String? query,
    Set<int> jlptLevels = const {},
    Set<int>? includeIds,
    Set<int> excludeIds = const {},
    int limit = 50,
    int offset = 0,
  }) async {
    final wordsData = await _database.queryWords(
      query: query,
      jlptLevels: jlptLevels,
      includeIds: includeIds,
      excludeIds: excludeIds,
      limit: limit,
      offset: offset,
    );
    return wordsData.map(_wordDataToModel).toList();
  }

  Future<int> countWords({
    String? query,
    Set<int> jlptLevels = const {},
    Set<int>? includeIds,
    Set<int> excludeIds = const {},
  }) {
    return _database.countWords(
      query: query,
      jlptLevels: jlptLevels,
      includeIds: includeIds,
      excludeIds: excludeIds,
    );
  }

  Future<List<Word>> getWordsByIds(List<int> ids) async {
    final wordsData = await _database.getWordsByIds(ids);
    return wordsData.map(_wordDataToModel).toList();
  }

  Future<List<String>> getAllWordTexts() {
    return _database.getAllWordTexts();
  }

  Future<List<int>> getWordIdsForSession({
    String? query,
    Set<int> jlptLevels = const {},
    Set<int>? includeIds,
    Set<int> excludeIds = const {},
    required int limit,
  }) {
    return _database.getWordIdsForSession(
      query: query,
      jlptLevels: jlptLevels,
      includeIds: includeIds,
      excludeIds: excludeIds,
      limit: limit,
    );
  }

  /// Drift 한자 데이터 → Kanji 모델 변환
  Kanji _kanjiDataToModel(KanjiTableData data) {
    final meaningsKo = data.meaningsKo.isNotEmpty
        ? data.meaningsKo
        : data.meanings.where(_hasKorean).toList();
    final meaningsEn = data.meaningsEn.isNotEmpty
        ? data.meaningsEn
        : data.meanings.where((meaning) => !_hasKorean(meaning)).toList();

    return Kanji(
      id: data.id,
      character: data.character,
      meanings: meaningsKo,
      meaningsKo: meaningsKo,
      meaningsEn: meaningsEn,
      krMeanings: data.krMeanings.isNotEmpty ? data.krMeanings : meaningsKo,
      jpMeanings: data.jpMeanings,
      enMeanings: data.enMeanings.isNotEmpty ? data.enMeanings : meaningsEn,
      readings: KanjiReadings(on: data.readingsOn, kun: data.readingsKun),
      jpOnReadings: data.jpOnReadings.isNotEmpty
          ? data.jpOnReadings
          : data.readingsOn,
      jpKunReadings: data.jpKunReadings.isNotEmpty
          ? data.jpKunReadings
          : data.readingsKun,
      krOnReadings: data.krOnReadings.isNotEmpty
          ? data.krOnReadings
          : data.koreanOnReadings,
      krKunReadings: data.krKunReadings.isNotEmpty
          ? data.krKunReadings
          : data.koreanKunReadings,
      koreanOnReadings: data.koreanOnReadings,
      koreanKunReadings: data.koreanKunReadings,
      grade: data.grade,
      jlpt: data.jlpt,
      strokeCount: data.strokeCount,
      examples: [], // 예문은 별도 로직으로 처리
      radical: data.radical,
      commentary: data.commentary,
      krCommentary: data.krCommentary ?? data.commentary,
      jpCommentary: data.jpCommentary,
      enCommentary: data.enCommentary,
      source: data.source,
      externalId: data.externalId,
      sourceVersion: data.sourceVersion,
      qualityStatus: data.qualityStatus,
      meaningSource: data.meaningSource,
      isCommon: data.isCommon,
      priorityRank: data.priorityRank,
      tags: data.tags,
      updatedAt: data.updatedAt,
    );
  }

  /// Supabase JSON → Drift Companion 변환 (한자)
  KanjiTableCompanion _kanjiJsonToCompanion(Map<String, dynamic> json) {
    return KanjiTableCompanion.insert(
      id: Value(json['id'] as int),
      character: json['character'] as String,
      meanings:
          (json['meanings'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      meaningsKo: Value(
        (json['meanings_ko'] as List<dynamic>?)
                ?.map((e) => e.toString())
                .toList() ??
            (json['meanings'] as List<dynamic>?)
                ?.map((e) => e.toString())
                .where(_hasKorean)
                .toList() ??
            [],
      ),
      meaningsEn: Value(
        (json['meanings_en'] as List<dynamic>?)
                ?.map((e) => e.toString())
                .toList() ??
            (json['meanings'] as List<dynamic>?)
                ?.map((e) => e.toString())
                .where((meaning) => !_hasKorean(meaning))
                .toList() ??
            [],
      ),
      krMeanings: Value(
        (json['kr_meanings'] as List<dynamic>?)
                ?.map((e) => e.toString())
                .toList() ??
            (json['meanings_ko'] as List<dynamic>?)
                ?.map((e) => e.toString())
                .toList() ??
            (json['meanings'] as List<dynamic>?)
                ?.map((e) => e.toString())
                .where(_hasKorean)
                .toList() ??
            [],
      ),
      jpMeanings: Value(
        (json['jp_meanings'] as List<dynamic>?)
                ?.map((e) => e.toString())
                .toList() ??
            [],
      ),
      enMeanings: Value(
        (json['en_meanings'] as List<dynamic>?)
                ?.map((e) => e.toString())
                .toList() ??
            (json['meanings_en'] as List<dynamic>?)
                ?.map((e) => e.toString())
                .toList() ??
            [],
      ),
      readingsOn:
          (json['on_readings'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      readingsKun:
          (json['kun_readings'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      jpOnReadings: Value(
        (json['jp_on_readings'] as List<dynamic>?)
                ?.map((e) => e.toString())
                .toList() ??
            (json['on_readings'] as List<dynamic>?)
                ?.map((e) => e.toString())
                .toList() ??
            [],
      ),
      jpKunReadings: Value(
        (json['jp_kun_readings'] as List<dynamic>?)
                ?.map((e) => e.toString())
                .toList() ??
            (json['kun_readings'] as List<dynamic>?)
                ?.map((e) => e.toString())
                .toList() ??
            [],
      ),
      krOnReadings: Value(
        (json['kr_on_readings'] as List<dynamic>?)
                ?.map((e) => e.toString())
                .toList() ??
            (json['korean_on_readings'] as List<dynamic>?)
                ?.map((e) => e.toString())
                .toList() ??
            [],
      ),
      krKunReadings: Value(
        (json['kr_kun_readings'] as List<dynamic>?)
                ?.map((e) => e.toString())
                .toList() ??
            (json['korean_kun_readings'] as List<dynamic>?)
                ?.map((e) => e.toString())
                .toList() ??
            [],
      ),
      koreanOnReadings:
          (json['korean_on_readings'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      koreanKunReadings:
          (json['korean_kun_readings'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      grade: json['grade'] as int,
      jlpt: json['jlpt'] as int,
      strokeCount: json['stroke_count'] as int,
      examples: const Value([]), // 예문은 별도 테이블로 관리 예정
      radical: Value(json['radical'] as String?),
      commentary: Value(json['commentary'] as String?),
      krCommentary: Value(
        (json['kr_commentary'] as String?) ?? (json['commentary'] as String?),
      ),
      jpCommentary: Value(json['jp_commentary'] as String?),
      enCommentary: Value(json['en_commentary'] as String?),
      source: Value(json['source'] as String? ?? 'legacy_excel'),
      externalId: Value(json['external_id'] as String?),
      sourceVersion: Value(json['source_version'] as String?),
      qualityStatus: Value(json['quality_status'] as String? ?? 'reviewed'),
      meaningSource: Value(json['meaning_source'] as String? ?? 'legacy_excel'),
      isCommon: Value(json['is_common'] as bool? ?? false),
      priorityRank: Value(json['priority_rank'] as int?),
      tags: Value(
        (json['tags'] as List<dynamic>?)?.map((e) => e.toString()).toList() ??
            [],
      ),
      updatedAt: Value(_parseDateTime(json['updated_at'])),
    );
  }

  /// Drift 단어 데이터 → Word 모델 변환
  Word _wordDataToModel(WordsTableData data) {
    final word = Word.fromJson({
      'id': data.id,
      'word': data.word,
      'reading': data.reading,
      'meanings': jsonDecode(data.meanings),
      'meanings_ko': jsonDecode(data.meaningsKo),
      'meanings_en': jsonDecode(data.meaningsEn),
      'meanings_jp': jsonDecode(data.meaningsJp),
      'jlpt_level': data.jlptLevel,
      'source': data.source,
      'external_id': data.externalId,
      'source_version': data.sourceVersion,
      'quality_status': data.qualityStatus,
      'meaning_source': data.meaningSource,
      'is_common': data.isCommon,
      'priority_rank': data.priorityRank,
      'tags': data.tags,
      'updated_at': data.updatedAt?.toUtc().toIso8601String(),
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
      meaningsKo: Value(
        jsonEncode(
          json['meanings_ko'] ?? _filterWordMeanings(json['meanings'], true),
        ),
      ),
      meaningsEn: Value(
        jsonEncode(
          json['meanings_en'] ?? _filterWordMeanings(json['meanings'], false),
        ),
      ),
      meaningsJp: Value(jsonEncode(json['meanings_jp'] ?? [])),
      jlptLevel: json['jlpt_level'] as int,
      source: Value(json['source'] as String? ?? 'legacy_naver'),
      externalId: Value(json['external_id'] as String?),
      sourceVersion: Value(json['source_version'] as String?),
      qualityStatus: Value(json['quality_status'] as String? ?? 'reviewed'),
      meaningSource: Value(json['meaning_source'] as String? ?? 'legacy_naver'),
      isCommon: Value(json['is_common'] as bool? ?? false),
      priorityRank: Value(json['priority_rank'] as int?),
      tags: Value(
        (json['tags'] as List<dynamic>?)?.map((e) => e.toString()).toList() ??
            [],
      ),
      updatedAt: Value(_parseDateTime(json['updated_at'])),
    );
  }

  DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    return DateTime.tryParse(value.toString());
  }

  static bool _hasKorean(String value) => RegExp(r'[가-힣]').hasMatch(value);

  static List<dynamic> _filterWordMeanings(dynamic meanings, bool korean) {
    if (meanings is! List) {
      return [];
    }
    return meanings.where((meaning) {
      if (meaning is Map<String, dynamic>) {
        return _hasKorean(meaning['meaning']?.toString() ?? '') == korean;
      }
      if (meaning is Map) {
        return _hasKorean(meaning['meaning']?.toString() ?? '') == korean;
      }
      return _hasKorean(meaning.toString()) == korean;
    }).toList();
  }

  /// 데이터베이스 종료
  Future<void> dispose() async {
    await _database.close();
  }
}
