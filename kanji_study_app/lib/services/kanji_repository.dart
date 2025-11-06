import '../models/kanji_model.dart';
import 'supabase_service.dart';

class KanjiRepository {
  static final KanjiRepository _instance = KanjiRepository._internal();
  static KanjiRepository get instance => _instance;

  KanjiRepository._internal();

  final SupabaseService _supabaseService = SupabaseService.instance;
  List<Kanji>? _kanjiList;
  Map<String, Kanji>? _kanjiMap;

  Future<void> loadKanjiData() async {
    if (_kanjiList != null) return; // Already loaded

    try {
      // Load data from Supabase
      final supabaseData = await _supabaseService.getAllKanji();

      // Convert to Kanji objects
      _kanjiList = supabaseData.map((data) => Kanji.fromJson(data)).toList();

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
