import 'dart:async';
import 'dart:math';
import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import '../database/app_database.dart';
import '../models/study_progress.dart';
import '../models/study_record_model.dart';
import 'local_database_service.dart';
import 'supabase_service.dart';
import 'connectivity_service.dart';
import 'connectivity_sync_helper.dart';

/// 학습 기록 전역 상태 관리 서비스 (싱글톤)
/// 오프라인 지원 + Supabase 동기화
class StudyRecordService extends ChangeNotifier {
  static final StudyRecordService _instance = StudyRecordService._internal();
  static StudyRecordService get instance => _instance;

  StudyRecordService._internal();

  final LocalDatabaseService _localDb = LocalDatabaseService.instance;
  final SupabaseService _supabaseService = SupabaseService.instance;
  final ConnectivityService _connectivityService = ConnectivityService.instance;
  late final ConnectivitySyncHelper _syncHelper = ConnectivitySyncHelper(
    label: 'StudyRecordService',
    onReconnect: syncWithSupabase,
    connectivityService: _connectivityService,
  );

  final Map<String, StudyItemProgress> _progressCache = {};

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

      final records = await _getLocalRecords(userId);
      _replaceCache(records);

      _isInitialized = true;
      debugPrint(
        'StudyRecordService initialized with ${_progressCache.length} tracked items',
      );

