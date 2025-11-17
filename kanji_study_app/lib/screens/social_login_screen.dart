import 'dart:async';
import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
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
  String? _waitingMessage;
  StreamSubscription<AuthState>? _authSubscription;

  @override
  void initState() {
    super.initState();
    _setupAuthListener();
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }

  void _setupAuthListener() {
    _authSubscription = _supabaseService.authStateChanges().listen((AuthState state) {
      if (!mounted) return;

      // OAuth 로그인이 완료되면 자동으로 화면 닫기
      if (state.session != null && _isLoading) {
        // 로그인 성공 - WidgetsBinding을 사용하여 안전하게 Navigator 호출
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && Navigator.canPop(context)) {
            Navigator.of(context).pop(true);
          }
        });
      }
    });
  }

  Future<void> _handleSocialLogin(
    Future<bool> Function() loginFunction,
    String providerName,
  ) async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _waitingMessage = null;
    });

    try {
      final success = await loginFunction();

      if (!mounted) return;

      if (success) {
        // OAuth 브라우저가 열렸으므로 대기 메시지 표시
        setState(() {
          _waitingMessage = '브라우저에서 $providerName 로그인을 완료하세요';
        });
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _errorMessage = '$providerName 로그인 실패: ${e.toString()}';
        _isLoading = false;
        _waitingMessage = null;
      });
    }
  }

  Future<void> _handleGoogleSignIn() async {
    await _handleSocialLogin(_supabaseService.signInWithGoogle, 'Google');
  }

  Future<void> _handleAppleSignIn() async {
    await _handleSocialLogin(_supabaseService.signInWithApple, 'Apple');
  }

  Future<void> _handleKakaoSignIn() async {
    await _handleSocialLogin(_supabaseService.signInWithKakao, '카카오');
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
            onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
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
                '콘나칸지',
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

              // Loading indicator or Social Login Buttons
              if (_isLoading)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32.0),
                    child: CircularProgressIndicator(),
                  ),
                )
              else ...[
                _buildSocialButton(
                  onPressed: _handleGoogleSignIn,
                  icon: Icons.g_mobiledata_rounded,
                  label: 'Google로 계속하기',
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black87,
                  borderColor: Colors.grey.shade300,
                  theme: theme,
                ),
                const SizedBox(height: 12),
                _buildSocialButton(
                  onPressed: _handleAppleSignIn,
                  icon: PhosphorIconsFill.appleLogo,
                  label: 'Apple로 계속하기',
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                  theme: theme,
                ),
                const SizedBox(height: 12),
                _buildSocialButton(
                  onPressed: _handleKakaoSignIn,
                  icon: Icons.chat_bubble_rounded,
                  label: '카카오로 계속하기',
                  backgroundColor: const Color(0xFFFEE500),
                  foregroundColor: const Color(0xFF000000),
                  theme: theme,
                ),
              ],

              // Waiting Message
              if (_waitingMessage != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.colors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        PhosphorIconsRegular.browser,
                        size: 16,
                        color: theme.colors.primary,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _waitingMessage!,
                          style: theme.typography.sm.copyWith(
                            color: theme.colors.primary,
                            fontFamily: 'SUITE',
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

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
              if (isAnonymous && !_isLoading) ...[
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
    required VoidCallback onPressed,
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
            border: borderColor != null ? Border.all(color: borderColor) : null,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 24, color: foregroundColor),
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
