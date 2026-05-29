import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../constants/app_spacing.dart';
import '../l10n/localization_extensions.dart';
import '../widgets/custom_header.dart';
import 'settings_account_screen.dart';
import 'settings_notification_screen.dart';
import 'settings_ai_screen.dart';
import 'settings_info_screen.dart';
import 'settings_privacy_screen.dart';
import 'settings_learning_goal_screen.dart';
import 'settings_language_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = FTheme.of(context);
    final typography = theme.typography;
    final l10n = context.l10n;

    return Scaffold(
      backgroundColor: theme.colors.background,
      body: Column(
        children: [
          CustomHeader(
            title: Text(l10n.settings),
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
                      l10n.account,
                      style: typography.md.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    details: Text(l10n.accountDetails, style: typography.sm),
                    suffix: Icon(PhosphorIconsRegular.caretRight, size: 20),
                    onPress: () =>
                        _navigateTo(context, const SettingsAccountScreen()),
                  ),
                  FItem(
                    prefix: Icon(PhosphorIconsRegular.bell, size: 26),
                    title: Text(
                      l10n.notifications,
                      style: typography.md.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    details: Text(
                      l10n.notificationDetails,
                      style: typography.sm,
                    ),
                    suffix: Icon(PhosphorIconsRegular.caretRight, size: 20),
                    onPress: () => _navigateTo(
                      context,
                      const SettingsNotificationScreen(),
                    ),
                  ),
                  FItem(
                    prefix: Icon(PhosphorIconsRegular.trophy, size: 26),
                    title: Text(
                      l10n.learningGoal,
                      style: typography.md.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    details: Text(
                      l10n.learningGoalDetails,
                      style: typography.sm,
                    ),
                    suffix: Icon(PhosphorIconsRegular.caretRight, size: 20),
                    onPress: () => _navigateTo(
                      context,
                      const SettingsLearningGoalScreen(),
                    ),
                  ),
                  FItem(
                    prefix: Icon(PhosphorIconsRegular.sparkle, size: 26),
                    title: Text(
                      l10n.aiSettings,
                      style: typography.md.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    details: Text(l10n.aiSettingsDetails, style: typography.sm),
                    suffix: Icon(PhosphorIconsRegular.caretRight, size: 20),
                    onPress: () =>
                        _navigateTo(context, const SettingsAiScreen()),
                  ),
                  FItem(
                    prefix: Icon(PhosphorIconsRegular.translate, size: 26),
                    title: Text(
                      l10n.language,
                      style: typography.md.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    details: Text(l10n.languageSettings, style: typography.sm),
                    suffix: Icon(PhosphorIconsRegular.caretRight, size: 20),
                    onPress: () =>
                        _navigateTo(context, const SettingsLanguageScreen()),
                  ),
                  FItem(
                    prefix: Icon(PhosphorIconsRegular.shieldCheck, size: 26),
                    title: Text(
                      l10n.privacy,
                      style: typography.md.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    details: Text(l10n.privacyDetails, style: typography.sm),
                    suffix: Icon(PhosphorIconsRegular.caretRight, size: 20),
                    onPress: () =>
                        _navigateTo(context, const SettingsPrivacyScreen()),
                  ),
                  FItem(
                    prefix: Icon(PhosphorIconsRegular.info, size: 26),
                    title: Text(
                      l10n.appInfo,
                      style: typography.md.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    details: Text(l10n.appInfoDetails, style: typography.sm),
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

  Future<void> _navigateTo(BuildContext context, Widget screen) async {
    final result = await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (context) => screen));
    if (result == true && context.mounted) {
      Navigator.of(context).pop(true);
    }
  }
}
