import 'dart:async';
import 'dart:math';

import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../database/app_database.dart';
import '../models/favorite_crdt_state.dart';
import 'connectivity_service.dart';
import 'connectivity_sync_helper.dart';
import 'local_database_service.dart';
import 'supabase_service.dart';

abstract class FavoriteRemoteStore {
  Future<List<FavoriteCrdtState>> fetchFavorites(String userId);
  Future<void> upsertFavorite(FavoriteCrdtState state);
}

class SupabaseFavoriteRemoteStore implements FavoriteRemoteStore {
  SupabaseFavoriteRemoteStore(this._supabaseService);

  final SupabaseService _supabaseService;

  @override
  Future<List<FavoriteCrdtState>> fetchFavorites(String userId) async {
    final response = await _supabaseService.client
        .from('favorites')
        .select()
        .eq('user_id', userId);

    return (response as List)
        .map((record) => _stateFromServerRecord(record as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<void> upsertFavorite(FavoriteCrdtState state) async {
    await _supabaseService.client.from('favorites').upsert({
      'user_id': state.userId,
      'type': state.type,
      'target_id': state.targetId,
      'note': state.note,
      'is_favorite': state.isFavorite,
      'operation_timestamp': state.operationTimestamp.toUtc().toIso8601String(),
      'operation_id': state.operationId,
      'device_id': state.deviceId,
      'created_at': (state.createdAt ?? state.operationTimestamp)
          .toUtc()
          .toIso8601String(),
    }, onConflict: 'user_id,type,target_id');
  }

  FavoriteCrdtState _stateFromServerRecord(Map<String, dynamic> record) {
    final createdAt = _parseDateTime(record['created_at']);
    return FavoriteCrdtState(
      userId: record['user_id'] as String,
      type: record['type'] as String,
      targetId: (record['target_id'] as num).toInt(),
      note: record['note'] as String?,
      isFavorite: record['is_favorite'] as bool? ?? true,
      operationTimestamp:
          _parseDateTime(record['operation_timestamp']) ??
          createdAt ??
          DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      operationId:
          record['operation_id'] as String? ??
          'legacy-${record['id']?.toString() ?? 'unknown'}',
      deviceId: record['device_id'] as String? ?? 'legacy',
      createdAt: createdAt,
    );
  }

  DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }
}

/// 즐겨찾기 전역 상태 관리 서비스 (싱글톤)
/// 오프라인 작업을 LWW CRDT 상태로 저장하고 Supabase와 병합한다.
class FavoriteService extends ChangeNotifier {
  static final FavoriteService _instance = FavoriteService._internal();
  static FavoriteService get instance => _instance;

  FavoriteService._internal()
    : _remoteStore = SupabaseFavoriteRemoteStore(SupabaseService.instance);

  static const _deviceIdPreferenceKey = 'favorite_crdt_device_id';

  final LocalDatabaseService _localDb = LocalDatabaseService.instance;
  final SupabaseService _supabaseService = SupabaseService.instance;
  final ConnectivityService _connectivityService = ConnectivityService.instance;
  final FavoriteRemoteStore _remoteStore;
  late final ConnectivitySyncHelper _syncHelper = ConnectivitySyncHelper(
    label: 'FavoriteService',
    onReconnect: syncWithSupabase,
    connectivityService: _connectivityService,
  );

  // 메모리 캐시: "type_targetId" -> isFavorite
  final Map<String, bool> _favoriteCache = {};

  String? _deviceId;
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

      await _loadLocalFavoritesIntoCache(userId);

      _isInitialized = true;
      debugPrint(
        'FavoriteService initialized with ${_favoriteCache.length} favorites',
      );

      _syncHelper.listen();
      await syncWithSupabase();
    } catch (e) {
      debugPrint('Error initializing FavoriteService: $e');
    }
  }

  /// 즐겨찾기 여부 확인
  bool isFavorite(String type, int targetId) {
    final key = _cacheKey(type, targetId);
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

  /// 즐겨찾기 토글. 로컬 상태를 즉시 갱신하고 서버 동기화는 별도로 재시도한다.
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

    final key = _cacheKey(type, targetId);
    final nextIsFavorite = !(_favoriteCache[key] ?? false);

    final operationTimestamp = DateTime.now().toUtc();
    final state = FavoriteCrdtState(
      userId: userId,
      type: type,
      targetId: targetId,
      note: note,
      isFavorite: nextIsFavorite,
      operationTimestamp: operationTimestamp,
      operationId: _createOperationId(operationTimestamp),
      deviceId: await _getDeviceId(),
      createdAt: operationTimestamp,
    );

    try {
      _applyStateToCache(state);
      await _upsertLocalState(state, isSynced: false);
      notifyListeners();

      if (_connectivityService.isOnline && _supabaseService.isInitialized) {
        unawaited(syncWithSupabase());
      }

      debugPrint(
        'FavoriteService: ${nextIsFavorite ? 'Added' : 'Removed'} '
        '$type favorite for $targetId',
      );
    } catch (e) {
      debugPrint('Error toggling favorite: $e');
      if (nextIsFavorite) {
        _favoriteCache.remove(key);
      } else {
        _favoriteCache[key] = true;
      }
      rethrow;
    }
  }

