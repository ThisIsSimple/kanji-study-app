import 'package:flutter/foundation.dart';
import '../models/word_model.dart';
import '../repositories/word_repository.dart';
import 'favorite_service.dart';
import 'study_record_service.dart';
import '../models/study_record_model.dart';

class WordService {
  static final WordService _instance = WordService._internal();
  static WordService get instance => _instance;

  WordService._internal();

  final WordRepository _wordRepository = WordRepository.instance;
  final FavoriteService _favoriteService = FavoriteService.instance;
  final StudyRecordService _studyRecordService = StudyRecordService.instance;
  bool _isInitialized = false;

  List<Word> get allWords => const [];

  // Check if service is initialized
  bool get isInitialized => _isInitialized;

  // Initialize service
  Future<void> init() async {
    if (_isInitialized) return;

    await _loadWords();
    _isInitialized = true;
  }

  // Force reload data
  Future<void> reloadData() async {
    _isInitialized = false;
    _wordRepository.clearCache(); // Clear repository cache first
    await _wordRepository.refreshWords();
    _isInitialized = true;
  }

  // Load words from Repository (로컬 DB 우선)
  Future<void> _loadWords() async {
    try {
      await _wordRepository.loadWordsData();
      debugPrint('Word database is ready');
    } catch (e) {
      debugPrint('Error loading words: $e');
      rethrow;
    }
  }

  Future<List<Word>> queryWords({
    String? query,
    Set<int> jlptLevels = const {},
    bool favoriteOnly = false,
    String? studyFilter,
    int limit = 50,
    int offset = 0,
  }) {
    final wordFilter = _buildWordFilter(
      favoriteOnly: favoriteOnly,
      studyFilter: studyFilter,
    );
    return _wordRepository.queryWords(
      query: query,
      jlptLevels: jlptLevels,
      includeIds: wordFilter.includeIds,
      excludeIds: wordFilter.excludeIds,
      limit: limit,
      offset: offset,
    );
  }

  Future<int> countWords({
    String? query,
    Set<int> jlptLevels = const {},
    bool favoriteOnly = false,
    String? studyFilter,
  }) {
    final wordFilter = _buildWordFilter(
      favoriteOnly: favoriteOnly,
      studyFilter: studyFilter,
    );
    return _wordRepository.countWords(
      query: query,
      jlptLevels: jlptLevels,
      includeIds: wordFilter.includeIds,
      excludeIds: wordFilter.excludeIds,
    );
  }

  Future<List<Word>> getWordsForFlashcardSession({
    String? query,
    Set<int> jlptLevels = const {},
    bool favoriteOnly = false,
    String? studyFilter,
    required int limit,
  }) async {
    final wordFilter = _buildWordFilter(
      favoriteOnly: favoriteOnly,
      studyFilter: studyFilter,
    );
    final ids = await _wordRepository.getWordIdsForSession(
      query: query,
      jlptLevels: jlptLevels,
      includeIds: wordFilter.includeIds,
      excludeIds: wordFilter.excludeIds,
      limit: limit,
    );
    return _wordRepository.getWordsByIds(ids);
  }

  Future<List<Word>> getWordsByIds(List<int> ids) {
    return _wordRepository.getWordsByIds(ids);
  }

  Future<List<String>> getAllWordTexts() {
    return _wordRepository.getAllWordTexts();
  }

  // Check if word is favorite
  bool isFavorite(int wordId) {
    return _favoriteService.isFavorite('word', wordId);
  }

  // Toggle favorite status
  Future<void> toggleFavorite(int wordId) async {
    await _favoriteService.toggleFavorite(type: 'word', targetId: wordId);
  }

  // Get favorite words
  // Get word by ID
  Word? getWordById(int id) {
    return _wordRepository.getWordById(id);
  }

  Future<Word?> getWordByIdAsync(int id) {
    return _wordRepository.getWordByIdAsync(id);
  }

  _WordDbFilter _buildWordFilter({
    required bool favoriteOnly,
    required String? studyFilter,
  }) {
    Set<int>? includeIds;
    final excludeIds = <int>{};

    if (favoriteOnly) {
      includeIds = _favoriteService.getFavoriteIds('word').toSet();
    }

    if (studyFilter != null) {
      final progressById = _studyRecordService.getProgressByType(
        StudyType.word,
      );

      switch (studyFilter) {
        case 'not_studied':
          excludeIds.addAll(progressById.keys);
          break;
        case 'completed':
          final completedIds = progressById.entries
              .where(
                (entry) =>
                    entry.value.lastStatus == StudyStatus.completed ||
                    entry.value.lastStatus == StudyStatus.mastered,
              )
              .map((entry) => entry.key)
              .toSet();
          includeIds = _intersectIncludeIds(includeIds, completedIds);
          break;
        case 'forgot':
          final forgotIds = progressById.entries
              .where((entry) => entry.value.lastStatus == StudyStatus.forgot)
              .map((entry) => entry.key)
              .toSet();
          includeIds = _intersectIncludeIds(includeIds, forgotIds);
          break;
      }
    }

    return _WordDbFilter(includeIds: includeIds, excludeIds: excludeIds);
  }

  Set<int> _intersectIncludeIds(Set<int>? current, Set<int> next) {
    if (current == null) return next;
    return current.intersection(next);
  }
}

class _WordDbFilter {
  final Set<int>? includeIds;
  final Set<int> excludeIds;

  const _WordDbFilter({required this.includeIds, required this.excludeIds});
}
