import 'dart:async';

import 'package:flutter/foundation.dart';

import 'connectivity_service.dart';

class ConnectivitySyncHelper {
  ConnectivitySyncHelper({
    required this.label,
    required this.onReconnect,
    ConnectivityService? connectivityService,
  }) : _connectivityService =
           connectivityService ?? ConnectivityService.instance;

  final String label;
  final Future<void> Function() onReconnect;
  final ConnectivityService _connectivityService;

  StreamSubscription<bool>? _subscription;
  bool _isSyncing = false;

  bool get isSyncing => _isSyncing;

  void listen() {
    _subscription?.cancel();
    _subscription = _connectivityService.onConnectivityChanged.listen((
      isOnline,
    ) {
      if (isOnline) {
        unawaited(onReconnect());
      }
    });
  }

  Future<void> runGuarded(Future<void> Function() action) async {
    if (!_connectivityService.isOnline || _isSyncing) return;

    _isSyncing = true;
    try {
      await action();
    } catch (error, stackTrace) {
      debugPrint('$label sync failed: $error');
      debugPrintStack(stackTrace: stackTrace);
      rethrow;
    } finally {
      _isSyncing = false;
    }
  }

  void dispose() {
    _subscription?.cancel();
  }
}
