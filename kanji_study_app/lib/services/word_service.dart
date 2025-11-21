import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/word_model.dart';
import '../repositories/word_repository.dart';
import 'favorite_service.dart';

class WordService {
  static final WordService _instance = WordService._internal();
  static WordService get instance => _instance;

  WordService._internal();

  final WordRepository _wordRepository = WordRepository.instance;
  final FavoriteService _favoriteService = FavoriteService.instance;
  List<Word> _allWords = [];
  bool _isInitialized = false;

  // Get all words
  List<Word> get allWords => List.unmodifiable(_allWords);

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
    await _loadWords();
    _isInitialized = true;
  }

  // Load words from Repository (로컬 DB 우선)
  Future<void> _loadWords() async {
    try {
      await _wordRepository.loadWordsData();
      _allWords = _wordRepository.getAllWords();

      debugPrint('Loaded ${_allWords.length} words from database');
    } catch (e) {
      debugPrint('Error loading words: $e');
      _allWords = [];
      rethrow;
    }
  }

  // Check if word is favorite
  bool isFavorite(int wordId) {
    return _favoriteService.isFavorite('word', wordId);
  }

  // Toggle favorite status
  Future<void> toggleFavorite(int wordId) async {
    await _favoriteService.toggleFavorite(
      type: 'word',
      targetId: wordId,
    );
  }

  // Get favorite words
  List<Word> getFavoriteWords() {
    final favoriteIds = _favoriteService.getFavoriteIds('word');
    return _allWords
        .where((word) => favoriteIds.contains(word.id))
        .toList();
  }

  // Search words by query
  List<Word> searchWords(String query, {int? jlptLevel}) {
    if (query.isEmpty && jlptLevel == null) {
      return _allWords;
    }

    List<Word> results = _allWords;

    // Filter by JLPT level if specified
    if (jlptLevel != null) {
      results = results.where((word) => word.jlptLevel == jlptLevel).toList();
    }

    // Filter by search query if specified
    if (query.isNotEmpty) {
      results = results.where((word) => word.matchesQuery(query)).toList();
    }

    return results;
  }

  // Get words by JLPT level
  List<Word> getWordsByJlptLevel(int level) {
    return _allWords.where((word) => word.jlptLevel == level).toList();
  }

  // Get word by ID
  Word? getWordById(int id) {
    try {
      return _allWords.firstWhere((word) => word.id == id);
    } catch (e) {
      return null;
    }
  }

  // Get statistics
  Map<String, int> getStatistics() {
    final favoriteIds = _favoriteService.getFavoriteIds('word');
    final stats = <String, int>{
      'total': _allWords.length,
      'favorites': favoriteIds.length,
    };

    // Count by JLPT level
    for (int level = 1; level <= 5; level++) {
      stats['jlpt_n$level'] = _allWords
          .where((w) => w.jlptLevel == level)
          .length;
    }

    return stats;
  }

  // Get recently viewed words (for future implementation)
  Future<List<int>> getRecentlyViewedIds() async {
    final prefs = await SharedPreferences.getInstance();
    final recentData = prefs.getString('recently_viewed_words');

    if (recentData != null) {
      final List<dynamic> decoded = json.decode(recentData);
      return decoded.map((id) => id as int).toList();
    }

    return [];
  }

  // Add to recently viewed (for future implementation)
  Future<void> addToRecentlyViewed(int wordId) async {
    final prefs = await SharedPreferences.getInstance();
    final recent = await getRecentlyViewedIds();

    // Remove if already exists
    recent.remove(wordId);

    // Add to beginning
    recent.insert(0, wordId);

    // Keep only last 50
    if (recent.length > 50) {
      recent.removeRange(50, recent.length);
    }

    await prefs.setString('recently_viewed_words', json.encode(recent));
  }
}
