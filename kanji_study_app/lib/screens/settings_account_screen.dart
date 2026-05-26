import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../services/supabase_service.dart';
import '../services/local_database_service.dart';
import '../constants/app_spacing.dart';
import '../widgets/app_toast.dart';
import '../widgets/custom_header.dart';

class SettingsAccountScreen extends StatefulWidget {
  const SettingsAccountScreen({super.key});

  @override
  State<SettingsAccountScreen> createState() => _SettingsAccountScreenState();
}

class _SettingsAccountScreenState extends State<SettingsAccountScreen> {
  final SupabaseService _supabaseService = SupabaseService.instance;
  String? _userEmail;
  bool _isAnonymous = false;
  bool _isLoading = true;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
  }

  Future<void> _loadUserInfo() async {
    final user = _supabaseService.currentUser;
    setState(() {
      _userEmail = user?.email;
      _isAnonymous = user?.isAnonymous ?? false;
      _isLoading = false;
    });
  }

  Future<void> _handleLogout() async {
    final shouldLogout = await showFDialog<bool>(
      context: context,
      builder: (context, style, animation) => FDialog(
        animation: animation,
        direction: Axis.horizontal,
        title: const Text('로그아웃'),
        body: Text(
          _isAnonymous
              ? '게스트 계정에서 로그아웃하면 학습 기록이 삭제될 수 있습니다. 계속하시겠습니까?'
              : '정말 로그아웃 하시겠습니까?',
        ),
        actions: [
          FButton(
            variant: FButtonVariant.outline,
            onPress: () => Navigator.of(context).pop(false),
            child: const Text('취소'),
          ),
          FButton(
            variant: FButtonVariant.destructive,
            onPress: () => Navigator.of(context).pop(true),
            child: const Text('로그아웃'),
          ),
        ],
      ),
    );

    if (shouldLogout == true && mounted) {
      try {
        await _supabaseService.signOut();
      } catch (e) {
        debugPrint('Logout error: $e');
        if (!mounted) return;
        showAppToast(
          context,
          message: '로그아웃 중 오류가 발생했습니다.',
          type: AppToastType.error,
        );
      }
    }
  }

  Future<void> _clearLocalUserData(String userId) async {
    final localDb = LocalDatabaseService.instance;
    await localDb.database.clearUserData(userId);
  }

  Future<void> _handleDeleteAppData() async {
    final shouldDelete = await showFDialog<bool>(
      context: context,
      builder: (context, style, animation) => FDialog(
        animation: animation,
        direction: Axis.horizontal,
        title: const Text('학습 데이터 삭제'),
        body: const Text('학습 기록, 즐겨찾기, AI 퀴즈 기록을 삭제합니다. 계정 로그인 정보는 유지됩니다.'),
        actions: [
          FButton(
            variant: FButtonVariant.outline,
            onPress: () => Navigator.of(context).pop(false),
            child: const Text('취소'),
          ),
          FButton(
            variant: FButtonVariant.destructive,
            onPress: () => Navigator.of(context).pop(true),
            child: const Text('삭제'),
          ),
        ],
      ),
    );

    if (shouldDelete != true || !mounted) return;

    final userId = _supabaseService.currentUser?.id;
    if (userId == null) return;

    setState(() => _isProcessing = true);
    try {
      await _supabaseService.deleteCurrentUserServerData();
      await _clearLocalUserData(userId);
      if (!mounted) return;
      showAppToast(context, message: '학습 데이터가 삭제되었습니다.');
    } catch (e) {
      if (!mounted) return;
      showAppToast(
        context,
        message: '데이터 삭제 중 오류가 발생했습니다.',
        type: AppToastType.error,
      );
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  Future<void> _handleDeleteAccount() async {
    final shouldDelete = await showFDialog<bool>(
      context: context,
      builder: (context, style, animation) => FDialog(
        animation: animation,
        direction: Axis.horizontal,
        title: const Text('계정 삭제'),
        body: const Text('계정과 서버에 저장된 학습 데이터를 삭제합니다. 이 작업은 되돌릴 수 없습니다.'),
        actions: [
          FButton(
            variant: FButtonVariant.outline,
            onPress: () => Navigator.of(context).pop(false),
            child: const Text('취소'),
          ),
          FButton(
            variant: FButtonVariant.destructive,
            onPress: () => Navigator.of(context).pop(true),
            child: const Text('계정 삭제'),
          ),
        ],
      ),
    );

    if (shouldDelete != true || !mounted) return;

    final userId = _supabaseService.currentUser?.id;
    if (userId == null) return;

    setState(() => _isProcessing = true);
    try {
      await _supabaseService.deleteCurrentUserAccount();
      await _clearLocalUserData(userId);
      if (!mounted) return;
      showAppToast(context, message: '계정 삭제가 요청되었습니다.');
    } catch (e) {
      if (!mounted) return;
      showAppToast(
        context,
        message: '계정 삭제 서버 기능을 확인해주세요. 데이터는 삭제되지 않았습니다.',
        type: AppToastType.error,
      );
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
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
            title: const Text('계정 관리'),
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
                        // User Info Card
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: theme.colors.secondary.withValues(
                              alpha: 0.1,
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: theme.colors.secondary.withValues(
                                    alpha: 0.2,
                                  ),
                                  borderRadius: BorderRadius.circular(24),
                                ),
                                child: Icon(
                                  _isAnonymous
                                      ? PhosphorIconsRegular.userCircle
                                      : PhosphorIconsRegular.userCheck,
                                  size: 28,
                                  color: theme.colors.foreground,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _isAnonymous
                                          ? '게스트 사용자'
                                          : (_userEmail ?? '사용자'),
                                      style: theme.typography.md.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      _isAnonymous
                                          ? '소셜 계정 연동으로 데이터를 안전하게 보관하세요'
                                          : '이메일로 로그인됨',
                                      style: theme.typography.sm.copyWith(
                                        color: theme.colors.mutedForeground,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                        if (_isAnonymous) ...[
                          const SizedBox(height: 16),
                          // Warning for anonymous users
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.orange.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: Colors.orange.withValues(alpha: 0.3),
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  PhosphorIconsRegular.warning,
                                  size: 20,
                                  color: Colors.orange,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    '게스트 계정은 앱 삭제 시 데이터가 손실될 수 있습니다.',
                                    style: theme.typography.sm.copyWith(
                                      color: Colors.orange.shade700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],

                        const SizedBox(height: 32),

                        // Logout Button
                        FButton(
                          onPress: _isProcessing ? null : _handleDeleteAppData,
                          variant: FButtonVariant.outline,
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(PhosphorIconsRegular.trash, size: 18),
                              SizedBox(width: 8),
                              Text('학습 데이터 삭제'),
                            ],
                          ),
                        ),

                        const SizedBox(height: 12),

                        FButton(
                          onPress: _isProcessing ? null : _handleDeleteAccount,
                          variant: FButtonVariant.destructive,
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(PhosphorIconsRegular.userMinus, size: 18),
                              SizedBox(width: 8),
                              Text('계정 삭제'),
                            ],
                          ),
                        ),

                        const SizedBox(height: 12),

                        FButton(
                          onPress: _isProcessing ? null : _handleLogout,
                          variant: FButtonVariant.destructive,
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(PhosphorIconsRegular.signOut, size: 18),
                              SizedBox(width: 8),
                              Text('로그아웃'),
                            ],
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
