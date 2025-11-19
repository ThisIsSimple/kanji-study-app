import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/supabase_service.dart';
import '../utils/nickname_generator.dart';
import '../models/daily_study_stats.dart';
import 'settings_screen.dart';
import 'study_calendar_screen.dart';
import 'study_calendar_detail_screen.dart';
import 'social_login_screen.dart';
import '../widgets/app_scaffold.dart';
import '../constants/app_spacing.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final SupabaseService _supabaseService = SupabaseService.instance;

  bool _isLoading = true;
  bool _isLoadingProfile = true;
  String _username = '';
  String _userEmail = '';
  String? _avatarUrl;
  List<DailyStudyStats> _weeklyStats = [];

  @override
  void initState() {
    super.initState();
    _loadWeeklyStats();
    _loadUserProfile();

    // Listen to auth state changes
    _supabaseService.authStateChanges().listen((authState) {
      if (authState.event == AuthChangeEvent.signedOut) {
        // Clear user data when signed out
        if (mounted) {
          setState(() {
            _username = '';
            _userEmail = '';
            _avatarUrl = null;
            _weeklyStats = [];
          });
        }
      } else if (authState.event == AuthChangeEvent.signedIn) {
        // Reload data when signed in
        _loadWeeklyStats();
        _loadUserProfile();
      }
    });
  }

  Future<void> _loadWeeklyStats() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final stats = await _supabaseService.getWeeklyStudyStats();
      setState(() {
        _weeklyStats = stats;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading weekly stats: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadUserProfile() async {
    setState(() {
      _isLoadingProfile = true;
    });

    try {
      // Get current user info
      final currentUser = _supabaseService.currentUser;
      debugPrint('Current user ID: ${currentUser?.id}');
      debugPrint('Current user email: ${currentUser?.email}');
      debugPrint('Is anonymous: ${_supabaseService.isAnonymousUser}');
      debugPrint('User metadata: ${currentUser?.userMetadata}');

      // Get user profile from Supabase
      final profile = await _supabaseService.getUserProfile();
      debugPrint('Loaded profile: $profile');

      // Check for username in profile or metadata
      String? username;
      if (profile != null &&
          profile['username'] != null &&
          profile['username'].toString().isNotEmpty) {
        username = profile['username'];
      } else if (currentUser?.userMetadata?['username'] != null) {
        username = currentUser!.userMetadata!['username'];
      } else if (currentUser?.userMetadata?['provider'] == 'kakao' &&
          currentUser?.userMetadata?['username'] != null) {
        username = currentUser!.userMetadata!['username'];
      }

      if (username != null) {
        setState(() {
          _username = username!;
        });
        debugPrint('Username loaded: $_username');
      } else {
        debugPrint('No username found in profile or metadata');
        // If no username, try to generate one
        if (currentUser != null) {
          final nickname = NicknameGenerator.instance.generate(currentUser.id);
          debugPrint('Generated nickname for display: $nickname');
          setState(() {
            _username = nickname;
          });
          // Try to save it
          try {
            await _supabaseService.updateUserProfile(username: nickname);
            debugPrint('Saved generated nickname to profile');
          } catch (e) {
            debugPrint('Failed to save nickname: $e');
          }
        }
      }

      // Get email from current user or metadata
      if (currentUser != null) {
        // Get avatar URL from metadata or profile
        String? avatarUrl;
        if (currentUser.userMetadata?['avatar_url'] != null) {
          avatarUrl = currentUser.userMetadata!['avatar_url'];
        } else if (currentUser.userMetadata?['picture'] != null) {
          avatarUrl = currentUser.userMetadata!['picture'];
        } else if (profile != null && profile['avatar_url'] != null) {
          avatarUrl = profile['avatar_url'];
        }

        if (currentUser.email != null && currentUser.email!.isNotEmpty) {
          setState(() {
            _userEmail = currentUser.email!;
            _avatarUrl = avatarUrl;
          });
        } else if (currentUser.userMetadata?['kakao_email'] != null) {
          setState(() {
            _userEmail = '카카오 계정';
            _avatarUrl = avatarUrl;
          });
        } else if (currentUser.userMetadata?['provider'] == 'kakao') {
          setState(() {
            _userEmail = '카카오 계정으로 연동됨';
            _avatarUrl = avatarUrl;
          });
        } else if (_supabaseService.isAnonymousUser) {
          setState(() {
            _userEmail = '익명 사용자';
            _avatarUrl = avatarUrl;
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading user profile: $e');
    } finally {
      setState(() {
        _isLoadingProfile = false;
      });
    }
  }

  void _navigateToSettings() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const SettingsScreen()),
    );

    if (result == true) {
      _loadWeeklyStats();
      _loadUserProfile();
    }
  }

  void _navigateToSocialLogin() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const SocialLoginScreen()),
    );

    if (result == true) {
      // Reload profile after successful SNS linking
      _loadUserProfile();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = FTheme.of(context);

    return AppScaffold(
      actions: [
        IconButton(
          icon: Icon(PhosphorIconsRegular.gear),
          onPressed: _navigateToSettings,
        ),
      ],
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: AppSpacing.screenPadding,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // SNS Account Linking Banner for Anonymous Users
                  if (_supabaseService.isAnonymousUser) ...[
                    GestureDetector(
                      onTap: _navigateToSocialLogin,
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              theme.colors.primary.withValues(alpha: 0.1),
                              theme.colors.primary.withValues(alpha: 0.05),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: theme.colors.primary.withValues(alpha: 0.2),
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: theme.colors.primary.withValues(
                                  alpha: 0.1,
                                ),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                PhosphorIconsFill.shieldCheck,
                                color: theme.colors.primary,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'SNS 계정 연동해서 데이터 안전하게 보관하기',
                                    style: theme.typography.sm.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '다른 기기에서도 학습 기록을 이어가세요',
                                    style: theme.typography.xs.copyWith(
                                      color: theme.colors.mutedForeground,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Icon(
                              PhosphorIconsRegular.caretRight,
                              color: theme.colors.mutedForeground,
                              size: 20,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // User Info Card
                  FCard(
                    child: Padding(
                      padding: AppSpacing.cardPadding,
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                color: theme.colors.secondary.withValues(
                                  alpha: 0.1,
                                ),
                                shape: BoxShape.circle,
                                image: _avatarUrl != null
                                    ? DecorationImage(
                                        image: NetworkImage(_avatarUrl!),
                                        fit: BoxFit.cover,
                                      )
                                    : null,
                              ),
                              child: _avatarUrl == null
                                  ? Icon(
                                      PhosphorIconsFill.user,
                                      size: 40,
                                      color: theme.colors.primary,
                                    )
                                  : null,
                            ),
                            const SizedBox(height: 16),
                            _isLoadingProfile
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : Text(
                                    _username.isEmpty ? '로딩 중...' : _username,
                                    style: theme.typography.lg.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                            const SizedBox(height: 8),
                            Text(
                              _userEmail.isEmpty ? '익명 사용자' : _userEmail,
                              style: theme.typography.sm.copyWith(
                                color: theme.colors.mutedForeground,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Weekly Calendar Card
                  FCard(
                    child: Padding(
                      padding: AppSpacing.cardPadding,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '이번 주 학습',
                                style: theme.typography.lg.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              FButton(
                                onPress: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          const StudyCalendarScreen(),
                                    ),
                                  );
                                },
                                style: FButtonStyle.outline(),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      PhosphorIconsRegular.calendar,
                                      size: 16,
                                    ),
                                    const SizedBox(width: 6),
                                    const Text(
                                      '전체 보기',
                                      style: TextStyle(),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          _buildWeeklyCalendar(theme),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildWeeklyCalendar(FThemeData theme) {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));

    return Column(
      children: [
        // Days of week header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            for (int i = 0; i < 7; i++)
              _buildDayHeader(
                DateFormat(
                  'E',
                  'ko_KR',
                ).format(startOfWeek.add(Duration(days: i)))[0],
                theme,
              ),
          ],
        ),
        const SizedBox(height: 12),
        // Calendar days
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            for (int i = 0; i < 7; i++)
              _buildDayCell(startOfWeek.add(Duration(days: i)), theme),
          ],
        ),
        const SizedBox(height: 16),
        // Legend
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 12,
          runSpacing: 8,
          children: [
            _buildLegendItem('미학습', Colors.grey.shade200, theme),
            _buildLegendItem('1-4개', Colors.blue.shade100, theme),
            _buildLegendItem('5-9개', Colors.blue.shade300, theme),
            _buildLegendItem('10+개', Colors.blue.shade500, theme),
          ],
        ),
      ],
    );
  }

  Widget _buildDayHeader(String day, FThemeData theme) {
    return SizedBox(
      width: 36,
      child: Center(
        child: Text(
          day,
          style: theme.typography.xs.copyWith(
            color: theme.colors.mutedForeground,
            fontWeight: FontWeight.w600,
            fontSize: 11,
          ),
        ),
      ),
    );
  }

  Widget _buildDayCell(DateTime date, FThemeData theme) {
    final isToday = DateUtils.isSameDay(date, DateTime.now());
    final stats = _weeklyStats.firstWhere(
      (s) => DateUtils.isSameDay(s.date, date),
      orElse: () => DailyStudyStats(
        date: date,
        kanjiStudied: 0,
        wordsStudied: 0,
        totalCompleted: 0,
        totalForgot: 0,
        studyItems: [],
      ),
    );

    Color getBackgroundColor() {
      final total = stats.totalStudied;
      if (total == 0) return Colors.grey.shade200;
      if (total < 5) return Colors.blue.shade100;
      if (total < 10) return Colors.blue.shade300;
      return Colors.blue.shade500;
    }

    return GestureDetector(
      onTap: () {
        if (stats.totalStudied > 0) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => StudyCalendarDetailScreen(date: date),
            ),
          );
        }
      },
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: getBackgroundColor(),
          borderRadius: BorderRadius.circular(8),
          border: isToday
              ? Border.all(color: theme.colors.primary, width: 2)
              : null,
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${date.day}',
                style: theme.typography.xs.copyWith(
                  fontWeight: isToday ? FontWeight.bold : FontWeight.w500,
                  color: stats.totalStudied > 9
                      ? Colors.white
                      : theme.colors.foreground,
                  fontSize: 12,
                ),
              ),
              if (stats.totalStudied > 0)
                Text(
                  '${stats.totalStudied}',
                  style: theme.typography.xs.copyWith(
                    fontSize: 9,
                    color: stats.totalStudied > 9
                        ? Colors.white
                        : theme.colors.foreground,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color, FThemeData theme) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: theme.typography.xs.copyWith(
            color: theme.colors.mutedForeground,
          ),
        ),
      ],
    );
  }
}
