import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../services/kanji_service.dart';
import '../services/supabase_service.dart';
import '../utils/nickname_generator.dart';
import 'settings_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final KanjiService _kanjiService = KanjiService.instance;
  final SupabaseService _supabaseService = SupabaseService.instance;
  
  int _totalKanji = 0;
  int _studiedCount = 0;
  int _masteredCount = 0;
  double _progress = 0.0;
  bool _isLoading = true;
  bool _isLoadingProfile = true;
  String _username = '';
  String _userEmail = '';

  @override
  void initState() {
    super.initState();
    _loadStatistics();
    _loadUserProfile();
  }

  Future<void> _loadStatistics() async {
    try {
      await _kanjiService.init();
      
      setState(() {
        _totalKanji = _kanjiService.getAllKanji().length;
        _studiedCount = _kanjiService.getStudiedCount();
        _masteredCount = _kanjiService.getMasteredCount();
        _progress = _kanjiService.getOverallProgress();
        _isLoading = false;
      });
    } catch (e) {
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
      _loadStatistics();
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
                  
                  // Overall Progress Card
                  FCard(
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '전체 진도',
                            style: theme.typography.lg.copyWith(
                              fontWeight: FontWeight.bold,
                              fontFamily: 'SUITE',
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              _buildStatItem(
                                '전체',
                                '$_totalKanji',
                                theme.colors.primary,
                              ),
                              _buildStatItem(
                                '학습',
                                '$_studiedCount',
                                theme.colors.primary.withValues(alpha: 0.7),
                              ),
                              _buildStatItem(
                                '마스터',
                                '$_masteredCount',
                                theme.colors.primary,
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          LinearProgressIndicator(
                            value: _progress,
                            backgroundColor: theme.colors.secondary.withValues(alpha: 0.2),
                            valueColor: AlwaysStoppedAnimation<Color>(
                              theme.colors.primary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${(_progress * 100).toStringAsFixed(1)}% 완료',
                            style: theme.typography.sm.copyWith(
                              color: theme.colors.mutedForeground,
                              fontFamily: 'SUITE',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    final theme = FTheme.of(context);
    
    return Column(
      children: [
        Text(
          value,
          style: theme.typography.xl.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
            fontSize: 32,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: theme.typography.sm.copyWith(
            color: theme.colors.mutedForeground,
            fontFamily: 'SUITE',
          ),
        ),
      ],
    );
  }

}