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
              padding: AppSpacing.screenPadding / 2,
              child: FItemGroup(
                children: [
                  FItem(
                    prefix: Icon(PhosphorIconsRegular.userCircle),
                    title: const Text('계정 관리'),
                    details: const Text('로그인 정보 및 계정 설정'),
                    suffix: Icon(PhosphorIconsRegular.caretRight),
                    onPress: () =>
                        _navigateTo(context, const SettingsAccountScreen()),
                  ),
                  FItem(
                    prefix: Icon(PhosphorIconsRegular.bell),
                    title: const Text('알림'),
                    details: const Text('학습 알림 및 시간 설정'),
                    suffix: Icon(PhosphorIconsRegular.caretRight),
                    onPress: () => _navigateTo(
                      context,
                      const SettingsNotificationScreen(),
                    ),
                  ),
                  FItem(
                    prefix: Icon(PhosphorIconsRegular.sparkle),
                    title: const Text('AI 설정'),
                    details: const Text('Gemini API 키 관리'),
                    suffix: Icon(PhosphorIconsRegular.caretRight),
                    onPress: () =>
                        _navigateTo(context, const SettingsAiScreen()),
                  ),
                  FItem(
                    prefix: Icon(PhosphorIconsRegular.info),
                    title: const Text('앱 정보'),
                    details: const Text('버전 및 개발자 정보'),
                    suffix: Icon(PhosphorIconsRegular.caretRight),
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
