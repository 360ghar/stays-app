import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:upgrader/upgrader.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:stays_app/app/utils/logger/app_logger.dart';
import 'package:stays_app/config/app_config.dart';

/// Status of the update check process
enum UpdateStatus {
  unknown,
  checking,
  available,
  notAvailable,
  error,
}

/// Service for checking app updates using the upgrader package.
///
/// Supports both forced updates (critical) and optional updates (dismissible).
/// Uses GetStorage for persisting "remind me later" preferences.
class AppUpdateService extends GetxService {
  static const String _boxName = 'app_update_prefs';
  static const String _lastDismissedKey = 'last_dismissed_at';
  static const String _dismissedVersionKey = 'dismissed_version';
  static const Duration _cooldownDuration = Duration(hours: 24);
  static const Duration _checkTimeout = Duration(seconds: 10);

  late final GetStorage _storage;
  late final Upgrader _upgrader;

  String _currentVersion = '';
  String _currentBuildNumber = '';

  // Observable state
  final Rx<UpdateStatus> status = UpdateStatus.unknown.obs;
  final RxBool isUpdateAvailable = false.obs;
  final RxBool isForceUpdate = false.obs;
  final RxString storeVersion = ''.obs;
  final RxString releaseNotes = ''.obs;
  final RxString minAppVersion = ''.obs;

  /// Current app version
  String get currentVersion => _currentVersion;

  /// Current build number
  String get currentBuildNumber => _currentBuildNumber;

  /// Full version string (version+buildNumber)
  String get fullVersion => '$_currentVersion+$_currentBuildNumber';

  /// Initialize the service
  Future<AppUpdateService> init() async {
    try {
      // Initialize storage
      await GetStorage.init(_boxName);
      _storage = GetStorage(_boxName);

      // Get current app version
      final packageInfo = await PackageInfo.fromPlatform();
      _currentVersion = packageInfo.version;
      _currentBuildNumber = packageInfo.buildNumber;

      // Initialize upgrader with debug logging in dev mode
      _upgrader = Upgrader(
        debugLogging: AppConfig.isDev,
        durationUntilAlertAgain: _cooldownDuration,
      );

      AppLogger.info(
        'AppUpdateService initialized. Current version: $fullVersion',
      );

      return this;
    } catch (e, stack) {
      AppLogger.error('Failed to initialize AppUpdateService', e, stack);
      rethrow;
    }
  }

  /// Check for available updates
  ///
  /// Returns true if an update is available, false otherwise.
  /// Sets [isForceUpdate] to true if the update is critical.
  Future<bool> checkForUpdate() async {
    // Skip on web platform
    if (kIsWeb) {
      AppLogger.info('Web platform - skipping update check');
      status.value = UpdateStatus.notAvailable;
      return false;
    }

    status.value = UpdateStatus.checking;
    AppLogger.info('Checking for app updates...');

    try {
      // Initialize upgrader and check for updates with timeout
      await _upgrader.initialize().timeout(_checkTimeout);

      final state = _upgrader.state;
      final appStoreVersion = state.versionInfo?.appStoreVersion;
      final updateAvailable = appStoreVersion != null &&
          _isNewerVersion(
            appStoreVersion.toString(),
            _currentVersion,
          );

      if (updateAvailable) {
        status.value = UpdateStatus.available;
        isUpdateAvailable.value = true;
        storeVersion.value = appStoreVersion.toString();
        releaseNotes.value = state.versionInfo?.releaseNotes ?? '';
        minAppVersion.value = state.versionInfo?.minAppVersion?.toString() ?? '';

        // Check if this is a force update
        isForceUpdate.value = _checkIsForceUpdate();

        AppLogger.info(
          'Update available: ${storeVersion.value} '
          '(force: ${isForceUpdate.value})',
        );
        return true;
      } else {
        status.value = UpdateStatus.notAvailable;
        isUpdateAvailable.value = false;
        AppLogger.info('No update available');
        return false;
      }
    } on TimeoutException {
      AppLogger.warning('Update check timed out');
      status.value = UpdateStatus.error;
      return false;
    } catch (e, stack) {
      AppLogger.error('Update check failed', e, stack);
      status.value = UpdateStatus.error;
      return false;
    }
  }

  /// Check if the update prompt should be shown based on cooldown
  bool shouldShowUpdatePrompt() {
    if (!isUpdateAvailable.value) return false;

    // Force updates always show
    if (isForceUpdate.value) return true;

    final lastDismissed = _storage.read<int>(_lastDismissedKey);
    final dismissedVersion = _storage.read<String>(_dismissedVersionKey);

    // If never dismissed, show the prompt
    if (lastDismissed == null) return true;

    // If a new version is available (different from dismissed), show prompt
    if (dismissedVersion != storeVersion.value) return true;

    // Check if cooldown period has passed
    final dismissedTime = DateTime.fromMillisecondsSinceEpoch(lastDismissed);
    final elapsed = DateTime.now().difference(dismissedTime);

    return elapsed > _cooldownDuration;
  }

  /// Record that the user dismissed the update prompt
  Future<void> recordDismissal() async {
    await _storage.write(
      _lastDismissedKey,
      DateTime.now().millisecondsSinceEpoch,
    );
    await _storage.write(_dismissedVersionKey, storeVersion.value);
    AppLogger.info('Update prompt dismissed for version: ${storeVersion.value}');
  }

  /// Get the store URL for the current platform
  String? getStoreUrl() {
    final state = _upgrader.state;
    return state.versionInfo?.appStoreListingURL;
  }

  /// Open the app store page
  Future<bool> openStore() async {
    final url = getStoreUrl();
    if (url == null || url.isEmpty) {
      AppLogger.warning('No store URL available');
      return false;
    }

    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        return true;
      } else {
        AppLogger.warning('Cannot launch store URL: $url');
        return false;
      }
    } catch (e) {
      AppLogger.error('Failed to open store URL', e);
      return false;
    }
  }

  /// Check if this update is forced (critical)
  bool _checkIsForceUpdate() {
    final minVersion = minAppVersion.value;
    if (minVersion.isEmpty) return false;

    // Compare current version against minimum required version
    return _isNewerVersion(minVersion, _currentVersion);
  }

  /// Compare two semantic version strings
  ///
  /// Returns true if [version1] is newer than [version2]
  bool _isNewerVersion(String version1, String version2) {
    try {
      final v1Parts = version1.split('.').map((e) => int.tryParse(e) ?? 0).toList();
      final v2Parts = version2.split('.').map((e) => int.tryParse(e) ?? 0).toList();

      // Pad with zeros if needed
      while (v1Parts.length < 3) {
        v1Parts.add(0);
      }
      while (v2Parts.length < 3) {
        v2Parts.add(0);
      }

      // Compare major, minor, patch
      for (int i = 0; i < 3; i++) {
        if (v1Parts[i] > v2Parts[i]) return true;
        if (v1Parts[i] < v2Parts[i]) return false;
      }

      return false; // Versions are equal
    } catch (e) {
      AppLogger.warning('Version comparison failed: $version1 vs $version2');
      return false;
    }
  }

  /// Clear all stored preferences (for testing)
  Future<void> clearPreferences() async {
    await _storage.remove(_lastDismissedKey);
    await _storage.remove(_dismissedVersionKey);
  }
}
