import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../constants/app_spacing.dart';
import '../l10n/localization_extensions.dart';
import '../widgets/custom_header.dart';

class SettingsPrivacyScreen extends StatelessWidget {
  const SettingsPrivacyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = FTheme.of(context);
    final l10n = context.l10n;

    return Scaffold(
      backgroundColor: theme.colors.background,
      body: Column(
        children: [
          CustomHeader(
            title: Text(l10n.privacy),
            titleAlign: HeaderTitleAlign.center,
            withBack: true,
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: AppSpacing.screenPadding,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _Section(
                    title: l10n.serverStoredData,
                    rows: [
                      _PrivacyRow(
                        icon: PhosphorIconsRegular.user,
                        title: l10n.accountIdentifier,
                        body: l10n.accountIdentifierBody,
                      ),
                      _PrivacyRow(
                        icon: PhosphorIconsRegular.envelope,
                        title: l10n.emailAddress,
                        body: l10n.emailAddressBody,
                      ),
                      _PrivacyRow(
                        icon: PhosphorIconsRegular.chartBar,
                        title: l10n.learningActivity,
                        body: l10n.learningActivityBody,
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _Section(
                    title: l10n.deviceOnlyData,
                    rows: [
                      _PrivacyRow(
                        icon: PhosphorIconsRegular.database,
                        title: l10n.learningContentCache,
                        body: l10n.learningContentCacheBody,
                      ),
                      _PrivacyRow(
                        icon: PhosphorIconsRegular.key,
                        title: l10n.geminiApiKey,
                        body: l10n.geminiApiKeyBody,
                      ),
                      _PrivacyRow(
                        icon: PhosphorIconsRegular.bell,
                        title: l10n.notificationSettings,
                        body: l10n.notificationSettingsBody,
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _InfoBox(text: l10n.privacyInfo, theme: theme),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final List<_PrivacyRow> rows;

  const _Section({required this.title, required this.rows});

  @override
  Widget build(BuildContext context) {
    final theme = FTheme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            title,
            style: theme.typography.sm.copyWith(
              color: theme.colors.mutedForeground,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: theme.colors.secondary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(children: rows),
        ),
      ],
    );
  }
}

class _PrivacyRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;

  const _PrivacyRow({
    required this.icon,
    required this.title,
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    final theme = FTheme.of(context);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 22, color: theme.colors.foreground),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.typography.md.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  body,
                  style: theme.typography.sm.copyWith(
                    color: theme.colors.mutedForeground,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoBox extends StatelessWidget {
  final String text;
  final FThemeData theme;

  const _InfoBox({required this.text, required this.theme});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: theme.typography.sm.copyWith(color: theme.colors.foreground),
      ),
    );
  }
}
