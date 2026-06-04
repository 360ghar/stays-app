import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../utils/logger/app_logger.dart';

/// Service responsible for managing the "Remember Me" functionality.
/// Handles persisting and restoring user sessions across app launches.
class RememberMeService extends GetxService {
  static const String _boxName = 'auth_preferences';
  static const String _rememberMeFlagKey = 'remember_me';
  static const String _accessTokenKey = 'remembered_access_token';
  static const String _refreshTokenKey = 'remembered_refresh_token';

  late final GetStorage _storage;
  final RxBool isEnabled = false.obs;

  /// Initialize the service
  Future<RememberMeService> init() async {
    await GetStorage.init(_boxName);
    _storage = GetStorage(_boxName);
    isEnabled.value = _storage.read<bool>(_rememberMeFlagKey) ?? false;
    AppLogger.info(
      'RememberMeService initialized. Enabled: ${isEnabled.value}',
    );
    return this;
  }

  /// Check if remember-me is enabled
  bool get enabled => isEnabled.value;

  /// Check if we have stored credentials
  bool get hasStoredCredentials {
    final accessToken = _storage.read<String>(_accessTokenKey);
    final refreshToken = _storage.read<String>(_refreshTokenKey);
    return accessToken != null &&
        accessToken.isNotEmpty &&
        refreshToken != null &&
        refreshToken.isNotEmpty;
  }

  /// Get stored access token
  String? get storedAccessToken => _storage.read<String>(_accessTokenKey);

  /// Get stored refresh token
  String? get storedRefreshToken => _storage.read<String>(_refreshTokenKey);

  /// Enable or disable remember-me
  Future<void> setEnabled({required bool value}) async {
    isEnabled.value = value;
    await _storage.write(_rememberMeFlagKey, value);
    if (!value) {
      await clearStoredSession();
    }
  }

  /// Persist the current Supabase session
  Future<void> persistSession({Session? session}) async {
    final activeSession =
        session ?? Supabase.instance.client.auth.currentSession;
    if (activeSession == null) {
      AppLogger.warning('Cannot persist session: no active session');
      return;
    }

    await _storage.write(_rememberMeFlagKey, true);
    await _storage.write(_accessTokenKey, activeSession.accessToken);

    final refreshToken = activeSession.refreshToken;
    if (refreshToken != null && refreshToken.isNotEmpty) {
      await _storage.write(_refreshTokenKey, refreshToken);
    }

    AppLogger.info('Session persisted for remember-me');
  }

  /// Clear stored session credentials
  Future<void> clearStoredSession() async {
    await _storage.remove(_accessTokenKey);
    await _storage.remove(_refreshTokenKey);
    AppLogger.info('Stored session cleared');
  }

  /// Sync remember-me state after login
  Future<void> syncAfterLogin() async {
    if (isEnabled.value) {
      await persistSession();
    } else {
      await _storage.write(_rememberMeFlagKey, false);
      await clearStoredSession();
    }
  }

  /// Handle sign-out by clearing stored session
  Future<void> onSignOut() async {
    await clearStoredSession();
  }
}
