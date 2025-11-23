import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:intl/intl.dart';
import '../models/study_record_model.dart';

/// A reusable study button bar widget that displays study status and actions.
/// Used in both kanji and word detail screens.
class StudyButtonBar extends StatelessWidget {
  final bool isLoading;
  final bool isRecording;
  final StudyStats? studyStats;
  final VoidCallback onStudyComplete;
  final VoidCallback onForgot;
  final VoidCallback onShowTimeline;

  const StudyButtonBar({
    super.key,
    required this.isLoading,
    required this.isRecording,
    required this.studyStats,
    required this.onStudyComplete,
    required this.onForgot,
    required this.onShowTimeline,
  });

  @override
  Widget build(BuildContext context) {
    final theme = FTheme.of(context);

    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.colors.background,
          border: Border(top: BorderSide(color: theme.colors.border, width: 1)),
        ),
        child: SafeArea(
          top: false,
          child: isLoading
              ? const Center(
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: FCircularProgress(),
                  ),
                )
              : studyStats == null || studyStats!.totalRecords == 0
              ? FButton(
                  onPress: isRecording ? null : onStudyComplete,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(PhosphorIconsRegular.checkCircle, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        isRecording ? '기록 중...' : '학습 완료',
                        style: TextStyle(),
                      ),
                    ],
                  ),
                )
              : Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            studyStats!.lastStudied != null
                                ? '${DateFormat('yyyy년 MM월 dd일').format(studyStats!.lastStudied!)} 학습'
                                : '학습 기록',
                            style: theme.typography.sm.copyWith(
                              color: theme.colors.mutedForeground,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            studyStats!.summaryText,
                            style: theme.typography.base.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Timeline button
                    FButton(
                      onPress: onShowTimeline,
                      style: FButtonStyle.outline(),
                      child: Icon(PhosphorIconsRegular.clockCounterClockwise, size: 18),
                    ),
                    const SizedBox(width: 8),
                    FButton(
                      onPress: isRecording ? null : onForgot,
                      style: FButtonStyle.outline(),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(PhosphorIconsRegular.warningCircle, size: 18),
                          const SizedBox(width: 6),
                          Text(
                            isRecording ? '기록 중...' : '까먹음',
                            style: TextStyle(),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  /// Shows a timeline bottom sheet with study records
  static void showTimelineSheet({
    required BuildContext context,
    required StudyStats? studyStats,
  }) {
    final theme = FTheme.of(context);

    showFSheet(
      context: context,
      side: FLayout.btt,
      builder: (context) => Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.6,
        ),
        decoration: BoxDecoration(
          color: theme.colors.background,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: theme.colors.muted,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Header
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(
                    PhosphorIconsRegular.clockCounterClockwise,
                    size: 24,
                    color: theme.colors.foreground,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '학습 기록',
                    style: theme.typography.lg.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            Divider(height: 1, color: theme.colors.border),
            // Timeline content
            Expanded(
              child: studyStats == null || studyStats.recentRecords.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            PhosphorIconsRegular.clockCounterClockwise,
                            size: 48,
                            color: theme.colors.mutedForeground,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            '학습 기록이 없습니다',
                            style: theme.typography.base.copyWith(
                              color: theme.colors.mutedForeground,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      itemCount: studyStats.recentRecords.length,
                      itemBuilder: (context, index) {
                        final record = studyStats.recentRecords[index];
                        final isLast = index == studyStats.recentRecords.length - 1;
                        final isCompleted = record.status == StudyStatus.completed;

                        return IntrinsicHeight(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Timeline indicator
                              Column(
                                children: [
                                  Container(
                                    width: 12,
                                    height: 12,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: isCompleted
                                          ? Colors.green
                                          : Colors.red,
                                    ),
                                  ),
                                  if (!isLast)
                                    Expanded(
                                      child: Container(
                                        width: 2,
                                        color: theme.colors.border,
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(width: 16),
                              // Record content
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.only(bottom: 24),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        record.createdAt != null
                                            ? DateFormat('yyyy.MM.dd HH:mm').format(record.createdAt!)
                                            : '',
                                        style: theme.typography.sm.copyWith(
                                          color: theme.colors.mutedForeground,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          Icon(
                                            isCompleted
                                                ? PhosphorIconsRegular.checkCircle
                                                : PhosphorIconsRegular.warningCircle,
                                            size: 16,
                                            color: isCompleted
                                                ? Colors.green
                                                : Colors.red,
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            isCompleted ? '학습 완료' : '까먹음',
                                            style: theme.typography.base.copyWith(
                                              fontWeight: FontWeight.w500,
                                              color: isCompleted
                                                  ? Colors.green
                                                  : Colors.red,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
