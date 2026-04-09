import 'dart:math';

/// User statistics model for home dashboard
class UserStats {
  final int streak; // Consecutive study days
  final int totalXP; // Total XP points (for future implementation)
  final int todayProgress; // Number of items studied today
  final int dailyGoal; // Daily goal target
  final int weeklyCount; // This week's study count
  final double weeklyAverage; // Weekly average study rate
  final int reviewQueueSize; // Number of items needing review
  final int nextMilestone; // Next milestone target
  final int remainingToMilestone; // Remaining to reach milestone
  final int totalStudied; // Total number of kanji studied
  final int totalMastered; // Total number of kanji mastered

  const UserStats({
    required this.streak,
    required this.totalXP,
    required this.todayProgress,
    required this.dailyGoal,
    required this.weeklyCount,
    required this.weeklyAverage,
    required this.reviewQueueSize,
    required this.nextMilestone,
    required this.remainingToMilestone,
    required this.totalStudied,
    required this.totalMastered,
  });

  /// Calculate daily progress percentage (0.0 to 1.0)
  double get dailyProgressPercentage {
    if (dailyGoal <= 0) return 0.0;
    return min(todayProgress / dailyGoal, 1.0);
  }

  /// Check if daily goal is achieved
  bool get isDailyGoalAchieved {
    return todayProgress >= dailyGoal;
  }

  /// Get motivational message based on progress
  String get motivationalMessage {
    if (isDailyGoalAchieved) {
      return '오늘의 목표를 달성했어요! 🎉';
    } else if (dailyProgressPercentage >= 0.8) {
      return '거의 다 왔어요! 조금만 더 힘내세요! 💪';
    } else if (dailyProgressPercentage >= 0.5) {
      return '절반을 넘었어요! 계속 해봐요! 🚀';
    } else if (dailyProgressPercentage > 0) {
      return '좋은 시작이에요! 계속 진행해봐요! ✨';
    } else {
      return '오늘도 화이팅! 시작이 반이에요! 🎯';
    }
  }

  /// Get streak message
  String get streakMessage {
    if (streak >= 100) {
      return '$streak일 연속! 대단해요! 🔥🔥🔥';
    } else if (streak >= 30) {
      return '$streak일 연속! 훌륭해요! 🔥🔥';
    } else if (streak >= 7) {
      return '$streak일 연속! 잘하고 있어요! 🔥';
    } else if (streak >= 3) {
      return '$streak일 연속 학습 중';
    } else if (streak > 0) {
      return '$streak일 연속';
    } else {
      return '오늘부터 시작해봐요!';
    }
  }

  /// Get remaining items for daily goal
  int get remainingForDailyGoal {
    return max(0, dailyGoal - todayProgress);
  }

  /// Get progress text for daily goal
  String get dailyGoalProgressText {
    return '$todayProgress / $dailyGoal';
  }

  /// Get milestone progress text
  String get milestoneProgressText {
    return '$totalMastered / $nextMilestone';
  }

  /// Get milestone percentage
  double get milestonePercentage {
    if (nextMilestone <= 0) return 0.0;
    return min(totalMastered / nextMilestone, 1.0);
  }

  /// Get weekly average text
  String get weeklyAverageText {
    return '주간 평균: ${weeklyAverage.toStringAsFixed(1)}개/일';
  }

  /// Get this week's study text
  String get weeklyStudyText {
    return '이번 주: $weeklyCount개';
  }

  factory UserStats.empty() {
    return const UserStats(
      streak: 0,
      totalXP: 0,
      todayProgress: 0,
      dailyGoal: 10,
      weeklyCount: 0,
      weeklyAverage: 0.0,
      reviewQueueSize: 0,
      nextMilestone: 10,
      remainingToMilestone: 10,
      totalStudied: 0,
      totalMastered: 0,
    );
  }

  UserStats copyWith({
    int? streak,
    int? totalXP,
    int? todayProgress,
    int? dailyGoal,
    int? weeklyCount,
    double? weeklyAverage,
    int? reviewQueueSize,
    int? nextMilestone,
    int? remainingToMilestone,
    int? totalStudied,
    int? totalMastered,
  }) {
    return UserStats(
      streak: streak ?? this.streak,
      totalXP: totalXP ?? this.totalXP,
      todayProgress: todayProgress ?? this.todayProgress,
      dailyGoal: dailyGoal ?? this.dailyGoal,
      weeklyCount: weeklyCount ?? this.weeklyCount,
      weeklyAverage: weeklyAverage ?? this.weeklyAverage,
      reviewQueueSize: reviewQueueSize ?? this.reviewQueueSize,
      nextMilestone: nextMilestone ?? this.nextMilestone,
      remainingToMilestone: remainingToMilestone ?? this.remainingToMilestone,
      totalStudied: totalStudied ?? this.totalStudied,
      totalMastered: totalMastered ?? this.totalMastered,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is UserStats &&
        other.streak == streak &&
        other.totalXP == totalXP &&
        other.todayProgress == todayProgress &&
        other.dailyGoal == dailyGoal &&
        other.weeklyCount == weeklyCount &&
        other.weeklyAverage == weeklyAverage &&
        other.reviewQueueSize == reviewQueueSize &&
        other.nextMilestone == nextMilestone &&
        other.remainingToMilestone == remainingToMilestone &&
        other.totalStudied == totalStudied &&
        other.totalMastered == totalMastered;
  }

  @override
  int get hashCode {
    return streak.hashCode ^
        totalXP.hashCode ^
        todayProgress.hashCode ^
        dailyGoal.hashCode ^
        weeklyCount.hashCode ^
        weeklyAverage.hashCode ^
        reviewQueueSize.hashCode ^
        nextMilestone.hashCode ^
        remainingToMilestone.hashCode ^
        totalStudied.hashCode ^
        totalMastered.hashCode;
  }

  @override
  String toString() {
    return 'UserStats(streak: $streak, totalXP: $totalXP, todayProgress: $todayProgress, dailyGoal: $dailyGoal, weeklyCount: $weeklyCount, weeklyAverage: $weeklyAverage, reviewQueueSize: $reviewQueueSize, nextMilestone: $nextMilestone, remainingToMilestone: $remainingToMilestone, totalStudied: $totalStudied, totalMastered: $totalMastered)';
  }
}
