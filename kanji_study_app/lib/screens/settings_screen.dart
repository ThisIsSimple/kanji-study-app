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
    final typography = theme.typography;

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
              padding: AppSpacing.screenPadding / 2,
              child: FItemGroup(
                children: [
                  FItem(
                    prefix: Icon(PhosphorIconsRegular.userCircle, size: 26),
                    title: Text(
                      '계정 관리',
                      style: typography.base.copyWith(fontWeight: FontWeight.w500),
                    ),
                    details: Text(
                      '로그인 정보 및 계정 설정',
                      style: typography.sm,
                    ),
                    suffix: Icon(PhosphorIconsRegular.caretRight, size: 20),
                    onPress: () =>
                        _navigateTo(context, const SettingsAccountScreen()),
                  ),
                  FItem(
                    prefix: Icon(PhosphorIconsRegular.bell, size: 26),
                    title: Text(
                      '알림',
                      style: typography.base.copyWith(fontWeight: FontWeight.w500),
                    ),
                    details: Text(
                      '학습 알림 및 시간 설정',
                      style: typography.sm,
                    ),
                    suffix: Icon(PhosphorIconsRegular.caretRight, size: 20),
                    onPress: () => _navigateTo(
                      context,
                      const SettingsNotificationScreen(),
                    ),
                  ),
                  FItem(
                    prefix: Icon(PhosphorIconsRegular.sparkle, size: 26),
                    title: Text(
                      'AI 설정',
                      style: typography.base.copyWith(fontWeight: FontWeight.w500),
                    ),
                    details: Text(
                      'Gemini API 키 관리',
                      style: typography.sm,
                    ),
                    suffix: Icon(PhosphorIconsRegular.caretRight, size: 20),
                    onPress: () =>
                        _navigateTo(context, const SettingsAiScreen()),
                  ),
                  FItem(
                    prefix: Icon(PhosphorIconsRegular.info, size: 26),
                    title: Text(
                      '앱 정보',
                      style: typography.base.copyWith(fontWeight: FontWeight.w500),
                    ),
                    details: Text(
                      '버전 및 개발자 정보',
                      style: typography.sm,
                    ),
                    suffix: Icon(PhosphorIconsRegular.caretRight, size: 20),
                    onPress: () =>
                        _navigateTo(context, const SettingsInfoScreen()),
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
    Navigator.of(context).push(MaterialPageRoute(builder: (context) => screen));
  }
}
