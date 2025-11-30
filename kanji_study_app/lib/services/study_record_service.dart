import 'dart:async';
import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import '../database/app_database.dart';
import 'local_database_service.dart';
import 'supabase_service.dart';
import 'connectivity_service.dart';

/// 학습 기록 전역 상태 관리 서비스 (싱글톤)
/// 오프라인 지원 + Supabase 동기화
class StudyRecordService extends ChangeNotifier {
  static final StudyRecordService _instance = StudyRecordService._internal();
  static StudyRecordService get instance => _instance;

  StudyRecordService._internal();

  final LocalDatabaseService _localDb = LocalDatabaseService.instance;
  final SupabaseService _supabaseService = SupabaseService.instance;
  final ConnectivityService _connectivityService = ConnectivityService.instance;

  // 메모리 캐시: "type_targetId" -> status
  final Map<String, String> _statusCache = {};

  StreamSubscription<bool>? _connectivitySubscription;

  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  /// 서비스 초기화 - 로컬 DB에서 캐시 로드
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      final userId = _supabaseService.currentUser?.id;
      if (userId == null) {
        debugPrint('StudyRecordService: No user logged in');
        return;
      }

      // 로컬 DB에서 학습 기록 로드
      final records = await _localDb.database.getStudyRecords(userId);

      // 캐시에 로드 (각 targetId별 최신 상태만 유지)
      final Map<String, DateTime> latestDates = {};
      for (final record in records) {
        final key = '${record.studyType}_${record.targetId}';
        final existingDate = latestDates[key];

        if (existingDate == null || record.createdAt.isAfter(existingDate)) {
          _statusCache[key] = record.status;
          latestDates[key] = record.createdAt;
        }
      }

      _isInitialized = true;
      debugPrint('StudyRecordService initialized with ${_statusCache.length} records');

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
      debugPrint('Error initializing StudyRecordService: $e');
    }
  }

  /// 학습 기록 추가 (로컬 + 온라인)
  Future<void> addRecord({
    required String type,
    required int targetId,
    required String status,
  }) async {
    final userId = _supabaseService.currentUser?.id;
    if (userId == null) {
      debugPrint('StudyRecordService: No user logged in');
      return;
    }

    try {
      final now = DateTime.now().toUtc();
      final isOnline = _connectivityService.isOnline;

      // 1. 로컬 DB에 저장
      final localRecord = StudyRecordsTableCompanion.insert(
        userId: userId,
        studyType: type,
        targetId: targetId,
        status: status,
        studyDate: now,
        isSynced: Value(isOnline),
        createdAt: Value(now),
      );
      await _localDb.database.insertStudyRecord(localRecord);

      // 2. 메모리 캐시 업데이트
      final key = '${type}_$targetId';
      _statusCache[key] = status;

      // 3. 온라인이면 Supabase에도 저장 (created_at은 DB default now() 사용)
      if (isOnline) {
        await _supabaseService.client.from('study_records').insert({
          'user_id': userId,
          'type': type,
          'target_id': targetId,
          'status': status,
        });
      }

      // 4. 리스너에게 알림
      notifyListeners();

      debugPrint('StudyRecordService: Added $type record for $targetId ($status)');
    } catch (e) {
      debugPrint('Error adding study record: $e');
    }
  }

  /// 특정 항목의 학습 상태 조회
  String? getStatus(String type, int targetId) {
    final key = '${type}_$targetId';
    return _statusCache[key];
  }

  /// 특정 타입의 모든 학습 상태 조회
  Map<int, String> getStatusesByType(String type) {
    final result = <int, String>{};
    for (final entry in _statusCache.entries) {
      if (entry.key.startsWith('${type}_')) {
        final targetId = int.parse(entry.key.split('_')[1]);
        result[targetId] = entry.value;
      }
    }
    return result;
  }

  /// Supabase와 동기화
  Future<void> syncWithSupabase() async {
    if (!_connectivityService.isOnline) return;

    final userId = _supabaseService.currentUser?.id;
    if (userId == null) return;

    try {
      debugPrint('StudyRecordService: Starting sync with Supabase...');

      // 1. 미동기화 로컬 레코드를 Supabase에 업로드
      final unsyncedRecords = await _localDb.database.getUnsyncedRecords();
      for (final record in unsyncedRecords) {
        try {
          await _supabaseService.client.from('study_records').insert({
            'user_id': record.userId,
            'type': record.studyType,
            'target_id': record.targetId,
            'status': record.status,
            'created_at': record.createdAt.toIso8601String(),
          });
          await _localDb.database.markRecordAsSynced(record.id);
        } catch (e) {
          debugPrint('Error syncing record ${record.id}: $e');
        }
      }

      // 2. Supabase에서 최신 데이터 다운로드
      final serverRecords = await _supabaseService.getStudyRecords();

      // 3. 캐시 갱신 (서버 데이터 기준)
      _statusCache.clear();
      final Map<String, DateTime> latestDates = {};

      for (final record in serverRecords) {
        final key = '${record.type.value}_${record.targetId}';
        final existingDate = latestDates[key];

        if (existingDate == null ||
            (record.createdAt != null && record.createdAt!.isAfter(existingDate))) {
          _statusCache[key] = record.status.value;
          if (record.createdAt != null) {
            latestDates[key] = record.createdAt!;
          }
        }
      }

      notifyListeners();
      debugPrint('StudyRecordService: Sync completed, ${_statusCache.length} records in cache');
    } catch (e) {
      debugPrint('Error syncing with Supabase: $e');
    }
  }

  /// 캐시 강제 갱신 (Supabase에서 다시 로드)
  Future<void> refreshFromSupabase() async {
    if (!_connectivityService.isOnline) return;

    try {
      final serverRecords = await _supabaseService.getStudyRecords();

      _statusCache.clear();
      final Map<String, DateTime> latestDates = {};

      for (final record in serverRecords) {
        final key = '${record.type.value}_${record.targetId}';
        final existingDate = latestDates[key];

        if (existingDate == null ||
            (record.createdAt != null && record.createdAt!.isAfter(existingDate))) {
          _statusCache[key] = record.status.value;
          if (record.createdAt != null) {
            latestDates[key] = record.createdAt!;
          }
        }
      }

      notifyListeners();
      debugPrint('StudyRecordService: Refreshed from Supabase, ${_statusCache.length} records');
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
