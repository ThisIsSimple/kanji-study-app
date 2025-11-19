import 'dart:math';

/// Achievement types for categorizing different kinds of achievements
enum AchievementType {
  kanjiCount,    // Based on number of mastered kanji
  streak,        // Based on consecutive study days
  masteryRate,   // Based on success rate percentage
  weeklyCount;   // Based on weekly study count

  String get value {
    switch (this) {
      case AchievementType.kanjiCount:
        return 'kanji_count';
      case AchievementType.streak:
        return 'streak';
      case AchievementType.masteryRate:
        return 'mastery_rate';
      case AchievementType.weeklyCount:
        return 'weekly_count';
    }
  }

  static AchievementType fromString(String value) {
    switch (value) {
      case 'kanji_count':
        return AchievementType.kanjiCount;
      case 'streak':
        return AchievementType.streak;
      case 'mastery_rate':
        return AchievementType.masteryRate;
      case 'weekly_count':
        return AchievementType.weeklyCount;
      default:
        return AchievementType.kanjiCount;
    }
  }

  String get displayName {
    switch (this) {
      case AchievementType.kanjiCount:
        return '한자 마스터';
      case AchievementType.streak:
        return '연속 학습';
      case AchievementType.masteryRate:
        return '성공률';
      case AchievementType.weeklyCount:
        return '주간 학습';
    }
  }
}

/// Achievement model representing a badge or milestone
class Achievement {
  final String id;
  final String title;
  final String description;
  final String icon;
  final int requiredCount;
  final AchievementType type;
  final DateTime? createdAt;

  const Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.requiredCount,
    required this.type,
    this.createdAt,
  });

  factory Achievement.fromJson(Map<String, dynamic> json) {
    return Achievement(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      icon: json['icon'] as String,
      requiredCount: json['required_count'] as int,
      type: AchievementType.fromString(json['type'] as String),
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String).toLocal()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'icon': icon,
      'required_count': requiredCount,
      'type': type.value,
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
    };
  }

  Achievement copyWith({
    String? id,
    String? title,
    String? description,
    String? icon,
    int? requiredCount,
    AchievementType? type,
    DateTime? createdAt,
  }) {
    return Achievement(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      icon: icon ?? this.icon,
      requiredCount: requiredCount ?? this.requiredCount,
      type: type ?? this.type,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is Achievement &&
        other.id == id &&
        other.title == title &&
        other.description == description &&
        other.icon == icon &&
        other.requiredCount == requiredCount &&
        other.type == type;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        title.hashCode ^
        description.hashCode ^
        icon.hashCode ^
        requiredCount.hashCode ^
        type.hashCode;
  }

  @override
  String toString() {
    return 'Achievement(id: $id, title: $title, description: $description, icon: $icon, requiredCount: $requiredCount, type: $type)';
  }
}

/// User achievement model representing a user's progress on an achievement
class UserAchievement {
  final int? id;
  final String userId;
  final String achievementId;
  final DateTime unlockedAt;
  final int progress;

  const UserAchievement({
    this.id,
    required this.userId,
    required this.achievementId,
    required this.unlockedAt,
    required this.progress,
  });

  factory UserAchievement.fromJson(Map<String, dynamic> json) {
    return UserAchievement(
      id: json['id'] as int?,
      userId: json['user_id'] as String,
      achievementId: json['achievement_id'] as String,
      unlockedAt: DateTime.parse(json['unlocked_at'] as String).toLocal(),
      progress: json['progress'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'user_id': userId,
      'achievement_id': achievementId,
      'unlocked_at': unlockedAt.toIso8601String(),
      'progress': progress,
    };
  }

  Map<String, dynamic> toJsonForCreate() {
    return {
      'user_id': userId,
      'achievement_id': achievementId,
      'progress': progress,
    };
  }

  /// Calculate progress percentage (0.0 to 1.0)
  double progressPercentage(int requiredCount) {
    if (requiredCount <= 0) return 0.0;
    return min(progress / requiredCount, 1.0);
  }

  /// Check if achievement is unlocked
  bool isUnlocked(int requiredCount) {
    return progress >= requiredCount;
  }

  UserAchievement copyWith({
    int? id,
    String? userId,
    String? achievementId,
    DateTime? unlockedAt,
    int? progress,
  }) {
    return UserAchievement(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      achievementId: achievementId ?? this.achievementId,
      unlockedAt: unlockedAt ?? this.unlockedAt,
      progress: progress ?? this.progress,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is UserAchievement &&
        other.id == id &&
        other.userId == userId &&
        other.achievementId == achievementId &&
        other.unlockedAt == unlockedAt &&
        other.progress == progress;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        userId.hashCode ^
        achievementId.hashCode ^
        unlockedAt.hashCode ^
        progress.hashCode;
  }

  @override
  String toString() {
    return 'UserAchievement(id: $id, userId: $userId, achievementId: $achievementId, unlockedAt: $unlockedAt, progress: $progress)';
  }
}

/// Combined achievement with user progress for UI display
class AchievementWithProgress {
  final Achievement achievement;
  final UserAchievement? userAchievement;

  const AchievementWithProgress({
    required this.achievement,
    this.userAchievement,
  });

  bool get isUnlocked {
    if (userAchievement == null) return false;
    return userAchievement!.isUnlocked(achievement.requiredCount);
  }

  double get progressPercentage {
    if (userAchievement == null) return 0.0;
    return userAchievement!.progressPercentage(achievement.requiredCount);
  }

  int get currentProgress {
    return userAchievement?.progress ?? 0;
  }

  int get remaining {
    return max(0, achievement.requiredCount - currentProgress);
  }

  String get progressText {
    return '$currentProgress / ${achievement.requiredCount}';
  }
}
