import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';

/// Coarse online/offline signal. "Online" means a network interface is up;
/// actual reachability is confirmed by the requests themselves.
abstract class ConnectivityService {
  Stream<bool> get onlineChanges;
  Future<bool> isOnline();
}

class PlatformConnectivityService implements ConnectivityService {
  PlatformConnectivityService([Connectivity? c]) : _c = c ?? Connectivity();

  final Connectivity _c;

  static bool _online(List<ConnectivityResult> r) => r.any((x) => x != ConnectivityResult.none);

  @override
  Stream<bool> get onlineChanges => _c.onConnectivityChanged.map(_online).distinct();

  @override
  Future<bool> isOnline() async => _online(await _c.checkConnectivity());
}

class AlwaysOnlineConnectivity implements ConnectivityService {
  @override
  Stream<bool> get onlineChanges => Stream.value(true);

  @override
  Future<bool> isOnline() async => true;
}
