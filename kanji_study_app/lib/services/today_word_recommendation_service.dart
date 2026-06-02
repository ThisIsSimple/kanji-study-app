import 'dart:math';

import 'package:flutter/foundation.dart';

import '../models/learning_goal.dart';
import '../models/study_progress.dart';
import '../models/study_record_model.dart';
import '../models/today_word_recommendation.dart';
import '../models/word_model.dart';
import 'study_record_service.dart';
import 'supabase_service.dart';
import 'word_service.dart';

class TodayWordRecommendationService {
  static final TodayWordRecommendationService _instance =
      TodayWordRecommendationService._internal();
  static TodayWordRecommendationService get instance => _instance;

  TodayWordRecommendationService._internal();

  final WordService _wordService = WordService.instance;
  final StudyRecordService _studyRecordService = StudyRecordService.instance;
  final SupabaseService _supabaseService = SupabaseService.instance;
  static const int _recommendationCandidatePageSize = 1200;

  Future<List<TodayWordRecommendation>> getTodayWords({
    required LearningGoal goal,
    required int alreadyStudiedToday,
  }) async {
    final today = DateTime.now();
    return getWordsForDate(
      goal: goal,
      date: today,
      alreadyStudiedForDate: alreadyStudiedToday,
    );
  }

  Future<List<TodayWordRecommendation>> getWordsForDate({
    required LearningGoal goal,
    required DateTime date,
    required int alreadyStudiedForDate,
  }) async {
    await _wordService.init();

    final dateStart = DateTime(date.year, date.month, date.day);
    final dateEnd = dateStart.add(
      const Duration(hours: 23, minutes: 59, seconds: 59),
    );
    final dateRecords = await _studyRecordService.getStudyRecords(
      startDate: dateStart,
      endDate: dateEnd,
    );

    final progressById = _studyRecordService.getProgressByType(StudyType.word);
    final userSeed = _supabaseService.currentUser?.id ?? 'local';
    final candidateWords = await _loadRecommendationCandidates(
      goal: goal,
      progressById: progressById,
      todayRecords: dateRecords,
      alreadyStudiedToday: alreadyStudiedForDate,
      userSeed: userSeed,
      date: dateStart,
    );

    return buildRecommendations(
      allWords: candidateWords,
      progressById: progressById,
      todayRecords: dateRecords,
      goal: goal,
      alreadyStudiedToday: alreadyStudiedForDate,
      userSeed: userSeed,
      date: dateStart,
    );
  }

  Future<List<Word>> _loadRecommendationCandidates({
    required LearningGoal goal,
    required Map<int, StudyItemProgress> progressById,
    required List<StudyRecord> todayRecords,
    required int alreadyStudiedToday,
    required String userSeed,
    required DateTime date,
  }) {
    return loadRecommendationCandidatesFromPages(
      goal: goal,
      progressById: progressById,
      todayRecords: todayRecords,
      alreadyStudiedToday: alreadyStudiedToday,
      userSeed: userSeed,
      date: date,
      queryWords:
          ({
            required Set<int> jlptLevels,
            required int limit,
            required int offset,
          }) {
            return _wordService.queryWords(
              jlptLevels: jlptLevels,
              limit: limit,
              offset: offset,
            );
          },
    );
  }

  @visibleForTesting
  static Future<List<Word>> loadRecommendationCandidatesFromPages({
    required LearningGoal goal,
    required Map<int, StudyItemProgress> progressById,
    required List<StudyRecord> todayRecords,
    required int alreadyStudiedToday,
    required String userSeed,
    required DateTime date,
    required Future<List<Word>> Function({
      required Set<int> jlptLevels,
      required int limit,
      required int offset,
    })
    queryWords,
    int pageSize = _recommendationCandidatePageSize,
  }) async {
    final remaining = max(0, goal.dailyGoal - alreadyStudiedToday);
    if (remaining == 0 || !goal.isValid) return [];

    final quotas = _buildJlptQuotas(
      count: max(goal.dailyGoal, 1),
      targetJlptLevel: goal.targetJlptLevel,
    );
    final levelsToLoad = quotas.keys
        .where((levels) => levels.isNotEmpty)
        .toList();
    final offsets = {for (final levels in levelsToLoad) levels: 0};
    final exhausted = <Set<int>>{};

    final byId = <int, Word>{};
    while (exhausted.length < levelsToLoad.length) {
      var loadedAny = false;

      for (final levels in levelsToLoad) {
        if (exhausted.contains(levels)) continue;

        final page = await queryWords(
          jlptLevels: levels,
          limit: pageSize,
          offset: offsets[levels]!,
        );
        offsets[levels] = offsets[levels]! + page.length;

        if (page.isEmpty) {
          exhausted.add(levels);
          continue;
        }

        loadedAny = true;
        for (final word in page) {
          byId[word.id] = word;
        }

        if (page.length < pageSize) {
          exhausted.add(levels);
        }
      }

      final recommendations = buildRecommendations(
        allWords: byId.values.toList(),
        progressById: progressById,
        todayRecords: todayRecords,
        goal: goal,
        alreadyStudiedToday: alreadyStudiedToday,
        userSeed: userSeed,
        date: date,
      );
      if (recommendations.length >= remaining || !loadedAny) {
        break;
      }
    }

    return byId.values.toList();
  }

