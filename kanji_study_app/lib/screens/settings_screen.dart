import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import '../services/notification_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final NotificationService _notificationService = NotificationService.instance;
  bool _notificationsEnabled = false;
  TimeOfDay _selectedTime = const TimeOfDay(hour: 9, minute: 0);
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final enabled = await _notificationService.areNotificationsEnabled();
    final scheduledTime = await _notificationService.getScheduledTime();
    
    setState(() {
      _notificationsEnabled = enabled;
      if (scheduledTime != null) {
        _selectedTime = TimeOfDay(
          hour: scheduledTime['hour']!,
          minute: scheduledTime['minute']!,
        );
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
          : Padding(
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