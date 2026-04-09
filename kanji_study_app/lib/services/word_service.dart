import 'package:flutter/foundation.dart';
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
    await _favoriteService.toggleFavorite(type: 'word', targetId: wordId);
  }

  // Get favorite words
  List<Word> getFavoriteWords() {
    final favoriteIds = _favoriteService.getFavoriteIds('word');
    return _allWords.where((word) => favoriteIds.contains(word.id)).toList();
  }

  // Get word by ID
  Word? getWordById(int id) {
    try {
      return _allWords.firstWhere((word) => word.id == id);
    } catch (e) {
      return null;
    }
  }
}
