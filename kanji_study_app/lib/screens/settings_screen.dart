import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../constants/app_spacing.dart';
import '../widgets/custom_header.dart';
import 'settings_account_screen.dart';
import 'settings_notification_screen.dart';
import 'settings_ai_screen.dart';
import 'settings_info_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = FTheme.of(context);

    return Scaffold(
      backgroundColor: theme.colors.background,
      body: Column(
        children: [
          CustomHeader(
            title: const Text('설정'),
            titleAlign: HeaderTitleAlign.center,
            withBack: true,
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: AppSpacing.screenPadding,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Settings Menu Items
                  _SettingsMenuItem(
                    icon: PhosphorIconsRegular.userCircle,
                    title: '계정 관리',
                    subtitle: '로그인 정보 및 계정 설정',
                    onTap: () => _navigateTo(context, const SettingsAccountScreen()),
                  ),
                  _SettingsMenuItem(
                    icon: PhosphorIconsRegular.bell,
                    title: '알림',
                    subtitle: '학습 알림 및 시간 설정',
                    onTap: () => _navigateTo(context, const SettingsNotificationScreen()),
                  ),
                  _SettingsMenuItem(
                    icon: PhosphorIconsRegular.sparkle,
                    title: 'AI 설정',
                    subtitle: 'Gemini API 키 관리',
                    onTap: () => _navigateTo(context, const SettingsAiScreen()),
                  ),
                  _SettingsMenuItem(
                    icon: PhosphorIconsRegular.info,
                    title: '앱 정보',
                    subtitle: '버전 및 개발자 정보',
                    onTap: () => _navigateTo(context, const SettingsInfoScreen()),
                    showDivider: false,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _navigateTo(BuildContext context, Widget screen) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => screen),
    );
  }
}

class _SettingsMenuItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool showDivider;

  const _SettingsMenuItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.showDivider = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = FTheme.of(context);

    return Column(
      children: [
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 4),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: theme.colors.secondary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    icon,
                    size: 22,
                    color: theme.colors.foreground,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: theme.typography.base.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: theme.typography.sm.copyWith(
                          color: theme.colors.mutedForeground,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  PhosphorIconsRegular.caretRight,
                  size: 20,
                  color: theme.colors.mutedForeground,
                ),
              ],
            ),
          ),
        ),
        if (showDivider)
          Divider(
            height: 1,
            color: theme.colors.secondary.withValues(alpha: 0.2),
          ),
      ],
    );
  }
}
