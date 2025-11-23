import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../constants/app_spacing.dart';
import '../widgets/custom_header.dart';

class SettingsInfoScreen extends StatefulWidget {
  const SettingsInfoScreen({super.key});

  @override
  State<SettingsInfoScreen> createState() => _SettingsInfoScreenState();
}

class _SettingsInfoScreenState extends State<SettingsInfoScreen> {
  String _version = '1.0.0';
  String _buildNumber = '1';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPackageInfo();
  }

  Future<void> _loadPackageInfo() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      setState(() {
        _version = packageInfo.version;
        _buildNumber = packageInfo.buildNumber;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
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
            title: const Text('앱 정보'),
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
                        // App Icon and Name
                        Center(
                          child: Column(
                            children: [
                              Container(
                                width: 80,
                                height: 80,
                                decoration: BoxDecoration(
                                  color: theme.colors.primary.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Icon(
                                  PhosphorIconsFill.bookOpenText,
                                  size: 40,
                                  color: theme.colors.primary,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                '한자 학습',
                                style: theme.typography.xl.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '체계적인 한자 학습 앱',
                                style: theme.typography.sm.copyWith(
                                  color: theme.colors.mutedForeground,
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 32),

                        // Info Items
                        _buildInfoItem(
                          theme,
                          icon: PhosphorIconsRegular.info,
                          label: '버전',
                          value: '$_version ($_buildNumber)',
                        ),
                        const SizedBox(height: 12),
                        _buildInfoItem(
                          theme,
                          icon: PhosphorIconsRegular.code,
                          label: '개발자',
                          value: 'space.cordelia273',
                        ),

                        const SizedBox(height: 32),

                        // Copyright
                        Center(
                          child: Text(
                            '© 2024 space.cordelia273',
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

  Widget _buildInfoItem(
    FThemeData theme, {
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colors.secondary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: 24,
            color: theme.colors.foreground,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: theme.typography.base.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Text(
            value,
            style: theme.typography.base.copyWith(
              color: theme.colors.mutedForeground,
            ),
          ),
        ],
      ),
    );
  }
}
