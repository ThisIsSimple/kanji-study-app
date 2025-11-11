import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';

/// 네트워크 연결 상태를 감지하고 관리하는 싱글톤 서비스
class ConnectivityService {
  static final ConnectivityService _instance = ConnectivityService._internal();
  static ConnectivityService get instance => _instance;

  ConnectivityService._internal();

  final Connectivity _connectivity = Connectivity();
  final StreamController<bool> _connectivityController =
      StreamController<bool>.broadcast();

  bool _isOnline = true;
  StreamSubscription<List<ConnectivityResult>>? _subscription;

  /// 현재 온라인 상태
  bool get isOnline => _isOnline;

  /// 연결 상태 변경 스트림
  Stream<bool> get onConnectivityChanged => _connectivityController.stream;

  /// 서비스 초기화
  Future<void> initialize() async {
    // 현재 연결 상태 확인
    await _updateConnectionStatus(await _connectivity.checkConnectivity());

    // 연결 상태 변경 감지
    _subscription = _connectivity.onConnectivityChanged.listen(
      _updateConnectionStatus,
      onError: (error) {
        print('Connectivity error: $error');
        _updateOnlineStatus(false);
      },
    );
  }

  /// 연결 상태 업데이트
  Future<void> _updateConnectionStatus(List<ConnectivityResult> results) async {
    // none이 아니면 온라인으로 간주
    final bool hasConnection = results.isNotEmpty &&
        !results.every((result) => result == ConnectivityResult.none);

    _updateOnlineStatus(hasConnection);
  }

  /// 온라인 상태 업데이트 및 스트림 발행
  void _updateOnlineStatus(bool isOnline) {
    if (_isOnline != isOnline) {
      _isOnline = isOnline;
      _connectivityController.add(_isOnline);
      print('Connectivity changed: ${_isOnline ? "Online" : "Offline"}');
    }
  }

  /// 서비스 종료
  void dispose() {
    _subscription?.cancel();
    _connectivityController.close();
  }
}
