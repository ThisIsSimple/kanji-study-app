import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/word_model.dart';
import 'supabase_service.dart';

class WordService {
  static final WordService _instance = WordService._internal();
  static WordService get instance => _instance;
  
  WordService._internal();
  
  final SupabaseService _supabaseService = SupabaseService.instance;
  List<Word> _allWords = [];
  final Set<int> _favoriteWordIds = {};
  bool _isInitialized = false;
  
  // Get all words
  List<Word> get allWords => List.unmodifiable(_allWords);
  
  // Check if service is initialized
  bool get isInitialized => _isInitialized;
  
  // Initialize service
  Future<void> init() async {
    if (_isInitialized) return;
    
    await _loadWords();
    await _loadFavorites();
    _isInitialized = true;
  }
  
  // Force reload data
  Future<void> reloadData() async {
    _isInitialized = false;
    _allWords.clear();
    await init();
  }
  
  // Load words from Supabase
  Future<void> _loadWords() async {
    try {
      final response = await _supabaseService.client
          .from('words')
          .select('*')
          .order('id', ascending: true);
      
      _allWords = (response as List)
          .map((data) => Word.fromJson(data))
          .toList();
      
      debugPrint('Loaded ${_allWords.length} words from database');
    } catch (e) {
      debugPrint('Error loading words: $e');
      _allWords = [];
    }
  }
  
  // Load favorites from SharedPreferences
  Future<void> _loadFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    final favoritesData = prefs.getStringList('favorite_words') ?? [];
    _favoriteWordIds.clear();
    _favoriteWordIds.addAll(favoritesData.map((id) => int.tryParse(id) ?? 0));
  }
  
  // Save favorites to SharedPreferences
  Future<void> _saveFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      'favorite_words', 
      _favoriteWordIds.map((id) => id.toString()).toList()
    );
  }
  
  // Check if word is favorite
  bool isFavorite(int wordId) {
    return _favoriteWordIds.contains(wordId);
  }
  
  // Toggle favorite status
  Future<void> toggleFavorite(int wordId) async {
    if (_favoriteWordIds.contains(wordId)) {
      _favoriteWordIds.remove(wordId);
    } else {
      _favoriteWordIds.add(wordId);
    }
    await _saveFavorites();
  }
  
  // Get favorite words
  List<Word> getFavoriteWords() {
    return _allWords.where((word) => _favoriteWordIds.contains(word.id)).toList();
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
    final stats = <String, int>{
      'total': _allWords.length,
      'favorites': _favoriteWordIds.length,
    };
    
    // Count by JLPT level
    for (int level = 1; level <= 5; level++) {
      stats['jlpt_n$level'] = _allWords.where((w) => w.jlptLevel == level).length;
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