import 'package:flutter/material.dart';

class DailyStudyStats {
  final DateTime date;
  final int kanjiStudied;
  final int wordsStudied;
  final int totalCompleted;
  final int totalForgot;
  final List<StudyItem> studyItems;

  DailyStudyStats({
    required this.date,
    required this.kanjiStudied,
    required this.wordsStudied,
    required this.totalCompleted,
    required this.totalForgot,
    required this.studyItems,
  });

  factory DailyStudyStats.fromJson(Map<String, dynamic> json) {
    return DailyStudyStats(
      date: DateTime.parse(json['date']),
      kanjiStudied: json['kanji_studied'] ?? 0,
      wordsStudied: json['words_studied'] ?? 0,
      totalCompleted: json['total_completed'] ?? 0,
      totalForgot: json['total_forgot'] ?? 0,
      studyItems: (json['study_items'] as List?)
          ?.map((item) => StudyItem.fromJson(item))
          .toList() ?? [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'date': date.toIso8601String(),
      'kanji_studied': kanjiStudied,
      'words_studied': wordsStudied,
      'total_completed': totalCompleted,
      'total_forgot': totalForgot,
      'study_items': studyItems.map((item) => item.toJson()).toList(),
    };
  }

  int get totalStudied => kanjiStudied + wordsStudied;
  
  double get successRate {
    final total = totalCompleted + totalForgot;
    if (total == 0) return 0;
    return totalCompleted / total;
  }
  
  Color getColorForCalendar() {
    if (totalStudied == 0) return Colors.transparent;
    if (totalStudied < 5) return Colors.blue.shade100;
    if (totalStudied < 10) return Colors.blue.shade300;
    if (totalStudied < 20) return Colors.blue.shade500;
    return Colors.blue.shade700;
  }
  
  String get summaryText {
    if (totalStudied == 0) return '학습 없음';
    return '한자 $kanjiStudied개, 단어 $wordsStudied개';
  }
}

class StudyItem {
  final int id;
  final String type;
  final String name;
  final String status;
  final DateTime studiedAt;

  StudyItem({
    required this.id,
    required this.type,
    required this.name,
    required this.status,
    required this.studiedAt,
  });

  factory StudyItem.fromJson(Map<String, dynamic> json) {
    return StudyItem(
      id: json['id'],
      type: json['type'],
      name: json['name'] ?? '',
      status: json['status'],
      studiedAt: DateTime.parse(json['studied_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'name': name,
      'status': status,
      'studied_at': studiedAt.toIso8601String(),
    };
  }
}