      _syncHelper.listen();
      await syncWithSupabase();
    } catch (e) {
      debugPrint('Error initializing StudyRecordService: $e');
    }
  }

  /// 학습 기록 추가 (로컬 + 온라인)
  Future<void> addRecord({
    required StudyType type,
    required int targetId,
    required StudyStatus status,
  }) async {
    final userId = _supabaseService.currentUser?.id;
    if (userId == null) {
      throw StateError('StudyRecordService: No user logged in');
    }

    try {
      final now = DateTime.now().toUtc();
      final isOnline = _connectivityService.isOnline;
      final recordClientId = _createRecordClientId();

      // 1. 로컬 DB에 저장
      final localRecord = StudyRecordsTableCompanion.insert(
        userId: userId,
        studyType: type.value,
        targetId: targetId,
        status: status.value,
        studyDate: now,
        recordClientId: Value(recordClientId),
        isSynced: const Value(false),
        createdAt: Value(now),
      );
      final localRecordId = await _localDb.database.insertStudyRecord(
        localRecord,
      );

      // 2. 메모리 캐시 업데이트
      final record = StudyRecord(
        userId: userId,
        type: type,
        targetId: targetId,
        status: status,
        recordClientId: recordClientId,
        createdAt: now.toLocal(),
      );
      _upsertProgress(record);

      // 3. 온라인이면 Supabase에도 저장 (created_at은 DB default now() 사용)
      if (isOnline && _supabaseService.isInitialized) {
        try {
          await _upsertStudyRecordToServer(
            userId: userId,
            type: type.value,
            targetId: targetId,
            status: status.value,
            createdAt: now,
            recordClientId: recordClientId,
          );
          await _localDb.database.markRecordAsSynced(localRecordId);
        } catch (e) {
          debugPrint('StudyRecordService: remote insert failed: $e');
        }
      }

      // 4. 리스너에게 알림
      notifyListeners();

      debugPrint(
        'StudyRecordService: Added ${type.value} record for $targetId (${status.value})',
      );
    } catch (e) {
      debugPrint('Error adding study record: $e');
      rethrow;
    }
  }

  /// 특정 항목의 학습 상태 조회
  StudyStatus? getStatus(StudyType type, int targetId) {
    return getItemProgress(type, targetId)?.lastStatus;
  }

  StudyItemProgress? getItemProgress(StudyType type, int targetId) {
    return _progressCache['${type.value}_$targetId'];
  }

  Map<int, StudyItemProgress> getProgressByType(StudyType type) {
    final result = <int, StudyItemProgress>{};
    for (final entry in _progressCache.entries) {
      if (entry.value.type == type) {
        result[entry.value.targetId] = entry.value;
      }
    }
    return result;
  }

  StudyProgressSummary getSummary(StudyType type) {
    return buildProgressSummary(type, _progressCache.values);
  }

  /// Supabase와 동기화
  Future<void> syncWithSupabase() async {
    final userId = _supabaseService.currentUser?.id;
    if (userId == null) return;
    if (!_supabaseService.isInitialized) return;

    try {
      await _syncHelper.runGuarded(() async {
        debugPrint('StudyRecordService: Starting sync with Supabase...');

        final unsyncedRecords = await _localDb.database.getUnsyncedRecords();
        for (final record in unsyncedRecords) {
          try {
            final recordClientId = await _ensureRecordClientId(record);
            await _upsertStudyRecordToServer(
              userId: record.userId,
              type: record.studyType,
              targetId: record.targetId,
              status: record.status,
              createdAt: record.createdAt,
              recordClientId: recordClientId,
            );
            await _localDb.database.markRecordAsSynced(record.id);
          } catch (e) {
            debugPrint('Error syncing record ${record.id}: $e');
          }
        }

        final localRecords = await _getLocalRecords(userId);
        final serverRecords = await _supabaseService.getStudyRecords();
        _replaceCache(_mergeStudyRecords(localRecords, serverRecords));
        notifyListeners();
        debugPrint(
          'StudyRecordService: Sync completed, ${_progressCache.length} tracked items',
        );
      });
    } catch (e) {
      debugPrint('Error syncing with Supabase: $e');
    }
  }

  /// 캐시 강제 갱신 (Supabase에서 다시 로드)
  Future<void> refreshFromSupabase() async {
    try {
      if (!_supabaseService.isInitialized) return;
      final userId = _supabaseService.currentUser?.id;
      if (userId == null) return;
      final localRecords = await _getLocalRecords(userId);
      final serverRecords = await _supabaseService.getStudyRecords();
      _replaceCache(_mergeStudyRecords(localRecords, serverRecords));
      notifyListeners();
      debugPrint(
        'StudyRecordService: Refreshed from Supabase, ${_progressCache.length} tracked items',
      );
    } catch (e) {
      debugPrint('Error refreshing from Supabase: $e');
    }
  }

  Future<List<StudyRecord>> getStudyRecords({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final userId = _supabaseService.currentUser?.id;
    if (userId == null) return [];

    final localRecords = filterRecordsByDateRange(
      await _getLocalRecords(userId),
      startDate: startDate,
      endDate: endDate,
    );

    if (!_connectivityService.isOnline || !_supabaseService.isInitialized) {
      return localRecords;
    }

    final serverRecords = await _supabaseService.getStudyRecords(
      startDate: startDate,
      endDate: endDate,
    );
    return _mergeStudyRecords(localRecords, serverRecords);
  }

  @visibleForTesting
  static List<StudyRecord> filterRecordsByDateRange(
    Iterable<StudyRecord> records, {
    DateTime? startDate,
    DateTime? endDate,
  }) {
    return records.where((record) {
      final createdAt = record.createdAt;
      if (createdAt == null) return false;
      if (startDate != null && createdAt.isBefore(startDate)) return false;
      if (endDate != null && createdAt.isAfter(endDate)) return false;
      return true;
    }).toList();
  }

  Future<List<StudyRecord>> _getLocalRecords(String userId) async {
    final rows = await _localDb.database.getStudyRecords(userId);
    return rows
        .map(
          (row) => StudyRecord(
            id: row.id,
            userId: row.userId,
            type: StudyType.fromString(row.studyType),
            targetId: row.targetId,
            status: StudyStatus.fromString(row.status),
            notes: row.notes,
            recordClientId: row.recordClientId,
            createdAt: row.createdAt.toLocal(),
          ),
        )
        .toList();
  }

  void _replaceCache(List<StudyRecord> records) {
    _progressCache
      ..clear()
      ..addAll(buildProgressIndex(records));
  }

  static List<StudyRecord> _mergeStudyRecords(
    Iterable<StudyRecord> localRecords,
    Iterable<StudyRecord> serverRecords,
  ) {
    final merged = <StudyRecord>[];
    final seen = <String>{};

    for (final record in [...localRecords, ...serverRecords]) {
      final key = _recordMergeKey(record);
      if (seen.add(key)) {
        merged.add(record);
      }
    }

    merged.sort((left, right) {
      final leftTime = left.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      final rightTime =
          right.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      return rightTime.compareTo(leftTime);
    });
    return merged;
  }

  @visibleForTesting
  static List<StudyRecord> mergeStudyRecordsForTest(
    Iterable<StudyRecord> localRecords,
    Iterable<StudyRecord> serverRecords,
  ) => _mergeStudyRecords(localRecords, serverRecords);

  @visibleForTesting
  static String recordMergeKeyForTest(StudyRecord record) =>
      _recordMergeKey(record);

  static String _recordMergeKey(StudyRecord record) {
    final recordClientId = record.recordClientId;
    if (recordClientId != null && recordClientId.isNotEmpty) {
      return '${record.userId ?? ''}|$recordClientId';
    }

    final timestamp = record.createdAt?.toUtc().toIso8601String() ?? 'no-time';
    return [
      record.userId ?? '',
      record.type.value,
      record.targetId,
      record.status.value,
      timestamp,
    ].join('|');
  }

  Future<String> _ensureRecordClientId(StudyRecordsTableData record) async {
    var createdNewId = false;
    final recordClientId = _recordClientIdForSync(
      record.recordClientId,
      createRecordClientId: () {
        createdNewId = true;
        return _createRecordClientId();
      },
    );

    if (createdNewId) {
      await _localDb.database.updateStudyRecordClientId(
        record.id,
        recordClientId,
      );
    }
    return recordClientId;
  }

  @visibleForTesting
  Future<String> ensureRecordClientIdForTest(StudyRecordsTableData record) =>
      _ensureRecordClientId(record);

  @visibleForTesting
  static String? existingRecordClientIdOrNullForTest(String? recordClientId) =>
      _existingRecordClientIdOrNull(recordClientId);

  @visibleForTesting
  static String recordClientIdForSyncForTest(
    String? recordClientId, {
    required String Function() createRecordClientId,
  }) => _recordClientIdForSync(
    recordClientId,
    createRecordClientId: createRecordClientId,
  );

  static String _recordClientIdForSync(
    String? recordClientId, {
    required String Function() createRecordClientId,
  }) {
    return _existingRecordClientIdOrNull(recordClientId) ??
        createRecordClientId();
  }

  static String? _existingRecordClientIdOrNull(String? recordClientId) {
    if (recordClientId == null || recordClientId.isEmpty) return null;
    return recordClientId;
  }

  Future<void> _upsertStudyRecordToServer({
    required String userId,
    required String type,
    required int targetId,
    required String status,
    required DateTime createdAt,
    required String recordClientId,
  }) async {
    await _supabaseService.client.from('study_records').upsert({
      'user_id': userId,
      'type': type,
      'target_id': targetId,
      'status': status,
      'created_at': createdAt.toUtc().toIso8601String(),
      'record_client_id': recordClientId,
    }, onConflict: 'user_id,record_client_id');
  }

  static String _createRecordClientId() {
    final random = Random.secure();
    final bytes = List<int>.generate(16, (_) => random.nextInt(256));
    final hex = bytes.map((byte) => byte.toRadixString(16).padLeft(2, '0'));
    return 'study-record-${DateTime.now().microsecondsSinceEpoch}-${hex.join()}';
  }

  void _upsertProgress(StudyRecord record) {
    final key = '${record.type.value}_${record.targetId}';
    final current =
        _progressCache[key] ??
        StudyItemProgress.empty(record.type, record.targetId);
    _progressCache[key] = current.copyWithRecord(record);
  }

  @override
  void dispose() {
    _syncHelper.dispose();
    super.dispose();
  }
}
