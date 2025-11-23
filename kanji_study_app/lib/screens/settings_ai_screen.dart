import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/gemini_service.dart';
import '../constants/app_spacing.dart';
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('API 키가 저장되었습니다.')),
      );
    }
  }

  Future<void> _openAiStudio() async {
    final uri = Uri.parse('https://aistudio.google.com/app/apikey');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('브라우저에서 aistudio.google.com을 방문하여 API 키를 생성하세요.'),
        ),
      );
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
            title: const Text('AI 설정'),
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
                                  'Gemini API를 사용하여 예문 생성 및 학습 콘텐츠를 만들 수 있습니다.',
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
                                controller: _apiKeyController,
                                hint: 'API 키를 입력하세요',
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
                              style: FButtonStyle.ghost(),
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
                          style: FButtonStyle.primary(),
                          child: const Text('API 키 저장'),
                        ),

                        const SizedBox(height: 24),

                        // Get API Key Link
                        GestureDetector(
                          onTap: _openAiStudio,
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: theme.colors.secondary.withValues(alpha: 0.1),
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
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'API 키 받기',
                                          style: theme.typography.base.copyWith(
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          'Google AI Studio에서 무료로 발급',
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
                            'API 키는 기기에 안전하게 저장되며, 예문 생성 요청 시에만 사용됩니다.',
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
