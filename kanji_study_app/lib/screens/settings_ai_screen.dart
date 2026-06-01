import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../l10n/localization_extensions.dart';
import '../services/gemini_service.dart';
import '../constants/app_spacing.dart';
import '../widgets/app_toast.dart';
import '../widgets/custom_header.dart';

class SettingsAiScreen extends StatefulWidget {
  const SettingsAiScreen({super.key});

  @override
  State<SettingsAiScreen> createState() => _SettingsAiScreenState();
}

class _SettingsAiScreenState extends State<SettingsAiScreen> {
  final GeminiService _geminiService = GeminiService.instance;
  final TextEditingController _apiKeyController = TextEditingController();
  bool _apiKeyVisible = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  @override
  void dispose() {
    _apiKeyController.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    await _geminiService.init();

    setState(() {
      if (_geminiService.apiKey != null) {
        _apiKeyController.text = _geminiService.apiKey!;
      }
      _isLoading = false;
    });
  }

  Future<void> _saveApiKey() async {
    final apiKey = _apiKeyController.text.trim();
    if (apiKey.isNotEmpty) {
      await _geminiService.setApiKey(apiKey);
      if (!mounted) return;
      showAppToast(context, message: context.l10n.apiKeySaved);
    }
  }

  Future<void> _openAiStudio() async {
    final uri = Uri.parse('https://aistudio.google.com/app/apikey');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (!mounted) return;
      showAppToast(
        context,
        message: context.l10n.aiStudioOpenFailed,
        type: AppToastType.error,
      );
    }
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
            title: Text(l10n.aiSettings),
            titleAlign: HeaderTitleAlign.center,
            withBack: true,
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: FCircularProgress())
                : SingleChildScrollView(
                    padding: AppSpacing.screenPadding,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Info Section
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: theme.colors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                PhosphorIconsRegular.sparkle,
                                size: 24,
                                color: theme.colors.primary,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  l10n.aiInfo,
                                  style: theme.typography.sm.copyWith(
                                    color: theme.colors.foreground,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 24),

                        // API Key Input Section
                        Text(
                          'Gemini API Key',
                          style: theme.typography.sm.copyWith(
                            fontWeight: FontWeight.w600,
                            color: theme.colors.foreground,
                          ),
                        ),
                        const SizedBox(height: 8),

                        Row(
                          children: [
                            Expanded(
                              child: FTextField(
                                control: FTextFieldControl.managed(
                                  controller: _apiKeyController,
                                ),
                                hint: l10n.apiKeyHint,
                                obscureText: !_apiKeyVisible,
                              ),
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            FButton.icon(
                              onPress: () {
                                setState(() {
                                  _apiKeyVisible = !_apiKeyVisible;
                                });
                              },
                              variant: FButtonVariant.ghost,
                              child: Icon(
                                _apiKeyVisible
                                    ? PhosphorIconsRegular.eyeSlash
                                    : PhosphorIconsRegular.eye,
                                size: 20,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 16),

                        FButton(
                          onPress: _saveApiKey,
                          variant: FButtonVariant.primary,
                          child: Text(l10n.saveApiKey),
                        ),

                        const SizedBox(height: 24),

                        // Get API Key Link
                        GestureDetector(
                          onTap: _openAiStudio,
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: theme.colors.secondary.withValues(
                                alpha: 0.1,
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      PhosphorIconsRegular.key,
                                      size: 24,
                                      color: theme.colors.foreground,
                                    ),
                                    const SizedBox(width: 12),
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          l10n.getApiKey,
                                          style: theme.typography.md.copyWith(
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          l10n.getApiKeyDetails,
                                          style: theme.typography.sm.copyWith(
                                            color: theme.colors.mutedForeground,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                Icon(
                                  PhosphorIconsRegular.arrowSquareOut,
                                  size: 20,
                                  color: theme.colors.mutedForeground,
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Usage Info
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: Text(
                            l10n.apiKeyPrivacy,
                            style: theme.typography.sm.copyWith(
                              color: theme.colors.mutedForeground,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
