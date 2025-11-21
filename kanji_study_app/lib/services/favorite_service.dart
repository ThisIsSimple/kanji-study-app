import 'dart:async';
import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import '../database/app_database.dart';
import 'local_database_service.dart';
import 'supabase_service.dart';
import 'connectivity_service.dart';

/// 즐겨찾기 전역 상태 관리 서비스 (싱글톤)
/// 오프라인 지원 + Supabase 동기화
/// 서버 저장은 비동기로 처리하여 지연 없이 사용
class FavoriteService extends ChangeNotifier {
  static final FavoriteService _instance = FavoriteService._internal();
  static FavoriteService get instance => _instance;

  FavoriteService._internal();

  final LocalDatabaseService _localDb = LocalDatabaseService.instance;
  final SupabaseService _supabaseService = SupabaseService.instance;
  final ConnectivityService _connectivityService = ConnectivityService.instance;

  // 메모리 캐시: "type_targetId" -> isFavorite
  final Map<String, bool> _favoriteCache = {};

  StreamSubscription<bool>? _connectivitySubscription;

  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  /// 서비스 초기화 - 로컬 DB에서 캐시 로드
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      final userId = _supabaseService.currentUser?.id;
      if (userId == null) {
        debugPrint('FavoriteService: No user logged in');
        return;
      }

      // 로컬 DB에서 즐겨찾기 로드 (삭제되지 않은 것만)
      final favorites = await _localDb.database.getFavorites(userId);

      // 캐시에 로드
      for (final favorite in favorites) {
        final key = '${favorite.type}_${favorite.targetId}';
        _favoriteCache[key] = true;
      }

      _isInitialized = true;
      debugPrint('FavoriteService initialized with ${_favoriteCache.length} favorites');

      // 온라인이면 동기화 시도
      if (_connectivityService.isOnline) {
        await syncWithSupabase();
      }

