import 'package:flutter/foundation.dart';
import '../models/word_model.dart';
import '../services/local_database_service.dart';
import '../services/connectivity_service.dart';

class WordRepository {
  static final WordRepository _instance = WordRepository._internal();
  static WordRepository get instance => _instance;

  WordRepository._internal();

  final LocalDatabaseService _localDbService = LocalDatabaseService.instance;
  final ConnectivityService _connectivityService = ConnectivityService.instance;

  static const int _maxCachedWords = 1000;
  final Map<int, Word> _wordCache = {};
  bool _isInitialized = false;

  Future<void> loadWordsData() async {
    if (_isInitialized) return;

    try {
      final localWordCount = await _localDbService.countWords();

      if (localWordCount == 0) {
        if (_connectivityService.isOnline) {
          debugPrint('Local DB is empty. Downloading words from Supabase...');
          await _localDbService.downloadAndCacheWordsData();
        } else {
          debugPrint('Offline and no cached data. Cannot load words.');
          throw Exception('초기 데이터 다운로드를 위해 인터넷 연결이 필요합니다.');
        }
      }

      _isInitialized = true;
      if (_connectivityService.isOnline) {
        _checkForUpdatesInBackground();
      }
    } catch (e) {
      debugPrint('Error loading words data: $e');
      rethrow;
    }
  }

  /// 백그라운드에서 Supabase 업데이트 확인 (비차단)
  Future<void> _checkForUpdatesInBackground() async {
    try {
      // TODO: 마지막 업데이트 시간 확인 후 필요시에만 동기화
      // 현재는 매번 확인하지 않음 (성능상)
    } catch (e) {
      debugPrint('Background update check failed: $e');
    }
  }

  // Clear cached data
  void clearCache() {
    _isInitialized = false;
    _wordCache.clear();
  }

  Future<void> refreshWords({void Function(int downloaded)? onProgress}) async {
    if (!_connectivityService.isOnline) {
      _isInitialized = true;
      return;
    }

    await _localDbService.downloadAndCacheWordsData(onProgress: onProgress);
    _isInitialized = true;
  }

  Word? getWordById(int id) {
    return _wordCache[id];
  }

  Future<Word?> getWordByIdAsync(int id) async {
    final cached = _wordCache[id];
    if (cached != null) return cached;
    final word = await _localDbService.getWordById(id);
    if (word != null) _cacheWords([word]);
    return word;
  }

  Future<List<Word>> queryWords({
    String? query,
    Set<int> jlptLevels = const {},
    Set<int>? includeIds,
    Set<int> excludeIds = const {},
    int limit = 50,
    int offset = 0,
  }) async {
    await loadWordsData();
    final words = await _localDbService.queryWords(
      query: query,
      jlptLevels: jlptLevels,
      includeIds: includeIds,
      excludeIds: excludeIds,
      limit: limit,
      offset: offset,
    );
    _cacheWords(words);
    return words;
  }

  Future<int> countWords({
    String? query,
    Set<int> jlptLevels = const {},
    Set<int>? includeIds,
    Set<int> excludeIds = const {},
  }) async {
    await loadWordsData();
    return _localDbService.countWords(
      query: query,
      jlptLevels: jlptLevels,
      includeIds: includeIds,
      excludeIds: excludeIds,
    );
  }

  Future<List<Word>> getWordsByIds(List<int> ids) async {
    await loadWordsData();
    final missingIds = ids.where((id) => !_wordCache.containsKey(id)).toList();
    if (missingIds.isNotEmpty) {
      final loaded = await _localDbService.getWordsByIds(missingIds);
      _cacheWords(loaded);
    }
    return ids.map((id) => _wordCache[id]).whereType<Word>().toList();
  }

  Future<List<String>> getAllWordTexts() async {
    await loadWordsData();
    return _localDbService.getAllWordTexts();
  }

  Future<List<int>> getWordIdsForSession({
    String? query,
    Set<int> jlptLevels = const {},
    Set<int>? includeIds,
    Set<int> excludeIds = const {},
    required int limit,
  }) async {
    await loadWordsData();
    return _localDbService.getWordIdsForSession(
      query: query,
      jlptLevels: jlptLevels,
      includeIds: includeIds,
      excludeIds: excludeIds,
      limit: limit,
    );
  }

  void _cacheWords(Iterable<Word> words) {
    for (final word in words) {
      _wordCache[word.id] = word;
    }

    while (_wordCache.length > _maxCachedWords) {
      _wordCache.remove(_wordCache.keys.first);
    }
  }
}
