import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import '../services/supabase_service.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final SupabaseService _supabaseService = SupabaseService.instance;
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _usernameController = TextEditingController();

  bool _isLoading = false;
  bool _isSignUp = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _usernameController.dispose();
    super.dispose();
  }

  Future<void> _handleAuth() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final username = _usernameController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      setState(() {
        _errorMessage = '이메일과 비밀번호를 입력해주세요.';
      });
      return;
    }

    if (_isSignUp && username.isEmpty) {
      setState(() {
        _errorMessage = '사용자 이름을 입력해주세요.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      if (_isSignUp) {
        await _supabaseService.signUp(
          email: email,
          password: password,
          username: username,
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('회원가입이 완료되었습니다. 이메일을 확인해주세요.')),
          );
        }
      } else {
        await _supabaseService.signIn(email: email, password: password);

        // 로그인 성공 시 메인 화면으로 이동
        if (mounted) {
          Navigator.of(context).pop(true);
        }
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
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

    return FScaffold(
      header: FHeader(title: Text(_isSignUp ? '회원가입' : '로그인')),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Logo or App Name
            Icon(Icons.book, size: 80, color: theme.colors.primary),
            const SizedBox(height: 8),
            Text(
              '한자 학습',
              style: theme.typography.xl.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 48),

            // Email Input
            Material(
              color: Colors.transparent,
              child: TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: '이메일',
                  hintText: 'your@email.com',
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
                  prefixIcon: const Icon(Icons.email),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Username Input (Sign Up only)
            if (_isSignUp) ...[
              Material(
                color: Colors.transparent,
                child: TextField(
                  controller: _usernameController,
                  decoration: InputDecoration(
                    labelText: '사용자 이름',
                    hintText: '닉네임',
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
                    prefixIcon: const Icon(Icons.person),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Password Input
            Material(
              color: Colors.transparent,
              child: TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: '비밀번호',
                  hintText: '••••••••',
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
                  prefixIcon: const Icon(Icons.lock),
                ),
              ),
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
                  ),
                ),
              ),
            ],

            const SizedBox(height: 24),

            // Submit Button
            FButton(
              onPress: _isLoading ? null : _handleAuth,
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: FCircularProgress(),
                    )
                  : Text(_isSignUp ? '회원가입' : '로그인'),
            ),

            const SizedBox(height: 16),

            // Toggle Sign Up/Sign In
            FButton(
              onPress: () {
                setState(() {
                  _isSignUp = !_isSignUp;
                  _errorMessage = null;
                });
              },
              style: FButtonStyle.outline(),
              child: Text(_isSignUp ? '이미 계정이 있으신가요? 로그인' : '계정이 없으신가요? 회원가입'),
            ),
          ],
        ),
      ),
    );
  }
}
