import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

import 'package:stays_app/config/app_config.dart';

import '../logger/app_logger.dart';

enum ConnectivityStatus { connected, disconnected, mobile, wifi }

class ConnectivityService {
  factory ConnectivityService() => _shared;
  ConnectivityService._internal() {
    unawaited(_initialize());
  }

  // Shared instance so the legacy GetX graph and the Riverpod graph share
  // one connectivity subscription during migration.
  static final ConnectivityService _shared = ConnectivityService._internal();

  static ConnectivityService get I => Get.find<ConnectivityService>();

  final ValueNotifier<ConnectivityStatus> status =
      ValueNotifier<ConnectivityStatus>(ConnectivityStatus.disconnected);
  final ValueNotifier<bool> isOnline = ValueNotifier<bool>(false);

  StreamSubscription<List<ConnectivityResult>>? _subscription;
  final _connectionChangeController = StreamController<bool>.broadcast();
  Stream<bool> get onConnectionChanged => _connectionChangeController.stream;

  /// Call when the owner (DI scope) is disposed.
  void dispose() {
    if (_subscription != null) {
      unawaited(_subscription!.cancel());
    }
    unawaited(_connectionChangeController.close());
    status.dispose();
    isOnline.dispose();
  }

  Future<void> _initialize() async {
    // Optimistic online state: assume connectivity until the first real check
    // resolves, so early requests don't each perform a blocking socket probe.
    isOnline.value = true;
    status.value = ConnectivityStatus.connected;
    try {
      _subscription = Connectivity().onConnectivityChanged.listen(
        _handleConnectivityChange,
      );

      final result = await Connectivity().checkConnectivity();
      _handleConnectivityResult(result);
    } catch (e, stack) {
      AppLogger.error('Failed to initialize connectivity monitoring', e, stack);
    }
  }

  void _handleConnectivityChange(List<ConnectivityResult> results) {
    if (results.isEmpty) return;
    _handleConnectivityResult(results);
  }

  void _handleConnectivityResult(List<ConnectivityResult> results) {
    final hadConnection = isOnline.value;
    final nowConnected =
        results.contains(ConnectivityResult.wifi) ||
        results.contains(ConnectivityResult.mobile) ||
        results.contains(ConnectivityResult.ethernet);

    if (results.contains(ConnectivityResult.wifi)) {
      status.value = ConnectivityStatus.wifi;
    } else if (results.contains(ConnectivityResult.mobile) ||
        results.contains(ConnectivityResult.ethernet)) {
      status.value = ConnectivityStatus.mobile;
    } else if (results.contains(ConnectivityResult.none)) {
      status.value = ConnectivityStatus.disconnected;
    } else {
      status.value = ConnectivityStatus.connected;
    }

    isOnline.value = nowConnected;

    if (hadConnection != nowConnected) {
      _connectionChangeController.add(nowConnected);
      AppLogger.info(
        'Connection changed: ${nowConnected ? "Online" : "Offline"}',
        {'previous': hadConnection, 'current': nowConnected},
      );
    }

    // Verify actual internet reachability (transport alone can be wrong).
    unawaited(_confirmInternetAccess(hadConnection: hadConnection));
  }

  Future<bool> checkConnection() async {
    try {
      await Connectivity().checkConnectivity();
      return await _hasInternetAccess();
    } catch (e) {
      AppLogger.error('Failed to check connection', e);
      return await _hasInternetAccess();
    }
  }

  bool get isCurrentlyOnline => isOnline.value;

  bool get isOnWifi => status.value == ConnectivityStatus.wifi;

  bool get isOnMobile => status.value == ConnectivityStatus.mobile;

  Future<void> _confirmInternetAccess({required bool hadConnection}) async {
    final reachable = await _hasInternetAccess();
    if (isOnline.value != reachable) {
      isOnline.value = reachable;
      _connectionChangeController.add(reachable);
      AppLogger.info(
        'Connection verified: ${reachable ? "Online" : "Offline"}',
        {'previous': hadConnection, 'current': reachable},
      );
    }
  }

  /// Memoized probe result with a short TTL so hot paths (per-request
  /// connectivity checks in BaseProvider) don't each open sockets.
  bool? _cachedProbeResult;
  DateTime? _cachedProbeAt;
  static const Duration _probeCacheTtl = Duration(seconds: 5);

  Future<bool> _hasInternetAccess() async {
    final now = DateTime.now();
    final cached = _cachedProbeResult;
    if (cached != null &&
        _cachedProbeAt != null &&
        now.difference(_cachedProbeAt!) < _probeCacheTtl) {
      return cached;
    }
    final result = await _probeInternetAccess();
    _cachedProbeResult = result;
    _cachedProbeAt = DateTime.now();
    return result;
  }

  Future<bool> _probeInternetAccess() async {
    final apiHost = _resolveApiHost();
    final hosts = <String>{if (apiHost.isNotEmpty) apiHost, 'google.com'};

    for (final host in hosts) {
      if (await _canReachHost(
        host,
        host == apiHost ? _resolveHealthPort() : 443,
      )) {
        return true;
      }
    }

    return false;
  }

  String _resolveApiHost() {
    try {
      final uri = Uri.parse(AppConfig.I.api.apiBaseUrl);
      if (uri.host.isNotEmpty) return uri.host;
    } catch (_) {}
    return '';
  }

  int _resolveHealthPort() {
    try {
      final uri = Uri.parse(AppConfig.I.api.apiBaseUrl);
      if (uri.port > 0) return uri.port;
      return uri.scheme == 'http' ? 80 : 443;
    } catch (_) {
      return 443;
    }
  }

  Future<bool> _canReachHost(String host, int port) async {
    try {
      final result = await InternetAddress.lookup(
        host,
      ).timeout(const Duration(seconds: 3));
      if (result.isEmpty || result.first.rawAddress.isEmpty) {
        return false;
      }
    } catch (_) {}
    try {
      final socket = await Socket.connect(
        host,
        port,
        timeout: const Duration(seconds: 3),
      );
      socket.destroy();
      return true;
    } catch (_) {}
    return false;
  }
}
