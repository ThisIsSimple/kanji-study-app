import 'package:flutter/material.dart';
import 'package:forui/forui.dart';

import '../constants/app_spacing.dart';
import '../services/analytics_service.dart';
import '../services/learning_goal_service.dart';
import '../widgets/app_toast.dart';
import '../widgets/custom_header.dart';

class SettingsLearningGoalScreen extends StatefulWidget {
  const SettingsLearningGoalScreen({super.key});

  @override
  State<SettingsLearningGoalScreen> createState() =>
      _SettingsLearningGoalScreenState();
}

class _SettingsLearningGoalScreenState
    extends State<SettingsLearningGoalScreen> {
  final LearningGoalService _learningGoalService = LearningGoalService.instance;
  final AnalyticsService _analyticsService = AnalyticsService.instance;

  bool _isLoading = true;
  bool _isSaving = false;
  int _dailyGoal = 10;
  int _targetJlptLevel = 5;

  @override
  void initState() {
    super.initState();
    _loadGoal();
  }

  Future<void> _loadGoal() async {
    final goal = await _learningGoalService.getGoal();
    if (!mounted) return;
    setState(() {
      if (goal != null) {
        _dailyGoal = goal.dailyGoal;
        _targetJlptLevel = goal.targetJlptLevel;
      }
      _isLoading = false;
    });
  }

  Future<void> _saveGoal() async {
    setState(() => _isSaving = true);
    try {
      final result = await _learningGoalService.saveGoal(
        dailyGoal: _dailyGoal,
        targetJlptLevel: _targetJlptLevel,
      );
      await _analyticsService.clearCache();
      if (!mounted) return;
      showAppToast(
        context,
        message: result.syncedRemotely
            ? '학습 목표를 저장했습니다.'
            : '학습 목표를 저장했습니다. 서버 동기화는 나중에 다시 시도됩니다.',
      );
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      showAppToast(
        context,
        message: '학습 목표 저장에 실패했습니다.',
        type: AppToastType.error,
      );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = FTheme.of(context);

    return Scaffold(
      backgroundColor: theme.colors.background,
      body: Column(
        children: [
          CustomHeader(
            title: const Text('학습 목표'),
            titleAlign: HeaderTitleAlign.center,
            withBack: true,
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: FCircularProgress())
                : SingleChildScrollView(
                    padding: AppSpacing.screenPadding,
                    child: FCard(
                      child: Padding(
                        padding: AppSpacing.cardPadding,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '매일 학습할 단어 목표',
                              style: theme.typography.lg.copyWith(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '홈에서 추천할 단어 수와 중심 난이도를 정합니다.',
                              style: theme.typography.sm.copyWith(
                                color: theme.colors.mutedForeground,
                              ),
                            ),
                            const SizedBox(height: 24),
                            _buildDailyGoalStepper(theme),
                            const SizedBox(height: 24),
                            _buildJlptSelector(theme),
                            const SizedBox(height: 24),
                            SizedBox(
                              width: double.infinity,
                              child: FButton(
                                onPress: _isSaving ? null : _saveGoal,
                                child: _isSaving
                                    ? const SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: FCircularProgress(),
                                      )
                                    : const Text('저장'),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildDailyGoalStepper(FThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '하루 단어 수',
          style: theme.typography.sm.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            _buildStepButton(
              theme,
              icon: Icons.remove,
              onTap: _dailyGoal <= 1
                  ? null
                  : () => setState(() => _dailyGoal--),
            ),
            Expanded(
              child: Center(
                child: Text(
                  '$_dailyGoal개',
                  style: theme.typography.xl.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
            _buildStepButton(
              theme,
              icon: Icons.add,
              onTap: _dailyGoal >= 100
                  ? null
                  : () => setState(() => _dailyGoal++),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStepButton(
    FThemeData theme, {
    required IconData icon,
    required VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: onTap == null
              ? theme.colors.secondary.withValues(alpha: 0.2)
              : theme.colors.secondary.withValues(alpha: 0.45),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: theme.colors.border),
        ),
        child: Icon(
          icon,
          size: 20,
          color: onTap == null
              ? theme.colors.mutedForeground
              : theme.colors.foreground,
        ),
      ),
    );
  }

  Widget _buildJlptSelector(FThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '목표 JLPT',
          style: theme.typography.sm.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final level in const [5, 4, 3, 2, 1])
              _buildJlptOption(theme, level),
          ],
        ),
      ],
    );
  }

  Widget _buildJlptOption(FThemeData theme, int level) {
    final selected = _targetJlptLevel == level;
    return GestureDetector(
      onTap: () => setState(() => _targetJlptLevel = level),
      child: Container(
        width: 58,
        height: 40,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? theme.colors.primary : theme.colors.background,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selected ? theme.colors.primary : theme.colors.border,
          ),
        ),
        child: Text(
          'N$level',
          style: theme.typography.sm.copyWith(
            color: selected
                ? theme.colors.primaryForeground
                : theme.colors.foreground,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}
