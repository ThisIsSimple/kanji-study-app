import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../constants/app_spacing.dart';
import '../widgets/custom_header.dart';

class SettingsPrivacyScreen extends StatelessWidget {
  const SettingsPrivacyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = FTheme.of(context);

    return Scaffold(
      backgroundColor: theme.colors.background,
      body: Column(
        children: [
          CustomHeader(
            title: const Text('개인정보'),
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
                    title: '서버에 저장되는 데이터',
                    rows: const [
                      _PrivacyRow(
                        icon: PhosphorIconsRegular.user,
                        title: '계정 식별자',
                        body: '로그인 유지, 기기 간 학습 기록 동기화',
                      ),
                      _PrivacyRow(
                        icon: PhosphorIconsRegular.envelope,
                        title: '이메일 주소',
                        body: '소셜 로그인 계정 표시 및 인증',
                      ),
                      _PrivacyRow(
                        icon: PhosphorIconsRegular.chartBar,
                        title: '학습 활동',
                        body: '학습 기록, 즐겨찾기, 퀴즈 결과 동기화',
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _Section(
                    title: '기기에만 저장되는 데이터',
                    rows: const [
                      _PrivacyRow(
                        icon: PhosphorIconsRegular.database,
                        title: '학습 콘텐츠 캐시',
                        body: '오프라인 사용을 위한 한자/단어 데이터',
                      ),
                      _PrivacyRow(
                        icon: PhosphorIconsRegular.key,
                        title: 'Gemini API 키',
                        body: '사용자가 입력한 경우 예문/퀴즈 생성에 사용',
                      ),
                      _PrivacyRow(
                        icon: PhosphorIconsRegular.bell,
                        title: '알림 설정',
                        body: '매일 학습 알림 시간과 사용 여부',
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _InfoBox(
                    text:
                        '광고 추적에는 사용하지 않습니다. 계정 및 학습 데이터 삭제는 설정 > 계정 관리에서 시작할 수 있습니다.',
                    theme: theme,
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