  static List<TodayWordRecommendation> buildRecommendations({
    required List<Word> allWords,
    required Map<int, StudyItemProgress> progressById,
    required List<StudyRecord> todayRecords,
    required LearningGoal goal,
    required int alreadyStudiedToday,
    required String userSeed,
    required DateTime date,
  }) {
    final remaining = max(0, goal.dailyGoal - alreadyStudiedToday);
    if (remaining == 0 || allWords.isEmpty || !goal.isValid) return [];

    final studiedTodayIds = todayRecords
        .where((record) => record.type == StudyType.word)
        .map((record) => record.targetId)
        .toSet();
    final eligibleWords = allWords
        .where((word) => !studiedTodayIds.contains(word.id))
        .toList();
    if (eligibleWords.isEmpty) return [];

    final quotas = _buildJlptQuotas(
      count: remaining,
      targetJlptLevel: goal.targetJlptLevel,
    );
    final seed = _stableSeed(userSeed, date, goal.targetJlptLevel);
    final selected = <TodayWordRecommendation>[];
    final selectedIds = <int>{};

    for (final entry in quotas.entries) {
      _selectForLevels(
        selected: selected,
        selectedIds: selectedIds,
        words: eligibleWords,
        progressById: progressById,
        levels: entry.key,
        count: entry.value,
        seed: seed + selected.length + entry.value,
      );
    }

    if (selected.length < remaining) {
      _selectForLevels(
        selected: selected,
        selectedIds: selectedIds,
        words: eligibleWords,
        progressById: progressById,
        levels: const {1, 2, 3, 4, 5},
        count: remaining - selected.length,
        seed: seed + 97,
      );
    }

    return selected.take(remaining).toList();
  }

  static Map<Set<int>, int> _buildJlptQuotas({
    required int count,
    required int targetJlptLevel,
  }) {
    final targetCount = (count * 0.7).round().clamp(0, count);
    final adjacentCount = (count * 0.2).round().clamp(0, count - targetCount);
    final otherCount = count - targetCount - adjacentCount;

    final adjacentLevels = <int>{
      if (targetJlptLevel > 1) targetJlptLevel - 1,
      if (targetJlptLevel < 5) targetJlptLevel + 1,
    };
    final otherLevels = {1, 2, 3, 4, 5}
      ..remove(targetJlptLevel)
      ..removeAll(adjacentLevels);

    return {
      {targetJlptLevel}: targetCount,
      adjacentLevels: adjacentCount,
      otherLevels: otherCount,
    };
  }

  static void _selectForLevels({
    required List<TodayWordRecommendation> selected,
    required Set<int> selectedIds,
    required List<Word> words,
    required Map<int, StudyItemProgress> progressById,
    required Set<int> levels,
    required int count,
    required int seed,
  }) {
    if (count <= 0 || levels.isEmpty) return;

    final candidates = words
        .where(
          (word) =>
              levels.contains(word.jlptLevel) && !selectedIds.contains(word.id),
        )
        .toList();
    if (candidates.isEmpty) return;

    final reviewCandidates = candidates.where((word) {
      final progress = progressById[word.id];
      return progress != null &&
          !progress.isMastered &&
          (progress.lastStatus == StudyStatus.forgot ||
              progress.forgotCount > 0);
    }).toList();
    final newCandidates = candidates
        .where((word) => progressById[word.id] == null)
        .toList();
    final fallbackCandidates = candidates.where((word) {
      final progress = progressById[word.id];
      return progress == null || !progress.isMastered;
    }).toList();

    final targetSize = selected.length + count;
    final reviewTarget = min(count, (count * 0.4).ceil());
    _appendShuffled(
      selected: selected,
      selectedIds: selectedIds,
      candidates: reviewCandidates,
      progressById: progressById,
      count: reviewTarget,
      seed: seed,
    );
    _appendShuffled(
      selected: selected,
      selectedIds: selectedIds,
      candidates: newCandidates,
      progressById: progressById,
      count: targetSize - selected.length,
      seed: seed + 31,
    );
    _appendShuffled(
      selected: selected,
      selectedIds: selectedIds,
      candidates: fallbackCandidates,
      progressById: progressById,
      count: targetSize - selected.length,
      seed: seed + 53,
    );
  }

  static void _appendShuffled({
    required List<TodayWordRecommendation> selected,
    required Set<int> selectedIds,
    required List<Word> candidates,
    required Map<int, StudyItemProgress> progressById,
    required int count,
    required int seed,
  }) {
    if (count <= 0 || candidates.isEmpty) return;

    final shuffled =
        candidates.where((word) => !selectedIds.contains(word.id)).toList()
          ..shuffle(Random(seed));
    for (final word in shuffled.take(count)) {
      final progress = progressById[word.id];
      selectedIds.add(word.id);
      selected.add(
        TodayWordRecommendation(
          word: word,
          progress: progress,
          isReview:
              progress != null &&
              (progress.lastStatus == StudyStatus.forgot ||
                  progress.forgotCount > 0),
        ),
      );
    }
  }

  static int _stableSeed(String userSeed, DateTime date, int targetJlptLevel) {
    final key =
        '$userSeed-${date.year}-${date.month}-${date.day}-$targetJlptLevel';
    var hash = 0;
    for (final codeUnit in key.codeUnits) {
      hash = 0x1fffffff & (hash + codeUnit);
      hash = 0x1fffffff & (hash + ((0x0007ffff & hash) << 10));
      hash ^= hash >> 6;
    }
    hash = 0x1fffffff & (hash + ((0x03ffffff & hash) << 3));
    hash ^= hash >> 11;
    hash = 0x1fffffff & (hash + ((0x00003fff & hash) << 15));
    return hash;
  }
}
