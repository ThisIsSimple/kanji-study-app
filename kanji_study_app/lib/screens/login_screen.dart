import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:forui/forui.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../l10n/localization_extensions.dart';
import '../services/supabase_service.dart';
import '../utils/nickname_generator.dart';
import '../widgets/auth_provider_button.dart';

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
    final l10n = context.l10n;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Sign in anonymously
      await _supabaseService.signInAnonymously();

      // Generate and save nickname for anonymous user
      if (_supabaseService.isLoggedIn) {
        final userId = _supabaseService.currentUser!.id;
        final nickname = NicknameGenerator.instance.generate(userId);

        try {
          await _supabaseService.updateUserProfile(username: nickname);
        } catch (updateError) {
          debugPrint('Failed to save nickname to Supabase: $updateError');
        }
      }
    } catch (e) {
      setState(() {
        _errorMessage = l10n.guestLoginFailed(e.toString());
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
    final l10n = context.l10n;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await _supabaseService.signInWithGoogle();
    } catch (e) {
      setState(() {
        _errorMessage = l10n.googleLoginFailed(e.toString());
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
    final l10n = context.l10n;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await _supabaseService.signInWithApple();
    } catch (e) {
      setState(() {
        _errorMessage = l10n.appleLoginFailed(e.toString());
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
    final l10n = context.l10n;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await _supabaseService.signInWithKakao();
    } catch (e) {
      setState(() {
        _errorMessage = l10n.kakaoLoginFailed(e.toString());
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
    final l10n = context.l10n;
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
                            child: Icon(
                              PhosphorIconsFill.bookOpen,
                              size: 48,
                              color: theme.colors.primary,
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          l10n.appTitle,
                          style: theme.typography.xl2.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          l10n.loginSubtitle,
                          style: theme.typography.md.copyWith(
                            color: theme.colors.mutedForeground,
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
                        AuthProviderButton(
                          onPressed: _isLoading ? null : _handleGoogleSignIn,
                          icon: PhosphorIconsRegular.googleLogo,
                          label: l10n.continueWithGoogle,
                          outline: true,
                        ),
                        const SizedBox(height: 12),

                        AuthProviderButton(
                          onPressed: _isLoading ? null : _handleAppleSignIn,
                          icon: PhosphorIconsRegular.appleLogo,
                          label: l10n.continueWithApple,
                          outline: true,
                        ),
                        const SizedBox(height: 12),

                        AuthProviderButton(
                          onPressed: _isLoading ? null : _handleKakaoSignIn,
                          icon: PhosphorIconsRegular.chatsCircle,
                          label: l10n.continueWithKakao,
                          backgroundColor: const Color(0xFFFEE500),
                          foregroundColor: Colors.black87,
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
                                l10n.orDivider,
                                style: theme.typography.sm.copyWith(
                                  color: theme.colors.mutedForeground,
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
                          variant: FButtonVariant.secondary,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(PhosphorIconsRegular.userCircle, size: 20),
                              const SizedBox(width: 12),
                              Text(
                                l10n.startAsGuest,
                                style: TextStyle(fontWeight: FontWeight.w500),
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
                                  l10n.guestStartInfo,
                                  style: theme.typography.xs.copyWith(
                                    color: theme.colors.mutedForeground,
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
                          ),
                        ),
                      ),
                    ],

                    // Loading Overlay
                    if (_isLoading) ...[
                      const SizedBox(height: 16),
                      const Center(child: FCircularProgress()),
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
