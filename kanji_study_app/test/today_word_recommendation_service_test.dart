import 'package:flutter_test/flutter_test.dart';
import 'package:konnakanji/models/learning_goal.dart';
import 'package:konnakanji/models/study_progress.dart';
import 'package:konnakanji/models/study_record_model.dart';
import 'package:konnakanji/models/word_meaning_model.dart';
import 'package:konnakanji/models/word_model.dart';
import 'package:konnakanji/services/today_word_recommendation_service.dart';

void main() {
  test('returns remaining daily goal count and keeps stable ordering', () {
    final words = _wordsByLevel();
    final goal = LearningGoal(dailyGoal: 10, targetJlptLevel: 3);

    final first = TodayWordRecommendationService.buildRecommendations(
      allWords: words,
      progressById: const {},
      todayRecords: const [],
      goal: goal,
      alreadyStudiedToday: 2,
      userSeed: 'user-1',
      date: DateTime(2026, 5, 26),
    );
    final second = TodayWordRecommendationService.buildRecommendations(
      allWords: words,
      progressById: const {},
      todayRecords: const [],
      goal: goal,
      alreadyStudiedToday: 2,
      userSeed: 'user-1',
      date: DateTime(2026, 5, 26),
    );

    expect(first, hasLength(8));
    expect(
      second.map((item) => item.word.id),
      first.map((item) => item.word.id),
    );
  });

  test('applies target-centered JLPT mix', () {
    final recommendations = TodayWordRecommendationService.buildRecommendations(
      allWords: _wordsByLevel(perLevel: 10),
      progressById: const {},
      todayRecords: const [],
      goal: LearningGoal(dailyGoal: 10, targetJlptLevel: 3),
      alreadyStudiedToday: 0,
      userSeed: 'user-1',
      date: DateTime(2026, 5, 26),
    );

    final counts = <int, int>{};
    for (final item in recommendations) {
      counts[item.word.jlptLevel] = (counts[item.word.jlptLevel] ?? 0) + 1;
    }

    expect(counts[3], 7);
    expect((counts[2] ?? 0) + (counts[4] ?? 0), 2);
    expect((counts[1] ?? 0) + (counts[5] ?? 0), 1);
  });

  test('mixes recent forgotten words with unstudied words', () {
    final progress = buildProgressIndex([
      StudyRecord(
        type: StudyType.word,
        targetId: 300,
        status: StudyStatus.forgot,
        createdAt: DateTime(2026, 5, 25),
      ),
      StudyRecord(
        type: StudyType.word,
        targetId: 301,
        status: StudyStatus.completed,
        createdAt: DateTime(2026, 5, 24),
      ),
    ]).map((key, value) => MapEntry(value.targetId, value));

    final recommendations = TodayWordRecommendationService.buildRecommendations(
      allWords: _wordsByLevel(perLevel: 8),
      progressById: progress,
      todayRecords: const [],
      goal: LearningGoal(dailyGoal: 5, targetJlptLevel: 3),
      alreadyStudiedToday: 0,
      userSeed: 'user-1',
      date: DateTime(2026, 5, 26),
    );

    expect(recommendations.any((item) => item.word.id == 300), isTrue);
    expect(recommendations.any((item) => item.isReview), isTrue);
    expect(recommendations.any((item) => item.progress == null), isTrue);
  });

  test('excludes words already studied today', () {
    final recommendations = TodayWordRecommendationService.buildRecommendations(
      allWords: _wordsByLevel(perLevel: 8),
      progressById: const {},
      todayRecords: [
        StudyRecord(
          type: StudyType.word,
          targetId: 300,
          status: StudyStatus.completed,
          createdAt: DateTime(2026, 5, 26, 9),
        ),
      ],
      goal: LearningGoal(dailyGoal: 5, targetJlptLevel: 3),
      alreadyStudiedToday: 0,
      userSeed: 'user-1',
      date: DateTime(2026, 5, 26),
    );

    expect(recommendations.map((item) => item.word.id), isNot(contains(300)));
  });

  test('keeps a stable schedule for the same future date', () {
    final words = _wordsByLevel(perLevel: 20);
    final goal = LearningGoal(dailyGoal: 12, targetJlptLevel: 3);
    final futureDate = DateTime(2026, 5, 29);

    final first = TodayWordRecommendationService.buildRecommendations(
      allWords: words,
      progressById: const {},
      todayRecords: const [],
      goal: goal,
      alreadyStudiedToday: 0,
      userSeed: 'user-1',
      date: futureDate,
    );
    final second = TodayWordRecommendationService.buildRecommendations(
      allWords: words,
      progressById: const {},
      todayRecords: const [],
      goal: goal,
      alreadyStudiedToday: 0,
      userSeed: 'user-1',
      date: futureDate,
    );

    expect(first, hasLength(12));
    expect(
      second.map((item) => item.word.id),
      first.map((item) => item.word.id),
    );
  });

  test('uses the date seed so future schedules can differ by day', () {
    final words = _wordsByLevel(perLevel: 20);
    final goal = LearningGoal(dailyGoal: 12, targetJlptLevel: 3);

    final firstDay = TodayWordRecommendationService.buildRecommendations(
      allWords: words,
      progressById: const {},
      todayRecords: const [],
      goal: goal,
      alreadyStudiedToday: 0,
      userSeed: 'user-1',
      date: DateTime(2026, 5, 29),
    );
    final secondDay = TodayWordRecommendationService.buildRecommendations(
      allWords: words,
      progressById: const {},
      todayRecords: const [],
      goal: goal,
      alreadyStudiedToday: 0,
      userSeed: 'user-1',
      date: DateTime(2026, 5, 30),
    );

    expect(
      secondDay.map((item) => item.word.id),
      isNot(firstDay.map((item) => item.word.id)),
    );
  });

  test('returns empty when goal is already complete', () {
    final recommendations = TodayWordRecommendationService.buildRecommendations(
      allWords: _wordsByLevel(),
      progressById: const {},
      todayRecords: const [],
      goal: LearningGoal(dailyGoal: 5, targetJlptLevel: 3),
      alreadyStudiedToday: 5,
      userSeed: 'user-1',
      date: DateTime(2026, 5, 26),
    );

    expect(recommendations, isEmpty);
  });

  test('loads later candidate pages when early page is exhausted', () async {
    final words = [
      _word(id: 300, jlptLevel: 3),
      _word(id: 301, jlptLevel: 3),
      _word(id: 302, jlptLevel: 3),
    ];
    final progressById = {
      300: _masteredProgress(300),
      301: _masteredProgress(301),
    };
    final requestedTargetOffsets = <int>[];

    final candidates =
        await TodayWordRecommendationService.loadRecommendationCandidatesFromPages(
          goal: LearningGoal(dailyGoal: 1, targetJlptLevel: 3),
          progressById: progressById,
          todayRecords: const [],
          alreadyStudiedToday: 0,
          userSeed: 'user-1',
          date: DateTime(2026, 5, 26),
          pageSize: 2,
          queryWords:
              ({
                required Set<int> jlptLevels,
                required int limit,
                required int offset,
              }) async {
                if (jlptLevels.contains(3)) {
                  requestedTargetOffsets.add(offset);
                }
                return words
                    .where((word) => jlptLevels.contains(word.jlptLevel))
                    .skip(offset)
                    .take(limit)
                    .toList();
              },
        );

    final recommendations = TodayWordRecommendationService.buildRecommendations(
      allWords: candidates,
      progressById: progressById,
      todayRecords: const [],
      goal: LearningGoal(dailyGoal: 1, targetJlptLevel: 3),
      alreadyStudiedToday: 0,
      userSeed: 'user-1',
      date: DateTime(2026, 5, 26),
    );

    expect(requestedTargetOffsets, [0, 2]);
    expect(recommendations.map((item) => item.word.id), [302]);
  });
}

List<Word> _wordsByLevel({int perLevel = 5}) {
  final words = <Word>[];
  for (var level = 1; level <= 5; level++) {
    for (var index = 0; index < perLevel; index++) {
      final id = level * 100 + index;
      words.add(_word(id: id, jlptLevel: level));
    }
  }
  return words;
}

Word _word({required int id, required int jlptLevel}) {
  return Word(
    id: id,
    word: '単語$id',
    reading: 'たんご$id',
    meanings: const [WordMeaning(partOfSpeech: '명사', meaning: '단어')],
    jlptLevel: jlptLevel,
  );
}

StudyItemProgress _masteredProgress(int id) {
  return StudyItemProgress(
    type: StudyType.word,
    targetId: id,
    lastStatus: StudyStatus.mastered,
    attemptCount: 5,
    completedCount: 5,
    forgotCount: 0,
    lastStudiedAt: DateTime(2026, 5, 25),
  );
}
