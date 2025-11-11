import '../models/word_model.dart';
import '../services/supabase_service.dart';
import '../services/local_database_service.dart';
import '../services/connectivity_service.dart';

class WordRepository {
  static final WordRepository _instance = WordRepository._internal();
  static WordRepository get instance => _instance;

  WordRepository._internal();

  final SupabaseService _supabaseService = SupabaseService.instance;
  final LocalDatabaseService _localDbService = LocalDatabaseService.instance;
  final ConnectivityService _connectivityService = ConnectivityService.instance;

  List<Word>? _wordList;
  Map<int, Word>? _wordMap;

  Future<void> loadWordsData() async {
    if (_wordList != null) return; // Already loaded

    try {
      // 1. 로컬 DB에서 먼저 로드 시도
      _wordList = await _localDbService.getAllWords();

      // 2. 로컬 DB가 비어있으면 초기 다운로드 필요
      if (_wordList!.isEmpty) {
        if (_connectivityService.isOnline) {
          print('Local DB is empty. Downloading words from Supabase...');
          await _localDbService.downloadAndCacheWordsData();
          _wordList = await _localDbService.getAllWords();
        } else {
          print('Offline and no cached data. Cannot load words.');
          throw Exception('초기 데이터 다운로드를 위해 인터넷 연결이 필요합니다.');
        }
      }

      // 3. Create lookup map for efficient access
      _createLookupMap();

      // 4. 백그라운드에서 업데이트 확인 (온라인인 경우)
      if (_connectivityService.isOnline) {
        _checkForUpdatesInBackground();
      }
    } catch (e) {
      print('Error loading words data: $e');
      _wordList = [];
      rethrow;
    }
  }

  void _createLookupMap() {
    if (_wordList == null) return;

    // ID -> Word map
    _wordMap = {};
    for (final word in _wordList!) {
      _wordMap![word.id] = word;
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

  // Clear cached data
  void clearCache() {
    _wordList = null;
    _wordMap = null;
  }

  // Force reload data
  Future<void> reloadWordsData() async {
    clearCache();
    await loadWordsData();
  }

  // Get all words
  List<Word> getAllWords() {
    return _wordList ?? [];
  }

  // Get word by ID
  Word? getWordById(int id) {
    return _wordMap?[id];
  }

  // Get words by JLPT level
  List<Word> getWordsByJlptLevel(int level) {
    if (_wordList == null) return [];
    return _wordList!.where((word) => word.jlptLevel == level).toList();
  }

  // Search words by query
  List<Word> searchWords(String query) {
    if (_wordList == null) return [];
    final lowerQuery = query.toLowerCase();

    return _wordList!.where((word) {
      return word.word.toLowerCase().contains(lowerQuery) ||
          word.reading.toLowerCase().contains(lowerQuery) ||
          word.meaningsText.toLowerCase().contains(lowerQuery);
    }).toList();
  }

  // Get random words
  List<Word> getRandomWords({int count = 1}) {
    List<Word> candidates = _wordList ?? [];

    if (candidates.isEmpty) return [];

    // Shuffle and take first 'count' items
    candidates.shuffle();
    return candidates.take(count).toList();
  }
}
