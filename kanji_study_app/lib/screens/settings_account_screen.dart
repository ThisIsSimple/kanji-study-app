import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../services/supabase_service.dart';
import '../services/local_database_service.dart';
import '../constants/app_spacing.dart';
import '../l10n/localization_extensions.dart';
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
    final l10n = context.l10n;
    final shouldLogout = await showFDialog<bool>(
      context: context,
      builder: (context, style, animation) => FDialog(
        animation: animation,
        direction: Axis.horizontal,
        title: Text(l10n.logout),
        body: Text(
          _isAnonymous ? l10n.logoutGuestWarning : l10n.logoutConfirmBody,
        ),
        actions: [
          FButton(
            variant: FButtonVariant.outline,
            onPress: () => Navigator.of(context).pop(false),
            child: Text(l10n.cancel),
          ),
          FButton(
            variant: FButtonVariant.destructive,
            onPress: () => Navigator.of(context).pop(true),
            child: Text(l10n.logout),
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
          message: l10n.logoutFailed,
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
    final l10n = context.l10n;
    final shouldDelete = await showFDialog<bool>(
      context: context,
      builder: (context, style, animation) => FDialog(
        animation: animation,
        direction: Axis.horizontal,
        title: Text(l10n.deleteStudyData),
        body: Text(l10n.deleteStudyDataBody),
        actions: [
          FButton(
            variant: FButtonVariant.outline,
            onPress: () => Navigator.of(context).pop(false),
            child: Text(l10n.cancel),
          ),
          FButton(
            variant: FButtonVariant.destructive,
            onPress: () => Navigator.of(context).pop(true),
            child: Text(l10n.delete),
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
      showAppToast(context, message: l10n.studyDataDeleted);
    } catch (e) {
      if (!mounted) return;
      showAppToast(
        context,
        message: l10n.deleteStudyDataFailed,
        type: AppToastType.error,
      );
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  Future<void> _handleDeleteAccount() async {
    final l10n = context.l10n;
    final shouldDelete = await showFDialog<bool>(
      context: context,
      builder: (context, style, animation) => FDialog(
        animation: animation,
        direction: Axis.horizontal,
        title: Text(l10n.deleteAccount),
        body: Text(l10n.deleteAccountBody),
        actions: [
          FButton(
            variant: FButtonVariant.outline,
            onPress: () => Navigator.of(context).pop(false),
            child: Text(l10n.cancel),
          ),
          FButton(
            variant: FButtonVariant.destructive,
            onPress: () => Navigator.of(context).pop(true),
            child: Text(l10n.deleteAccount),
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
      showAppToast(context, message: l10n.accountDeleteRequested);
    } catch (e) {
      if (!mounted) return;
      showAppToast(
        context,
        message: l10n.deleteAccountUnavailable,
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
    final l10n = context.l10n;

    return Scaffold(
      backgroundColor: theme.colors.background,
      body: Column(
        children: [
          CustomHeader(
            title: Text(l10n.account),
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
                                          ? l10n.guestUser
                                          : (_userEmail ?? l10n.userFallback),
                                      style: theme.typography.md.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      _isAnonymous
                                          ? l10n.guestAccountSubtitle
                                          : l10n.signedInWithEmail,
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
                                    l10n.guestDataLossWarning,
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
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(PhosphorIconsRegular.trash, size: 18),
                              const SizedBox(width: 8),
                              Text(l10n.deleteStudyData),
                            ],
                          ),
                        ),

                        const SizedBox(height: 12),

                        FButton(
                          onPress: _isProcessing ? null : _handleDeleteAccount,
                          variant: FButtonVariant.destructive,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                PhosphorIconsRegular.userMinus,
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Text(l10n.deleteAccount),
                            ],
                          ),
                        ),

                        const SizedBox(height: 12),

                        FButton(
                          onPress: _isProcessing ? null : _handleLogout,
                          variant: FButtonVariant.destructive,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                PhosphorIconsRegular.signOut,
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Text(l10n.logout),
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