  /// Supabase와 동기화
  Future<void> syncWithSupabase() async {
    final userId = _supabaseService.currentUser?.id;
    if (userId == null) return;
    if (!_supabaseService.isInitialized) return;

    try {
      await _syncHelper.runGuarded(() async {
        debugPrint('FavoriteService: Starting CRDT sync with Supabase...');

        final localStates = await _localDb.database.getFavoriteStates(userId);
        final serverStates = await _remoteStore.fetchFavorites(userId);
        final localByKey = {
          for (final favorite in localStates) _dbKey(favorite): favorite,
        };
        final serverByKey = {
          for (final favorite in serverStates) favorite.key: favorite,
        };
        final allKeys = {...localByKey.keys, ...serverByKey.keys};

        for (final key in allKeys) {
          final local = localByKey[key];
          final server = serverByKey[key];
          final localState = local == null
              ? null
              : _stateFromLocalRecord(local);
          final latest = localState == null
              ? server!
              : server == null
              ? localState
              : mergeFavoriteStates(localState, server);

          final shouldUpdateServer =
              server == null || latest.isNewerThan(server);
          var synced = true;
          if (shouldUpdateServer) {
            try {
              await _remoteStore.upsertFavorite(latest);
            } catch (e) {
              synced = false;
              debugPrint('Error syncing favorite $key: $e');
            }
          }

          await _upsertLocalState(latest, isSynced: synced);
        }

        await _loadLocalFavoritesIntoCache(userId);
        notifyListeners();
        debugPrint(
          'FavoriteService: Sync completed, ${_favoriteCache.length} favorites in cache',
        );
      });
    } catch (e) {
      debugPrint('Error syncing with Supabase: $e');
    }
  }

  /// 캐시 강제 갱신. pending 로컬 작업을 잃지 않도록 일반 CRDT 동기화를 수행한다.
  Future<void> refreshFromSupabase() => syncWithSupabase();

  Future<void> _loadLocalFavoritesIntoCache(String userId) async {
    final favorites = await _localDb.database.getFavorites(userId);
    _favoriteCache.clear();
    for (final favorite in favorites) {
      _favoriteCache[_cacheKey(favorite.type, favorite.targetId)] = true;
    }
  }

  Future<void> _upsertLocalState(
    FavoriteCrdtState state, {
    required bool isSynced,
  }) {
    return _localDb.database.upsertFavoriteState(
      FavoritesTableCompanion.insert(
        userId: state.userId,
        type: state.type,
        targetId: state.targetId,
        note: Value(state.note),
        isSynced: Value(isSynced),
        isDeleted: Value(!state.isFavorite),
        operationTimestamp: Value(state.operationTimestamp.toLocal()),
        operationId: Value(state.operationId),
        deviceId: Value(state.deviceId),
        createdAt: Value(
          (state.createdAt ?? state.operationTimestamp).toLocal(),
        ),
      ),
    );
  }

  FavoriteCrdtState _stateFromLocalRecord(FavoritesTableData favorite) {
    return FavoriteCrdtState(
      userId: favorite.userId,
      type: favorite.type,
      targetId: favorite.targetId,
      note: favorite.note,
      isFavorite: !favorite.isDeleted,
      operationTimestamp: favorite.operationTimestamp.toUtc(),
      operationId: favorite.operationId,
      deviceId: favorite.deviceId,
      createdAt: favorite.createdAt.toUtc(),
    );
  }

  void _applyStateToCache(FavoriteCrdtState state) {
    final key = _cacheKey(state.type, state.targetId);
    if (state.isFavorite) {
      _favoriteCache[key] = true;
    } else {
      _favoriteCache.remove(key);
    }
  }

  Future<String> _getDeviceId() async {
    if (_deviceId != null) return _deviceId!;

    final prefs = await SharedPreferences.getInstance();
    final existing = prefs.getString(_deviceIdPreferenceKey);
    if (existing != null && existing.isNotEmpty) {
      _deviceId = existing;
      return existing;
    }

    final generated = _createRandomId('device');
    await prefs.setString(_deviceIdPreferenceKey, generated);
    _deviceId = generated;
    return generated;
  }

  String _createOperationId(DateTime timestamp) {
    return '${timestamp.microsecondsSinceEpoch}-${_createRandomId('op')}';
  }

  String _createRandomId(String prefix) {
    final random = Random.secure();
    final bytes = List<int>.generate(16, (_) => random.nextInt(256));
    final hex = bytes.map((byte) => byte.toRadixString(16).padLeft(2, '0'));
    return '$prefix-${DateTime.now().microsecondsSinceEpoch}-${hex.join()}';
  }

  String _cacheKey(String type, int targetId) => '${type}_$targetId';
  String _dbKey(FavoritesTableData favorite) =>
      '${favorite.type}-${favorite.targetId}';

  @override
  void dispose() {
    _syncHelper.dispose();
    super.dispose();
  }
}
