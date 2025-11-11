import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:forui/forui.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../services/supabase_service.dart';
import '../utils/nickname_generator.dart';
import 'main_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final SupabaseService _supabaseService = SupabaseService.instance;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    // Set system UI overlay style for better appearance
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
    );
  }

  Future<void> _handleGuestLogin() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Sign in anonymously
      await _supabaseService.signInAnonymously();
      debugPrint('Signed in anonymously');

      // Generate and save nickname for anonymous user
      if (_supabaseService.isLoggedIn) {
        final userId = _supabaseService.currentUser!.id;
        final nickname = NicknameGenerator.instance.generate(userId);
        debugPrint('Generated nickname for guest: $nickname');

        try {
          await _supabaseService.updateUserProfile(username: nickname);
          debugPrint('Successfully saved nickname to Supabase');
        } catch (updateError) {
          debugPrint('Failed to save nickname to Supabase: $updateError');
        }
      }

      if (mounted) {
        // Navigate to main screen
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const MainScreen()),
        );
      }
    } catch (e) {
      setState(() {
        _errorMessage = '게스트 로그인 실패: ${e.toString()}';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _handleGoogleSignIn() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await _supabaseService.signInWithGoogle();
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const MainScreen()),
        );
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
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const MainScreen()),
        );
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
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const MainScreen()),
        );
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

  @override
  Widget build(BuildContext context) {
    final theme = FTheme.of(context);
    final screenHeight = MediaQuery.of(context).size.height;

    return FScaffold(
      child: SafeArea(
        child: SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight:
                  screenHeight -
                  MediaQuery.of(context).padding.top -
                  MediaQuery.of(context).padding.bottom,
            ),
            child: IntrinsicHeight(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Spacer(flex: 2),

                    // App Logo and Title
                    Column(
                      children: [
                        Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            color: theme.colors.primary.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              '漢',
                              style: TextStyle(
                                fontSize: 48,
                                fontWeight: FontWeight.bold,
                                color: theme.colors.primary,
                                fontFamily: 'Noto Serif JP',
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          '콘나칸지',
                          style: theme.typography.xl2.copyWith(
                            fontWeight: FontWeight.bold,
                            fontFamily: 'SUITE',
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '일본어 공부, 바로 이런 느낌!',
                          style: theme.typography.base.copyWith(
                            color: theme.colors.mutedForeground,
                            fontFamily: 'SUITE',
                          ),
                        ),
                      ],
                    ),

                    const Spacer(flex: 3),

                    // Social Login Buttons
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Google Sign In
                        FButton(
                          onPress: _isLoading ? null : _handleGoogleSignIn,
                          style: FButtonStyle.outline(),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(PhosphorIconsRegular.googleLogo, size: 20),
                              const SizedBox(width: 12),
                              Text(
                                'Google로 계속하기',
                                style: TextStyle(
                                  fontFamily: 'SUITE',
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Apple Sign In
                        FButton(
                          onPress: _isLoading ? null : _handleAppleSignIn,
                          style: FButtonStyle.outline(),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(PhosphorIconsRegular.appleLogo, size: 20),
                              const SizedBox(width: 12),
                              Text(
                                'Apple로 계속하기',
                                style: TextStyle(
                                  fontFamily: 'SUITE',
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Kakao Sign In
                        Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEE500),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: _isLoading ? null : _handleKakaoSignIn,
                              borderRadius: BorderRadius.circular(8),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      PhosphorIconsRegular.chatsCircle,
                                      size: 20,
                                      color: Colors.black87,
                                    ),
                                    const SizedBox(width: 12),
                                    Text(
                                      '카카오로 계속하기',
                                      style: TextStyle(
                                        fontFamily: 'SUITE',
                                        fontWeight: FontWeight.w500,
                                        color: Colors.black87,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Divider with text
                        Row(
                          children: [
                            Expanded(
                              child: Container(
                                height: 1,
                                color: theme.colors.border,
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                              child: Text(
                                '또는',
                                style: theme.typography.sm.copyWith(
                                  color: theme.colors.mutedForeground,
                                  fontFamily: 'SUITE',
                                ),
                              ),
                            ),
                            Expanded(
                              child: Container(
                                height: 1,
                                color: theme.colors.border,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 24),

                        // Guest Login Button
                        FButton(
                          onPress: _isLoading ? null : _handleGuestLogin,
                          style: FButtonStyle.secondary(),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(PhosphorIconsRegular.userCircle, size: 20),
                              const SizedBox(width: 12),
                              Text(
                                '게스트로 시작하기',
                                style: TextStyle(
                                  fontFamily: 'SUITE',
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 12),

                        // Guest login info
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: theme.colors.secondary.withValues(
                              alpha: 0.1,
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                PhosphorIconsRegular.info,
                                size: 16,
                                color: theme.colors.mutedForeground,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  '게스트로 시작하면 나중에 SNS 계정을 연동하여 데이터를 안전하게 보관할 수 있습니다.',
                                  style: theme.typography.xs.copyWith(
                                    color: theme.colors.mutedForeground,
                                    fontFamily: 'SUITE',
                                    height: 1.4,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    // Error Message
                    if (_errorMessage != null) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: theme.colors.destructive.withValues(
                            alpha: 0.1,
                          ),
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

                    // Loading Overlay
                    if (_isLoading) ...[
                      const SizedBox(height: 16),
                      const Center(child: CircularProgressIndicator()),
                    ],

                    const Spacer(flex: 2),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
