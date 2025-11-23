import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../services/notification_service.dart';
import '../constants/app_spacing.dart';
import '../widgets/custom_header.dart';

class SettingsNotificationScreen extends StatefulWidget {
  const SettingsNotificationScreen({super.key});

  @override
  State<SettingsNotificationScreen> createState() =>
      _SettingsNotificationScreenState();
}

class _SettingsNotificationScreenState
    extends State<SettingsNotificationScreen> {
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

  void _showTimePickerSheet() {
    final theme = FTheme.of(context);

    showFSheet(
      context: context,
      side: FLayout.btt,
      mainAxisMaxRatio: 0.5,
      builder: (context) => _TimePickerSheet(
        theme: theme,
        initialTime: _selectedTime,
        onTimeSelected: (time) async {
          setState(() {
            _selectedTime = time;
          });

          if (_notificationsEnabled) {
            await _notificationService.scheduleDailyNotification(
              hour: time.hour,
              minute: time.minute,
            );
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = FTheme.of(context);

    return Scaffold(
      backgroundColor: theme.colors.background,
      body: Column(
        children: [
          CustomHeader(
            title: const Text('알림'),
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
                        // Notification Toggle
                        Container(
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
                                    PhosphorIconsRegular.bell,
                                    size: 24,
                                    color: theme.colors.foreground,
                                  ),
                                  const SizedBox(width: 12),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '학습 알림',
                                        style: theme.typography.base.copyWith(
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        '매일 학습 시간을 알려드려요',
                                        style: theme.typography.sm.copyWith(
                                          color: theme.colors.mutedForeground,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              FSwitch(
                                value: _notificationsEnabled,
                                onChange: _toggleNotifications,
                              ),
                            ],
                          ),
                        ),

                        if (_notificationsEnabled) ...[
                          const SizedBox(height: 16),

                          // Time Selection
                          GestureDetector(
                            onTap: _showTimePickerSheet,
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
                                        PhosphorIconsRegular.clock,
                                        size: 24,
                                        color: theme.colors.foreground,
                                      ),
                                      const SizedBox(width: 12),
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            '알림 시간',
                                            style: theme.typography.base.copyWith(
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            _selectedTime.format(context),
                                            style: theme.typography.sm.copyWith(
                                              color: theme.colors.mutedForeground,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  Icon(
                                    PhosphorIconsRegular.caretRight,
                                    size: 20,
                                    color: theme.colors.mutedForeground,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],

                        const SizedBox(height: 24),

                        // Info text
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: Text(
                            '알림을 통해 꾸준한 학습 습관을 만들어보세요. 설정한 시간에 매일 학습 알림을 받을 수 있습니다.',
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

class _TimePickerSheet extends StatefulWidget {
  final FThemeData theme;
  final TimeOfDay initialTime;
  final Future<void> Function(TimeOfDay) onTimeSelected;

  const _TimePickerSheet({
    required this.theme,
    required this.initialTime,
    required this.onTimeSelected,
  });

  @override
  State<_TimePickerSheet> createState() => _TimePickerSheetState();
}

class _TimePickerSheetState extends State<_TimePickerSheet> {
  late FTimePickerController _controller;

  @override
  void initState() {
    super.initState();
    _controller = FTimePickerController(
      initial: FTime(widget.initialTime.hour, widget.initialTime.minute),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: widget.theme.colors.background,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: widget.theme.colors.secondary.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),

              // Title
              Text(
                '알림 시간 설정',
                style: widget.theme.typography.lg.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),

              // Time Picker
              SizedBox(
                height: 200,
                child: FTimePicker(
                  controller: _controller,
                ),
              ),

              const SizedBox(height: 24),

              // Buttons
              Row(
                children: [
                  Expanded(
                    child: FButton(
                      style: FButtonStyle.outline(),
                      onPress: () => Navigator.of(context).pop(),
                      child: const Text('취소'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FButton(
                      onPress: () async {
                        final selectedTime = TimeOfDay(
                          hour: _controller.value.hour,
                          minute: _controller.value.minute,
                        );
                        await widget.onTimeSelected(selectedTime);
                        if (context.mounted) {
                          Navigator.of(context).pop();
                        }
                      },
                      child: const Text('확인'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