      // 연결 상태 변화 리스닝
      _connectivitySubscription = _connectivityService.onConnectivityChanged.listen((isOnline) {
        if (isOnline) {
          syncWithSupabase();
        }
      });
    } catch (e) {
      debugPrint('Error initializing FavoriteService: $e');
    }
  }

  /// 즐겨찾기 여부 확인
  bool isFavorite(String type, int targetId) {
    final key = '${type}_$targetId';
    return _favoriteCache[key] ?? false;
  }

  /// 특정 타입의 즐겨찾기 ID 목록 조회
  List<int> getFavoriteIds(String type) {
    final result = <int>[];
    for (final entry in _favoriteCache.entries) {
      if (entry.key.startsWith('${type}_') && entry.value) {
        final targetId = int.parse(entry.key.split('_')[1]);
        result.add(targetId);
      }
    }
    return result;
  }

  /// 즐겨찾기 토글 (비동기 서버 저장)
  Future<void> toggleFavorite({
    required String type,
    required int targetId,
    String? note,
  }) async {
    final userId = _supabaseService.currentUser?.id;
    if (userId == null) {
      debugPrint('FavoriteService: No user logged in');
      return;
    }

    final key = '${type}_$targetId';
    final currentlyFavorited = _favoriteCache[key] ?? false;

    if (currentlyFavorited) {
      // 즐겨찾기 해제 - 데이터 삭제
      await _removeFavorite(userId, type, targetId, key);
    } else {
      // 즐겨찾기 추가
      await _addFavorite(userId, type, targetId, key, note);
    }

    // 리스너에게 알림
    notifyListeners();
  }

  /// 즐겨찾기 추가 (내부 메서드)
  Future<void> _addFavorite(
    String userId,
    String type,
    int targetId,
    String key,
    String? note,
  ) async {
    try {
      final now = DateTime.now();
      final isOnline = _connectivityService.isOnline;

      // 1. 캐시 즉시 업데이트 (지연 없이 사용)
      _favoriteCache[key] = true;

      // 2. 로컬 DB에 저장
      final localFavorite = FavoritesTableCompanion.insert(
        userId: userId,
        type: type,
        targetId: targetId,
        note: Value(note),
        isSynced: Value(isOnline),
        createdAt: Value(now),
      );
      await _localDb.database.insertFavorite(localFavorite);

      // 3. 온라인이면 서버에 비동기로 저장 (응답 기다리지 않음)
      if (isOnline) {
        _saveToServerAsync(userId, type, targetId, note, now);
      }

      debugPrint('FavoriteService: Added $type favorite for $targetId');
    } catch (e) {
      debugPrint('Error adding favorite: $e');
      // 에러 발생 시 캐시 롤백
      _favoriteCache.remove(key);
    }
  }

  /// 즐겨찾기 삭제 (내부 메서드)
  Future<void> _removeFavorite(
    String userId,
    String type,
    int targetId,
    String key,
  ) async {
    try {
      final isOnline = _connectivityService.isOnline;

      // 1. 캐시 즉시 업데이트 (지연 없이 사용)
      _favoriteCache.remove(key);

      if (isOnline) {
        // 온라인: 로컬 DB에서 즉시 삭제 + 서버에서 비동기 삭제
        await _localDb.database.deleteFavoriteByTarget(userId, type, targetId);
        _deleteFromServerAsync(userId, type, targetId);
      } else {
        // 오프라인: 삭제 대기 상태로 표시 (온라인 시 동기화)
        final existing = await _localDb.database.getFavorite(userId, type, targetId);
        if (existing != null) {
          await _localDb.database.markFavoriteAsDeleted(existing.id);
        }
      }

      debugPrint('FavoriteService: Removed $type favorite for $targetId');
    } catch (e) {
      debugPrint('Error removing favorite: $e');
      // 에러 발생 시 캐시 롤백
      _favoriteCache[key] = true;
    }
  }

  /// 서버에 비동기로 저장 (응답 기다리지 않음)
  void _saveToServerAsync(
    String userId,
    String type,
    int targetId,
    String? note,
    DateTime createdAt,
  ) {
    _supabaseService.client.from('favorites').upsert({
      'user_id': userId,
      'type': type,
      'target_id': targetId,
      'note': note,
      'created_at': createdAt.toIso8601String(),
    }).then((_) {
      debugPrint('FavoriteService: Server save completed for $type $targetId');
      // 동기화 상태 업데이트
      _markAsSyncedAsync(userId, type, targetId);
    }).catchError((e) {
      debugPrint('Error saving to server: $e');
      // 실패해도 로컬에는 저장되어 있으므로 다음 동기화 시 재시도
    });
  }

  /// 서버에서 비동기로 삭제 (응답 기다리지 않음)
  void _deleteFromServerAsync(String userId, String type, int targetId) {
    _supabaseService.client
        .from('favorites')
        .delete()
        .eq('user_id', userId)
        .eq('type', type)
        .eq('target_id', targetId)
        .then((_) {
      debugPrint('FavoriteService: Server delete completed for $type $targetId');
    }).catchError((e) {
      debugPrint('Error deleting from server: $e');
    });
  }

  /// 동기화 상태 업데이트 (비동기)
  void _markAsSyncedAsync(String userId, String type, int targetId) {
    _localDb.database.getFavorite(userId, type, targetId).then((favorite) {
      if (favorite != null) {
        _localDb.database.markFavoriteAsSynced(favorite.id);
      }
    }).catchError((e) {
      debugPrint('Error marking as synced: $e');
    });
  }

  /// Supabase와 동기화
  Future<void> syncWithSupabase() async {
    if (!_connectivityService.isOnline) return;

    final userId = _supabaseService.currentUser?.id;
    if (userId == null) return;

    try {
      debugPrint('FavoriteService: Starting sync with Supabase...');

      // 1. 삭제 대기 중인 항목을 서버에서 삭제
      final deletedFavorites = await _localDb.database.getDeletedFavorites();
      for (final favorite in deletedFavorites) {
        try {
          await _supabaseService.client
              .from('favorites')
              .delete()
              .eq('user_id', favorite.userId)
              .eq('type', favorite.type)
              .eq('target_id', favorite.targetId);
          // 로컬에서 완전 삭제
          await _localDb.database.deleteFavorite(favorite.id);
        } catch (e) {
          debugPrint('Error syncing delete for ${favorite.id}: $e');
        }
      }

      // 2. 미동기화 즐겨찾기를 서버에 업로드
      final unsyncedFavorites = await _localDb.database.getUnsyncedFavorites();
      for (final favorite in unsyncedFavorites) {
        if (favorite.isDeleted) continue; // 삭제 대기 항목은 위에서 처리
        try {
          await _supabaseService.client.from('favorites').upsert({
            'user_id': favorite.userId,
            'type': favorite.type,
            'target_id': favorite.targetId,
            'note': favorite.note,
            'created_at': favorite.createdAt.toIso8601String(),
          });
          await _localDb.database.markFavoriteAsSynced(favorite.id);
        } catch (e) {
          debugPrint('Error syncing favorite ${favorite.id}: $e');
        }
      }

      // 3. 서버에서 최신 데이터 다운로드
      final serverFavorites = await _supabaseService.client
          .from('favorites')
          .select()
          .eq('user_id', userId);

      // 4. 캐시 갱신 (서버 데이터 기준)
      _favoriteCache.clear();

      for (final record in serverFavorites) {
        final type = record['type'] as String;
        final targetId = record['target_id'] as int;
        final key = '${type}_$targetId';
        _favoriteCache[key] = true;
      }

      notifyListeners();
      debugPrint('FavoriteService: Sync completed, ${_favoriteCache.length} favorites in cache');
    } catch (e) {
      debugPrint('Error syncing with Supabase: $e');
    }
  }

  /// 캐시 강제 갱신 (Supabase에서 다시 로드)
  Future<void> refreshFromSupabase() async {
    if (!_connectivityService.isOnline) return;

    final userId = _supabaseService.currentUser?.id;
    if (userId == null) return;

    try {
      final serverFavorites = await _supabaseService.client
          .from('favorites')
          .select()
          .eq('user_id', userId);

      _favoriteCache.clear();

      for (final record in serverFavorites) {
        final type = record['type'] as String;
        final targetId = record['target_id'] as int;
        final key = '${type}_$targetId';
        _favoriteCache[key] = true;
      }

      notifyListeners();
      debugPrint('FavoriteService: Refreshed from Supabase, ${_favoriteCache.length} favorites');
    } catch (e) {
      debugPrint('Error refreshing from Supabase: $e');
    }
  }

  @override
  void dispose() {
    _connectivitySubscription?.cancel();
    super.dispose();
  }
}
