import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/kanji_model.dart';

class KanjiRepository {
  static final KanjiRepository _instance = KanjiRepository._internal();
  static KanjiRepository get instance => _instance;
  
  KanjiRepository._internal();
  
  List<Kanji>? _kanjiList;
  Map<String, Kanji>? _kanjiMap;
  Map<int, List<Kanji>>? _gradeMap;
  Map<int, List<Kanji>>? _jlptMap;
  
  Future<void> loadKanjiData() async {
    if (_kanjiList != null) return; // Already loaded
    
    try {
      // Load JSON from assets
      final String jsonString = await rootBundle.loadString('assets/data/kanji_data.json');
      final Map<String, dynamic> jsonData = json.decode(jsonString);
      
      // Parse kanji list
      final List<dynamic> kanjiJsonList = jsonData['kanji'] as List;
      _kanjiList = kanjiJsonList.map((json) => Kanji.fromJson(json)).toList();
      
      // Create lookup maps for efficient access
      _createLookupMaps();
    } catch (e) {
      // In production, you might want to use a proper logging service
      // For now, we'll just initialize with empty list
      _kanjiList = [];
    }
  }
  
  void _createLookupMaps() {
    if (_kanjiList == null) return;
    
    // Character -> Kanji map
    _kanjiMap = {};
    for (final kanji in _kanjiList!) {
      _kanjiMap![kanji.character] = kanji;
    }
    
    // Grade -> List<Kanji> map
    _gradeMap = {};
    for (final kanji in _kanjiList!) {
      _gradeMap!.putIfAbsent(kanji.grade, () => []).add(kanji);
    }
    
    // JLPT -> List<Kanji> map
    _jlptMap = {};
    for (final kanji in _kanjiList!) {
      _jlptMap!.putIfAbsent(kanji.jlpt, () => []).add(kanji);
    }
  }
  
  // Get all kanji
  List<Kanji> getAllKanji() {
    return _kanjiList ?? [];
  }
  
  // Get kanji by character
  Kanji? getKanjiByCharacter(String character) {
    return _kanjiMap?[character];
  }
  
  // Get kanji by grade
  List<Kanji> getKanjiByGrade(int grade) {
    return _gradeMap?[grade] ?? [];
  }
  
  // Get kanji by JLPT level
  List<Kanji> getKanjiByJlpt(int jlptLevel) {
    return _jlptMap?[jlptLevel] ?? [];
  }
  
  // Search kanji by meaning
  List<Kanji> searchByMeaning(String query) {
    if (_kanjiList == null) return [];
    
    final lowerQuery = query.toLowerCase();
    return _kanjiList!.where((kanji) {
      return kanji.meanings.any((meaning) => 
        meaning.toLowerCase().contains(lowerQuery)
      );
    }).toList();
  }
  
  // Search kanji by reading
  List<Kanji> searchByReading(String query) {
    if (_kanjiList == null) return [];
    
    return _kanjiList!.where((kanji) {
      return kanji.readings.all.any((reading) => 
        reading.contains(query)
      );
    }).toList();
  }
  
  // Get kanji within frequency range
  List<Kanji> getKanjiByFrequencyRange(int start, int end) {
    if (_kanjiList == null) return [];
    
    return _kanjiList!.where((kanji) {
      return kanji.frequency >= start && kanji.frequency <= end;
    }).toList();
  }
  
  // Get random kanji from specific criteria
  List<Kanji> getRandomKanji({
    int? grade,
    int? jlpt,
    int count = 1,
  }) {
    List<Kanji> candidates = _kanjiList ?? [];
    
    if (grade != null) {
      candidates = candidates.where((k) => k.grade == grade).toList();
    }
    
    if (jlpt != null) {
      candidates = candidates.where((k) => k.jlpt == jlpt).toList();
    }
    
    if (candidates.isEmpty) return [];
    
    // Shuffle and take first 'count' items
    candidates.shuffle();
    return candidates.take(count).toList();
  }
}