import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../services/supabase_service.dart';

class SocialLoginScreen extends StatefulWidget {
  const SocialLoginScreen({super.key});

  @override
  State<SocialLoginScreen> createState() => _SocialLoginScreenState();
}

class _SocialLoginScreenState extends State<SocialLoginScreen> {
  final SupabaseService _supabaseService = SupabaseService.instance;
  bool _isLoading = false;
  String? _errorMessage;

  Future<void> _handleGoogleSignIn() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await _supabaseService.signInWithGoogle();
      if (mounted) {
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Google 계정으로 연동되었습니다.'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Google 로그인 실패: ${e.toString()}';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _handleAppleSignIn() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await _supabaseService.signInWithApple();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Apple 계정으로 연동되었습니다.'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Apple 로그인 실패: ${e.toString()}';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _handleKakaoSignIn() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await _supabaseService.signInWithKakao();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('카카오 계정으로 연동되었습니다.'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      setState(() {
        _errorMessage = '카카오 로그인 실패: ${e.toString()}';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _continueAsGuest() {
    Navigator.of(context).pop(false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = FTheme.of(context);
    final isAnonymous = _supabaseService.isAnonymousUser;

    return FScaffold(
      header: FHeader(
        title: Text(
          isAnonymous ? 'SNS 계정 연동' : '로그인',
          style: const TextStyle(fontFamily: 'SUITE'),
        ),
        suffixes: [
          IconButton(
            icon: const Icon(PhosphorIconsRegular.x),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 40),
              // Icon and Title
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: theme.colors.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  PhosphorIconsFill.bookOpen,
                  size: 64,
                  color: theme.colors.primary,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                '한자 학습',
                style: theme.typography.xl2.copyWith(
                  fontWeight: FontWeight.bold,
                  fontFamily: 'SUITE',
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                isAnonymous
                    ? 'SNS 계정을 연동하면 다른 기기에서도\n학습 기록을 이어갈 수 있어요'
                    : 'SNS 계정으로 간편하게 로그인하세요',
                style: theme.typography.sm.copyWith(
                  color: theme.colors.mutedForeground,
                  fontFamily: 'SUITE',
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),

              // Social Login Buttons
              _buildSocialButton(
                onPressed: _isLoading ? null : _handleGoogleSignIn,
                icon: Icons.g_mobiledata_rounded,
                label: 'Google로 계속하기',
                backgroundColor: Colors.white,
                foregroundColor: Colors.black87,
                borderColor: Colors.grey.shade300,
                theme: theme,
              ),
              const SizedBox(height: 12),
              _buildSocialButton(
                onPressed: _isLoading ? null : _handleAppleSignIn,
                icon: PhosphorIconsFill.appleLogo,
                label: 'Apple로 계속하기',
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
                theme: theme,
              ),
              const SizedBox(height: 12),
              _buildSocialButton(
                onPressed: _isLoading ? null : _handleKakaoSignIn,
                icon: Icons.chat_bubble_rounded,
                label: '카카오로 계속하기',
                backgroundColor: const Color(0xFFFEE500),
                foregroundColor: const Color(0xFF000000),
                theme: theme,
              ),

              // Error Message
              if (_errorMessage != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.colors.destructive.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _errorMessage!,
                    style: theme.typography.sm.copyWith(
                      color: theme.colors.destructive,
                      fontFamily: 'SUITE',
                    ),
                  ),
                ),
              ],

              // Guest Continue Button
              if (isAnonymous) ...[
                const SizedBox(height: 48),
                const Divider(),
                const SizedBox(height: 16),
                FButton(
                  onPress: _continueAsGuest,
                  style: FButtonStyle.outline(),
                  child: const Text(
                    '게스트로 계속 사용하기',
                    style: TextStyle(fontFamily: 'SUITE'),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '게스트로 사용하면 기기 변경 시 데이터가 유실될 수 있습니다',
                  style: theme.typography.xs.copyWith(
                    color: theme.colors.mutedForeground,
                    fontFamily: 'SUITE',
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSocialButton({
    required VoidCallback? onPressed,
    required IconData icon,
    required String label,
    required Color backgroundColor,
    required Color foregroundColor,
    Color? borderColor,
    required FThemeData theme,
  }) {
    return Material(
      color: backgroundColor,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            border: borderColor != null
                ? Border.all(color: borderColor)
                : null,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 24,
                color: foregroundColor,
              ),
              const SizedBox(width: 12),
              Text(
                label,
                style: theme.typography.base.copyWith(
                  color: foregroundColor,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'SUITE',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}