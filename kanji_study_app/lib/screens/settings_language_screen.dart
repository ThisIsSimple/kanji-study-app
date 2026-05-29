import 'package:flutter/material.dart';
import 'package:forui/forui.dart';

import '../constants/app_spacing.dart';
import '../l10n/localization_extensions.dart';
import '../models/language_settings.dart';
import '../services/language_settings_service.dart';
import '../widgets/custom_header.dart';

class SettingsLanguageScreen extends StatefulWidget {
  const SettingsLanguageScreen({super.key});

  @override
  State<SettingsLanguageScreen> createState() => _SettingsLanguageScreenState();
}

class _SettingsLanguageScreenState extends State<SettingsLanguageScreen> {
  final _languageSettings = LanguageSettingsService.instance;

  @override
  void initState() {
    super.initState();
    _languageSettings.addListener(_onSettingsChanged);
  }

  @override
  void dispose() {
    _languageSettings.removeListener(_onSettingsChanged);
    super.dispose();
  }

  void _onSettingsChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final theme = FTheme.of(context);
    final l10n = context.l10n;

    return Scaffold(
      backgroundColor: theme.colors.background,
      body: Column(
        children: [
          CustomHeader(
            title: Text(l10n.languageSettings),
            titleAlign: HeaderTitleAlign.center,
            withBack: true,
          ),
          Expanded(
            child: ListView(
              padding: AppSpacing.screenPadding,
              children: [
                _buildSection(
                  context,
                  title: l10n.appLanguage,
                  children: AppLanguage.values.map((language) {
                    return _languageOption(
                      context,
                      label: _labelForAppLanguage(context, language),
                      selected: _languageSettings.appLanguage == language,
                      onTap: () => _languageSettings.setAppLanguage(language),
                    );
                  }).toList(),
                ),
                const SizedBox(height: AppSpacing.lg),
                _buildSection(
                  context,
                  title: l10n.kanjiMeaningLanguage,
                  children: KanjiMeaningLanguage.values.map((language) {
                    return _languageOption(
                      context,
                      label: _labelForKanjiLanguage(context, language),
                      selected:
                          _languageSettings.kanjiMeaningLanguage == language,
                      onTap: () =>
                          _languageSettings.setKanjiMeaningLanguage(language),
                    );
                  }).toList(),
                ),
                const SizedBox(height: AppSpacing.lg),
                _buildSection(
                  context,
                  title: l10n.wordMeaningLanguage,
                  children: WordMeaningLanguage.values.map((language) {
                    return _languageOption(
                      context,
                      label: _labelForWordLanguage(context, language),
                      selected:
                          _languageSettings.wordMeaningLanguage == language,
                      onTap: () =>
                          _languageSettings.setWordMeaningLanguage(language),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(
    BuildContext context, {
    required String title,
    required List<FItemMixin> children,
  }) {
    final theme = FTheme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
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
        FItemGroup(children: children),
      ],
    );
  }

  FItem _languageOption(
    BuildContext context, {
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    final theme = FTheme.of(context);
    return FItem(
      title: Text(label),
      suffix: selected
          ? Icon(Icons.check, color: theme.colors.primary, size: 20)
          : null,
      onPress: onTap,
    );
  }

  String _labelForAppLanguage(BuildContext context, AppLanguage language) {
    final l10n = context.l10n;
    return switch (language) {
      AppLanguage.ko => l10n.korean,
      AppLanguage.ja => l10n.japanese,
      AppLanguage.en => l10n.english,
    };
  }

  String _labelForKanjiLanguage(
    BuildContext context,
    KanjiMeaningLanguage language,
  ) {
    final l10n = context.l10n;
    return switch (language) {
      KanjiMeaningLanguage.ko => l10n.korean,
      KanjiMeaningLanguage.en => l10n.english,
    };
  }

  String _labelForWordLanguage(
    BuildContext context,
    WordMeaningLanguage language,
  ) {
    final l10n = context.l10n;
    return switch (language) {
      WordMeaningLanguage.ko => l10n.korean,
      WordMeaningLanguage.en => l10n.english,
      WordMeaningLanguage.ja => l10n.japanese,
    };
  }
}
