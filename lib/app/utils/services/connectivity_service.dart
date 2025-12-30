import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:get/get.dart';

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
    _initialize();
  }

  @override
  void onClose() {
    _subscription?.cancel();
    _connectionChangeController.close();
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
  }

  Future<bool> checkConnection() async {
    try {
      final result = await Connectivity().checkConnectivity();
      return result.contains(ConnectivityResult.wifi) ||
          result.contains(ConnectivityResult.mobile) ||
          result.contains(ConnectivityResult.ethernet);
    } catch (e) {
      AppLogger.error('Failed to check connection', e);
      return false;
    }
  }

  bool get isCurrentlyOnline => isOnline.value;

  bool get isOnWifi => status.value == ConnectivityStatus.wifi;

  bool get isOnMobile => status.value == ConnectivityStatus.mobile;
}
