import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../services/notification_service.dart';
import '../services/gemini_service.dart';
import '../services/supabase_service.dart';
import '../constants/app_spacing.dart';
import '../widgets/custom_header.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final NotificationService _notificationService = NotificationService.instance;
  final GeminiService _geminiService = GeminiService.instance;
  final SupabaseService _supabaseService = SupabaseService.instance;
  final TextEditingController _apiKeyController = TextEditingController();
  bool _notificationsEnabled = false;
  TimeOfDay _selectedTime = const TimeOfDay(hour: 9, minute: 0);
  bool _isLoading = true;
  bool _apiKeyVisible = false;
  String? _userEmail;
  bool _isAnonymous = false;

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
    final enabled = await _notificationService.areNotificationsEnabled();
    final scheduledTime = await _notificationService.getScheduledTime();
    await _geminiService.init();

    // Load user info
    final user = _supabaseService.currentUser;

    setState(() {
      _notificationsEnabled = enabled;
      if (scheduledTime != null) {
        _selectedTime = TimeOfDay(
          hour: scheduledTime['hour']!,
          minute: scheduledTime['minute']!,
        );
      }
      if (_geminiService.apiKey != null) {
        _apiKeyController.text = _geminiService.apiKey!;
      }
      _userEmail = user?.email;
      _isAnonymous = user?.isAnonymous ?? false;
      _isLoading = false;
    });
  }

  Future<void> _toggleNotifications(bool value) async {
    setState(() {
      _notificationsEnabled = value;
    });

    if (value) {
      await _notificationService.scheduleDailyNotification(
        hour: _selectedTime.hour,
        minute: _selectedTime.minute,
      );
    } else {
      await _notificationService.disableNotifications();
    }
  }

  Future<void> _handleLogout() async {
    final shouldLogout = await showFDialog<bool>(
      context: context,
      builder: (context, style, animation) => FDialog(
        style: style,
        animation: animation,
        direction: Axis.horizontal,
        title: const Text('로그아웃'),
        body: Text(
          _isAnonymous
              ? '게스트 계정에서 로그아웃하면 학습 기록이 삭제될 수 있습니다. 계속하시겠습니까?'
              : '정말 로그아웃 하시겠습니까?',
        ),
        actions: [
          FButton(
            style: FButtonStyle.outline(),
            onPress: () => Navigator.of(context).pop(false),
            child: const Text('취소'),
          ),
          FButton(
            style: FButtonStyle.destructive(),
            onPress: () => Navigator.of(context).pop(true),
            child: const Text('로그아웃'),
          ),
        ],
      ),
    );

    if (shouldLogout == true && mounted) {
      try {
        await _supabaseService.signOut();
        // The StreamBuilder in main.dart will automatically navigate to LoginScreen
        // when the auth state changes
        debugPrint('User signed out successfully');
      } catch (e) {
        debugPrint('Logout error: $e');
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('로그아웃 중 오류가 발생했습니다.')));
      }
    }
  }

  Future<void> _selectTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
      builder: (BuildContext context, Widget? child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: false),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _selectedTime) {
      setState(() {
        _selectedTime = picked;
      });

      if (_notificationsEnabled) {
        await _notificationService.scheduleDailyNotification(
          hour: picked.hour,
          minute: picked.minute,
        );
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
            title: const Text('설정'),
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
                        // Account Management Card
                        FCard(
                          child: Padding(
                            padding: AppSpacing.cardPadding,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '계정 관리',
                                  style: theme.typography.lg.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 20),

                                // User Info
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: theme.colors.secondary.withValues(
                                      alpha: 0.1,
                                    ),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        _isAnonymous
                                            ? PhosphorIconsRegular.userCircle
                                            : PhosphorIconsRegular.userCheck,
                                        size: 32,
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              _isAnonymous
                                                  ? '게스트 사용자'
                                                  : (_userEmail ?? '사용자'),
                                              style: theme.typography.base
                                                  .copyWith(
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                            ),
                                            if (_isAnonymous) ...[
                                              const SizedBox(height: 4),
                                              Text(
                                                'SNS 계정을 연동하여 데이터를 안전하게 보관하세요',
                                                style: theme.typography.sm
                                                    .copyWith(
                                                      color: theme
                                                          .colors
                                                          .mutedForeground,
                                                    ),
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 16),

                                // Logout Button
                                FButton(
                                  onPress: _handleLogout,
                                  style: FButtonStyle.destructive(),
                                  child: const Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        PhosphorIconsRegular.signOut,
                                        size: 18,
                                      ),
                                      SizedBox(width: 8),
                                      Text('로그아웃'),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Notification Settings Card
                        FCard(
                          child: Padding(
                            padding: AppSpacing.cardPadding,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '알림 설정',
                                  style: theme.typography.lg.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 20),

                                // Notification Toggle
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      '학습 알림',
                                      style: theme.typography.base.copyWith(),
                                    ),
                                    FSwitch(
                                      value: _notificationsEnabled,
                                      onChange: _toggleNotifications,
                                    ),
                                  ],
                                ),

                                if (_notificationsEnabled) ...[
                                  const SizedBox(height: 24),

                                  // Time Selection
                                  Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: theme.colors.secondary.withValues(
                                        alpha: 0.1,
                                      ),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: GestureDetector(
                                      onTap: _selectTime,
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                '알림 시간',
                                                style: theme.typography.sm
                                                    .copyWith(
                                                      color: theme
                                                          .colors
                                                          .mutedForeground,
                                                    ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                _selectedTime.format(context),
                                                style: theme.typography.lg
                                                    .copyWith(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                              ),
                                            ],
                                          ),
                                          Icon(PhosphorIconsRegular.clock),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Gemini API Settings Card
                        FCard(
                          child: Padding(
                            padding: AppSpacing.cardPadding,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'AI 설정',
                                  style: theme.typography.lg.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'Gemini API를 사용하여 예문 생성 및 학습 콘텐츠를 만들 수 있습니다.',
                                  style: theme.typography.sm.copyWith(
                                    color: theme.colors.mutedForeground,
                                  ),
                                ),
                                const SizedBox(height: 16),

                                // API Key Input with visibility toggle
                                Row(
                                  children: [
                                    Expanded(
                                      child: FTextField(
                                        controller: _apiKeyController,
                                        label: Text('Gemini API Key'),
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
                                const SizedBox(height: 12),
                                FButton(
                                  onPress: () async {
                                    final apiKey = _apiKeyController.text
                                        .trim();
                                    if (apiKey.isNotEmpty) {
                                      await _geminiService.setApiKey(apiKey);
                                      if (!context.mounted) return;
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text('API 키가 저장되었습니다.'),
                                        ),
                                      );
                                    }
                                  },
                                  style: FButtonStyle.outline(),
                                  child: const Text('API 키 저장'),
                                ),
                                const SizedBox(height: 8),
                                GestureDetector(
                                  onTap: () {
                                    // Open AI Studio link
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          '브라우저에서 ai.google.dev를 방문하여 API 키를 생성하세요.',
                                        ),
                                      ),
                                    );
                                  },
                                  child: Text(
                                    'API 키 받기 →',
                                    style: theme.typography.sm.copyWith(
                                      color: theme.colors.primary,
                                      decoration: TextDecoration.underline,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // About Card
                        FCard(
                          child: Padding(
                            padding: AppSpacing.cardPadding,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '앱 정보',
                                  style: theme.typography.lg.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      '버전',
                                      style: theme.typography.base.copyWith(),
                                    ),
                                    Text(
                                      '1.0.0',
                                      style: theme.typography.base.copyWith(
                                        color: theme.colors.mutedForeground,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      '개발자',
                                      style: theme.typography.base.copyWith(),
                                    ),
                                    Text(
                                      'space.cordelia273',
                                      style: theme.typography.base.copyWith(
                                        color: theme.colors.mutedForeground,
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
                  ),
          ),
        ],
      ),
    );
  }
}
