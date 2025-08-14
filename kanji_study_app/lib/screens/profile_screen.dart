import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:intl/intl.dart';
import '../services/supabase_service.dart';
import '../utils/nickname_generator.dart';
import '../models/daily_study_stats.dart';
import 'settings_screen.dart';
import 'study_calendar_screen.dart';
import 'study_calendar_detail_screen.dart';

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
  List<DailyStudyStats> _weeklyStats = [];

  @override
  void initState() {
    super.initState();
    _loadWeeklyStats();
    _loadUserProfile();
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
      
      // Get user profile from Supabase
      final profile = await _supabaseService.getUserProfile();
      debugPrint('Loaded profile: $profile');
      
      if (profile != null && profile['username'] != null && profile['username'].toString().isNotEmpty) {
        setState(() {
          _username = profile['username'];
        });
        debugPrint('Username loaded: $_username');
      } else {
        debugPrint('No username found in profile');
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
      
      // Get email from current user
      if (currentUser != null && currentUser.email != null) {
        setState(() {
          _userEmail = currentUser.email!;
        });
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
      MaterialPageRoute(
        builder: (context) => const SettingsScreen(),
      ),
    );
    
    if (result == true) {
      _loadWeeklyStats();
      _loadUserProfile();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = FTheme.of(context);
    
    return FScaffold(
      header: FHeader(
        title: Text(
          '프로필',
          style: TextStyle(fontFamily: 'SUITE'),
        ),
        suffixes: [
          IconButton(
            icon: Icon(PhosphorIconsRegular.gear),
            onPressed: _navigateToSettings,
          ),
        ],
      ),
      child: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // User Info Card
                  FCard(
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              color: theme.colors.secondary.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              PhosphorIconsFill.user,
                              size: 40,
                              color: theme.colors.primary,
                            ),
                          ),
                          const SizedBox(height: 16),
                          _isLoadingProfile
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : Text(
                                  _username.isEmpty ? '로딩 중...' : _username,
                                  style: theme.typography.lg.copyWith(
                                    fontWeight: FontWeight.bold,
                                    fontFamily: 'SUITE',
                                  ),
                                ),
                          const SizedBox(height: 8),
                          Text(
                            _userEmail.isEmpty ? '익명 사용자' : _userEmail,
                            style: theme.typography.sm.copyWith(
                              color: theme.colors.mutedForeground,
                              fontFamily: 'SUITE',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Weekly Calendar Card
                  FCard(
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
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
                                  fontFamily: 'SUITE',
                                ),
                              ),
                              FButton(
                                onPress: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => const StudyCalendarScreen(),
                                    ),
                                  );
                                },
                                style: FButtonStyle.outline(),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(PhosphorIconsRegular.calendar, size: 16),
                                    const SizedBox(width: 6),
                                    const Text(
                                      '전체 보기',
                                      style: TextStyle(fontFamily: 'SUITE'),
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
                DateFormat('E', 'ko_KR').format(startOfWeek.add(Duration(days: i)))[0],
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
              _buildDayCell(
                startOfWeek.add(Duration(days: i)),
                theme,
              ),
          ],
        ),
        const SizedBox(height: 16),
        // Legend
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildLegendItem('미학습', Colors.grey.shade200, theme),
            const SizedBox(width: 16),
            _buildLegendItem('1-4개', Colors.blue.shade100, theme),
            const SizedBox(width: 16),
            _buildLegendItem('5-9개', Colors.blue.shade300, theme),
            const SizedBox(width: 16),
            _buildLegendItem('10+개', Colors.blue.shade500, theme),
          ],
        ),
      ],
    );
  }
  
  Widget _buildDayHeader(String day, FThemeData theme) {
    return Text(
      day,
      style: theme.typography.sm.copyWith(
        color: theme.colors.mutedForeground,
        fontFamily: 'SUITE',
        fontWeight: FontWeight.w600,
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
        width: 42,
        height: 42,
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
                style: theme.typography.sm.copyWith(
                  fontWeight: isToday ? FontWeight.bold : FontWeight.w500,
                  color: stats.totalStudied > 9 ? Colors.white : theme.colors.foreground,
                ),
              ),
              if (stats.totalStudied > 0)
                Text(
                  '${stats.totalStudied}',
                  style: theme.typography.xs.copyWith(
                    fontSize: 10,
                    color: stats.totalStudied > 9 ? Colors.white : theme.colors.foreground,
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
            fontFamily: 'SUITE',
          ),
        ),
      ],
    );
  }

}