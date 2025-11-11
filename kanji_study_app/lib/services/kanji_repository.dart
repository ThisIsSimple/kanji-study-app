import '../models/kanji_model.dart';
import 'supabase_service.dart';
import 'local_database_service.dart';
import 'connectivity_service.dart';

class KanjiRepository {
  static final KanjiRepository _instance = KanjiRepository._internal();
  static KanjiRepository get instance => _instance;

  KanjiRepository._internal();

  final SupabaseService _supabaseService = SupabaseService.instance;
  final LocalDatabaseService _localDbService = LocalDatabaseService.instance;
  final ConnectivityService _connectivityService = ConnectivityService.instance;

  List<Kanji>? _kanjiList;
  Map<String, Kanji>? _kanjiMap;

  Future<void> loadKanjiData() async {
    if (_kanjiList != null) return; // Already loaded

    try {
      // 1. 로컬 DB에서 먼저 로드 시도
      _kanjiList = await _localDbService.getAllKanji();

      // 2. 로컬 DB가 비어있으면 초기 다운로드 필요
      if (_kanjiList!.isEmpty) {
        if (_connectivityService.isOnline) {
          print('Local DB is empty. Downloading from Supabase...');
          await _localDbService.downloadAndCacheKanjiData();
          _kanjiList = await _localDbService.getAllKanji();
        } else {
          print('Offline and no cached data. Cannot load kanji.');
          throw Exception('초기 데이터 다운로드를 위해 인터넷 연결이 필요합니다.');
        }
      }

      // 3. Create lookup maps for efficient access
      _createLookupMaps();

      // 4. 백그라운드에서 업데이트 확인 (온라인인 경우)
      if (_connectivityService.isOnline) {
        _checkForUpdatesInBackground();
      }
    } catch (e) {
      print('Error loading kanji data: $e');
      _kanjiList = [];
      rethrow;
    }
  }

  /// 백그라운드에서 Supabase 업데이트 확인 (비차단)
  Future<void> _checkForUpdatesInBackground() async {
    try {
      // TODO: 마지막 업데이트 시간 확인 후 필요시에만 동기화
      // 현재는 매번 확인하지 않음 (성능상)
    } catch (e) {
      print('Background update check failed: $e');
    }
  }

  void _createLookupMaps() {
    if (_kanjiList == null) return;

    // Character -> Kanji map
    _kanjiMap = {};
    for (final kanji in _kanjiList!) {
      _kanjiMap![kanji.character] = kanji;
    }
  }

  // Clear cached data
  void clearCache() {
    _kanjiList = null;
    _kanjiMap = null;
  }

  // Force reload data from Supabase
  Future<void> reloadKanjiData() async {
    clearCache();
    await loadKanjiData();
  }

  // Get all kanji
  List<Kanji> getAllKanji() {
    return _kanjiList ?? [];
  }

  // Get kanji by character
  Kanji? getKanjiByCharacter(String character) {
    return _kanjiMap?[character];
  }

  // Get kanji by ID
  Kanji? getKanjiById(int id) {
    if (_kanjiList == null) return null;
    try {
      return _kanjiList!.firstWhere((kanji) => kanji.id == id);
    } catch (e) {
      return null;
    }
  }

  // Grade and JLPT methods removed - data is empty in current dataset

  // Search kanji by meaning
  List<Kanji> searchByMeaning(String query) {
    if (_kanjiList == null) return [];

    final lowerQuery = query.toLowerCase();
    return _kanjiList!.where((kanji) {
      return kanji.meanings.any(
        (meaning) => meaning.toLowerCase().contains(lowerQuery),
      );
    }).toList();
  }

  // Search kanji by reading (Japanese and Korean)
  List<Kanji> searchByReading(String query) {
    if (_kanjiList == null) return [];

    return _kanjiList!.where((kanji) {
      // Search in Japanese readings
      final japaneseMatch = kanji.readings.all.any(
        (reading) => reading.contains(query),
      );

      // Search in Korean readings
      final koreanMatch = [
        ...kanji.koreanOnReadings,
        ...kanji.koreanKunReadings,
      ].any((reading) => reading.contains(query));

      return japaneseMatch || koreanMatch;
    }).toList();
  }

  // Get kanji within frequency range
  List<Kanji> getKanjiByFrequencyRange(int start, int end) {
    if (_kanjiList == null) return [];

    return _kanjiList!.where((kanji) {
      return kanji.frequency >= start && kanji.frequency <= end;
    }).toList();
  }

  // Get random kanji
  List<Kanji> getRandomKanji({int count = 1}) {
    List<Kanji> candidates = _kanjiList ?? [];

    if (candidates.isEmpty) return [];

    // Shuffle and take first 'count' items
    candidates.shuffle();
    return candidates.take(count).toList();
  }
}
