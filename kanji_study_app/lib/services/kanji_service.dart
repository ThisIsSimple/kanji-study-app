import 'dart:convert';
import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/kanji_model.dart';
import '../models/user_progress.dart';
import 'kanji_repository.dart';

class KanjiService {
  static final KanjiService _instance = KanjiService._internal();
  static KanjiService get instance => _instance;
  
  KanjiService._internal();
  
  final KanjiRepository _repository = KanjiRepository.instance;
  final Map<String, UserProgress> _progressMap = {};
  
  Future<void> init() async {
    await _repository.loadKanjiData();
    await _loadProgress();
  }
  
  Future<void> _loadProgress() async {
    final prefs = await SharedPreferences.getInstance();
    final progressData = prefs.getString('user_progress');
    
    if (progressData != null) {
      final Map<String, dynamic> decoded = json.decode(progressData);
      decoded.forEach((key, value) {
        _progressMap[key] = UserProgress.fromJson(value);
      });
    }
  }
  
  Future<void> _saveProgress() async {
    final prefs = await SharedPreferences.getInstance();
    final Map<String, dynamic> data = {};
    
    _progressMap.forEach((key, value) {
      data[key] = value.toJson();
    });
    
    await prefs.setString('user_progress', json.encode(data));
  }
  
  Kanji getTodayKanji() {
    final allKanji = _repository.getAllKanji();
    if (allKanji.isEmpty) {
      throw Exception('No kanji data available');
    }
    
    // Get kanji that haven't been studied or least recently studied
    final unstudiedKanji = allKanji.where((kanji) {
      return !_progressMap.containsKey(kanji.character);
    }).toList();
    
    if (unstudiedKanji.isNotEmpty) {
      // Prioritize by frequency (lower frequency = more common)
      unstudiedKanji.sort((a, b) => a.frequency.compareTo(b.frequency));
      // Return one of the top 10 most common unstudied kanji
      final topCandidates = unstudiedKanji.take(10).toList();
      return topCandidates[Random().nextInt(topCandidates.length)];
    }
    
    // If all kanji have been studied, return the least recently studied one
    var oldestKanji = allKanji.first;
    DateTime oldestDate = DateTime.now();
    
    for (final kanji in allKanji) {
      final progress = _progressMap[kanji.character];
      if (progress != null && progress.lastStudied.isBefore(oldestDate)) {
        oldestDate = progress.lastStudied;
        oldestKanji = kanji;
      }
    }
    
    return oldestKanji;
  }
  
  List<Kanji> getAllKanji() => _repository.getAllKanji();
  
  UserProgress? getProgress(String character) => _progressMap[character];
  
  Future<void> markAsStudied(String character) async {
    final existing = _progressMap[character];
    
    if (existing != null) {
      _progressMap[character] = existing.copyWith(
        lastStudied: DateTime.now(),
        studyCount: existing.studyCount + 1,
        mastered: existing.studyCount >= 4, // Consider mastered after 5 studies
      );
    } else {
      _progressMap[character] = UserProgress(
        kanjiCharacter: character,
        lastStudied: DateTime.now(),
        studyCount: 1,
        mastered: false,
      );
    }
    
    await _saveProgress();
  }
  
  int getStudiedCount() => _progressMap.length;
  
  int getMasteredCount() {
    return _progressMap.values.where((progress) => progress.mastered).length;
  }
  
  double getOverallProgress() {
    final allKanji = _repository.getAllKanji();
    if (allKanji.isEmpty) return 0.0;
    return _progressMap.length / allKanji.length;
  }
  
  // New methods for enhanced functionality
  
  List<Kanji> searchKanji(String query) {
    if (query.isEmpty) return [];
    
    // Search by character
    final byCharacter = _repository.getKanjiByCharacter(query);
    if (byCharacter != null) {
      return [byCharacter];
    }
    
    // Search by meaning or reading
    final byMeaning = _repository.searchByMeaning(query);
    final byReading = _repository.searchByReading(query);
    
    // Combine results and remove duplicates
    final Map<String, Kanji> resultMap = {};
    for (final kanji in [...byMeaning, ...byReading]) {
      resultMap[kanji.character] = kanji;
    }
    
    return resultMap.values.toList();
  }
  
  List<Kanji> getKanjiByGrade(int grade) {
    return _repository.getKanjiByGrade(grade);
  }
  
  List<Kanji> getKanjiByJlpt(int jlptLevel) {
    return _repository.getKanjiByJlpt(jlptLevel);
  }
  
  List<Kanji> getKanjiForDailyStudy({
    int count = 5,
    int? grade,
    int? jlpt,
  }) {
    List<Kanji> candidates = _repository.getAllKanji();
    
    // Filter by grade if specified
    if (grade != null) {
      candidates = candidates.where((k) => k.grade == grade).toList();
    }
    
    // Filter by JLPT if specified
    if (jlpt != null) {
      candidates = candidates.where((k) => k.jlpt == jlpt).toList();
    }
    
    // Prioritize unstudied kanji
    final unstudied = candidates.where((k) => 
      !_progressMap.containsKey(k.character)
    ).toList();
    
    if (unstudied.isNotEmpty) {
      // Sort by frequency and take top candidates
      unstudied.sort((a, b) => a.frequency.compareTo(b.frequency));
      return unstudied.take(count).toList();
    }
    
    // If all are studied, return least recently studied
    candidates.sort((a, b) {
      final progressA = _progressMap[a.character];
      final progressB = _progressMap[b.character];
      
      if (progressA == null && progressB == null) return 0;
      if (progressA == null) return -1;
      if (progressB == null) return 1;
      
      return progressA.lastStudied.compareTo(progressB.lastStudied);
    });
    
    return candidates.take(count).toList();
  }
  
  Map<String, int> getStudyStatistics() {
    final allKanji = _repository.getAllKanji();
    
    return {
      'total': allKanji.length,
      'studied': _progressMap.length,
      'mastered': getMasteredCount(),
      'grade1': _repository.getKanjiByGrade(1).length,
      'grade2': _repository.getKanjiByGrade(2).length,
      'grade3': _repository.getKanjiByGrade(3).length,
      'grade4': _repository.getKanjiByGrade(4).length,
      'grade5': _repository.getKanjiByGrade(5).length,
      'grade6': _repository.getKanjiByGrade(6).length,
      'grade7': _repository.getKanjiByGrade(7).length,
      'jlptN5': _repository.getKanjiByJlpt(5).length,
      'jlptN4': _repository.getKanjiByJlpt(4).length,
      'jlptN3': _repository.getKanjiByJlpt(3).length,
      'jlptN2': _repository.getKanjiByJlpt(2).length,
      'jlptN1': _repository.getKanjiByJlpt(1).length,
    };
  }
}