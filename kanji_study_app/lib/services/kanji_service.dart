import 'dart:convert';
import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/kanji_model.dart';
import '../models/user_progress.dart';
import '../models/study_record_model.dart';
import 'kanji_repository.dart';
import 'favorite_service.dart';
import 'study_record_service.dart';

class KanjiService {
  static final KanjiService _instance = KanjiService._internal();
  static KanjiService get instance => _instance;

  KanjiService._internal();

  final KanjiRepository _repository = KanjiRepository.instance;
  final FavoriteService _favoriteService = FavoriteService.instance;
  final StudyRecordService _studyRecordService = StudyRecordService.instance;
  final Map<String, UserProgress> _legacyProgressMap = {};

  Future<void> init() async {
    await _repository.loadKanjiData();
    await _loadLegacyProgress();
  }

  Future<void> reloadData() async {
    await _repository.reloadKanjiData();
    await _loadLegacyProgress();
  }

  Future<void> _loadLegacyProgress() async {
    final prefs = await SharedPreferences.getInstance();
    final progressData = prefs.getString('user_progress');

    _legacyProgressMap.clear();
    if (progressData != null) {
      final Map<String, dynamic> decoded = json.decode(progressData);
      decoded.forEach((key, value) {
        _legacyProgressMap[key] = UserProgress.fromJson(value);
      });
    }
  }

  bool isFavorite(String character) {
    final kanji = _repository.getKanjiByCharacter(character);
    if (kanji == null) return false;
    return _favoriteService.isFavorite('kanji', kanji.id);
  }

  Future<void> toggleFavorite(String character) async {
    final kanji = _repository.getKanjiByCharacter(character);
    if (kanji == null) return;
    await _favoriteService.toggleFavorite(type: 'kanji', targetId: kanji.id);
  }

  List<Kanji> getFavoriteKanji() {
    final favoriteIds = _favoriteService.getFavoriteIds('kanji');
    return favoriteIds
        .map((id) => _repository.getKanjiById(id))
        .whereType<Kanji>()
        .toList();
  }

  Kanji getTodayKanji() {
    final allKanji = _repository.getAllKanji();
    if (allKanji.isEmpty) {
      throw Exception('No kanji data available');
    }

    final progressById = _studyRecordService.getProgressByType(StudyType.kanji);

    final unstudiedKanji = allKanji.where((kanji) {
      final progress = progressById[kanji.id];
      final legacy = _legacyProgressMap[kanji.character];
      return progress == null && legacy == null;
    }).toList();

    if (unstudiedKanji.isNotEmpty) {
      final topCandidates = unstudiedKanji.take(10).toList();
      return topCandidates[Random().nextInt(topCandidates.length)];
    }

    var oldestKanji = allKanji.first;
    var oldestDate = DateTime.now();

    for (final kanji in allKanji) {
      final progress = progressById[kanji.id];
      final progressDate =
          progress?.lastStudiedAt ??
          _legacyProgressMap[kanji.character]?.lastStudied;
      if (progressDate != null && progressDate.isBefore(oldestDate)) {
        oldestDate = progressDate;
        oldestKanji = kanji;
      }
    }

    return oldestKanji;
  }

  List<Kanji> getAllKanji() => _repository.getAllKanji();

  Kanji? getKanjiById(int id) => _repository.getKanjiById(id);

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
}
