import 'dart:async';
import 'dart:io';

import 'package:get/get.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

import 'package:stays_app/config/app_config.dart';

import '../logger/app_logger.dart';

enum ConnectivityStatus { connected, disconnected, mobile, wifi }

class ConnectivityService extends GetxService {
  static ConnectivityService get I => Get.find<ConnectivityService>();

  final Rx<ConnectivityStatus> status = ConnectivityStatus.disconnected.obs;
  final RxBool isOnline = false.obs;

  StreamSubscription<List<ConnectivityResult>>? _subscription;
  final _connectionChangeController = StreamController<bool>.broadcast();
  Stream<bool> get onConnectionChanged => _connectionChangeController.stream;

  @override
  void onInit() {
    super.onInit();
    unawaited(_initialize());
  }

  @override
  void onClose() {
    if (_subscription != null) {
      unawaited(_subscription!.cancel());
    }
    unawaited(_connectionChangeController.close());
    super.onClose();
  }

  Future<void> _initialize() async {
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
      final result = await Connectivity().checkConnectivity();
      final hasTransport =
          result.contains(ConnectivityResult.wifi) ||
          result.contains(ConnectivityResult.mobile) ||
          result.contains(ConnectivityResult.ethernet);
      if (!hasTransport) {
        return await _hasInternetAccess();
      }
      return await _hasInternetAccess();
    } catch (e) {
      AppLogger.error('Failed to check connection', e);
      return _hasInternetAccess();
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

  Future<bool> _hasInternetAccess() async {
    final apiHost = _resolveApiHost();
    final hosts = <String>{
      if (apiHost.isNotEmpty) apiHost,
      'google.com',
    };

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
      final uri = Uri.parse(AppConfig.I.apiBaseUrl);
      if (uri.host.isNotEmpty) return uri.host;
    } catch (_) {}
    return '';
  }

  int _resolveHealthPort() {
    try {
      final uri = Uri.parse(AppConfig.I.apiBaseUrl);
      if (uri.port > 0) return uri.port;
      return uri.scheme == 'http' ? 80 : 443;
    } catch (_) {
      return 443;
    }
  }

  Future<bool> _canReachHost(String host, int port) async {
    try {
      final result = await InternetAddress.lookup(host)
          .timeout(const Duration(seconds: 3));
      if (result.isNotEmpty && result.first.rawAddress.isNotEmpty) {
        return true;
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
