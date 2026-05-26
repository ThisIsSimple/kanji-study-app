import 'study_progress.dart';
import 'word_model.dart';

class TodayWordRecommendation {
  final Word word;
  final bool isReview;
  final StudyItemProgress? progress;

  const TodayWordRecommendation({
    required this.word,
    required this.isReview,
    this.progress,
  });
}
