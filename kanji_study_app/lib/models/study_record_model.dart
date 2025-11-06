enum StudyType {
  kanji,
  word;

  String get value => name;

  static StudyType fromString(String value) {
    return StudyType.values.firstWhere(
      (type) => type.value == value,
      orElse: () => StudyType.kanji,
    );
  }
}

enum StudyStatus {
  completed,
  forgot,
  reviewing,
  mastered;

  String get value => name;

  static StudyStatus fromString(String value) {
    return StudyStatus.values.firstWhere(
      (status) => status.value == value,
      orElse: () => StudyStatus.completed,
    );
  }

  String get displayText {
    switch (this) {
      case StudyStatus.completed:
        return '학습 완료';
      case StudyStatus.forgot:
        return '까먹음';
      case StudyStatus.reviewing:
        return '복습 중';
      case StudyStatus.mastered:
        return '완벽 습득';
    }
  }

  String get emoji {
    switch (this) {
      case StudyStatus.completed:
        return '✅';
      case StudyStatus.forgot:
        return '😕';
      case StudyStatus.reviewing:
        return '📚';
      case StudyStatus.mastered:
        return '🎯';
    }
  }
}

class StudyRecord {
  final int? id;
  final String? userId;
  final StudyType type;
  final int targetId;
  final StudyStatus status;
  final String? notes;
  final DateTime? createdAt;

  const StudyRecord({
    this.id,
    this.userId,
    required this.type,
    required this.targetId,
    required this.status,
    this.notes,
    this.createdAt,
  });

  factory StudyRecord.fromJson(Map<String, dynamic> json) {
    return StudyRecord(
      id: json['id'] as int?,
      userId: json['user_id'] as String?,
      type: StudyType.fromString(json['type'] as String),
      targetId: json['target_id'] as int,
      status: StudyStatus.fromString(json['status'] as String),
      notes: json['notes'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String).toLocal()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      if (userId != null) 'user_id': userId,
      'type': type.value,
      'target_id': targetId,
      'status': status.value,
      if (notes != null) 'notes': notes,
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
    };
  }

  Map<String, dynamic> toJsonForCreate() {
    return {
      'user_id': userId,
      'type': type.value,
      'target_id': targetId,
      'status': status.value,
      if (notes != null) 'notes': notes,
    };
  }

  StudyRecord copyWith({
    int? id,
    String? userId,
    StudyType? type,
    int? targetId,
    StudyStatus? status,
    String? notes,
    DateTime? createdAt,
  }) {
    return StudyRecord(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      targetId: targetId ?? this.targetId,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is StudyRecord &&
        other.id == id &&
        other.userId == userId &&
        other.type == type &&
        other.targetId == targetId &&
        other.status == status &&
        other.notes == notes &&
        other.createdAt == createdAt;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        userId.hashCode ^
        type.hashCode ^
        targetId.hashCode ^
        status.hashCode ^
        notes.hashCode ^
        createdAt.hashCode;
  }

  @override
  String toString() {
    return 'StudyRecord(id: $id, userId: $userId, type: $type, targetId: $targetId, status: $status, notes: $notes, createdAt: $createdAt)';
  }
}

// Study statistics for a specific target
class StudyStats {
  final int targetId;
  final StudyType type;
  final int totalRecords;
  final int completedCount;
  final int forgotCount;
  final int reviewingCount;
  final int masteredCount;
  final DateTime? firstStudied;
  final DateTime? lastStudied;
  final List<StudyRecord> recentRecords;

  const StudyStats({
    required this.targetId,
    required this.type,
    required this.totalRecords,
    required this.completedCount,
    required this.forgotCount,
    required this.reviewingCount,
    required this.masteredCount,
    this.firstStudied,
    this.lastStudied,
    required this.recentRecords,
  });

  double get masteryRate {
    if (totalRecords == 0) return 0;
    return masteredCount / totalRecords;
  }

  double get successRate {
    if (totalRecords == 0) return 0;
    final successCount = completedCount + masteredCount;
    return successCount / totalRecords;
  }

  StudyStatus? get currentStatus {
    if (recentRecords.isEmpty) return null;
    return recentRecords.first.status;
  }

  String get summaryText {
    if (totalRecords == 0) return '학습 기록 없음';

    final successPercent = (successRate * 100).toStringAsFixed(0);
    return '총 $totalRecords회 학습 (성공률 $successPercent%)';
  }
}
