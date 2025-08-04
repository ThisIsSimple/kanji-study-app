import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import '../services/notification_service.dart';
import '../services/gemini_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final NotificationService _notificationService = NotificationService.instance;
  final GeminiService _geminiService = GeminiService.instance;
  final TextEditingController _apiKeyController = TextEditingController();
  bool _notificationsEnabled = false;
  TimeOfDay _selectedTime = const TimeOfDay(hour: 9, minute: 0);
  bool _isLoading = true;
  bool _apiKeyVisible = false;

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
    
    return FScaffold(
      header: FHeader.nested(
        title: const Text('설정'),
        prefixes: [
          FHeaderAction.back(
            onPress: () => Navigator.of(context).pop(),
          ),
        ],
      ),
      child: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Notification Settings Card
                  FCard(
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
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
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '학습 알림',
                                style: theme.typography.base,
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
                                color: theme.colors.secondary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: GestureDetector(
                                onTap: _selectTime,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          '알림 시간',
                                          style: theme.typography.sm.copyWith(
                                            color: theme.colors.mutedForeground,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          _selectedTime.format(context),
                                          style: theme.typography.lg.copyWith(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                    Icon(Icons.access_time),
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
                      padding: const EdgeInsets.all(20.0),
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
                          
                          // API Key Input
                          Material(
                            color: Colors.transparent,
                            child: TextField(
                              controller: _apiKeyController,
                              obscureText: !_apiKeyVisible,
                              decoration: InputDecoration(
                                labelText: 'Gemini API Key',
                                hintText: 'API 키를 입력하세요',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(color: theme.colors.border),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(color: theme.colors.border),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(color: theme.colors.primary),
                                ),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _apiKeyVisible ? Icons.visibility_off : Icons.visibility,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _apiKeyVisible = !_apiKeyVisible;
                                    });
                                  },
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          FButton(
                            onPress: () async {
                              final apiKey = _apiKeyController.text.trim();
                              if (apiKey.isNotEmpty) {
                                await _geminiService.setApiKey(apiKey);
                                if (!context.mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
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
                                  content: Text('브라우저에서 ai.google.dev를 방문하여 API 키를 생성하세요.'),
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
                      padding: const EdgeInsets.all(20.0),
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
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '버전',
                                style: theme.typography.base,
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
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '개발자',
                                style: theme.typography.base,
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
    );
  }
}