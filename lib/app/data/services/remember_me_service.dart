import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../utils/logger/app_logger.dart';

/// Service responsible for managing the "Remember Me" functionality.
/// Handles persisting and restoring user sessions across app launches.
/// Auth methods recognized by the backend `/auth/last-method` contract.
class AuthMethods {
  static const String google = 'google';
  static const String apple = 'apple';
  static const String emailPassword = 'email_password';
  static const String phonePassword = 'phone_password';
  static const String phoneOtp = 'phone_otp';
  static const String emailOtp = 'email_otp';

  static const Set<String> all = {
    google,
    apple,
    emailPassword,
    phonePassword,
    phoneOtp,
    emailOtp,
  };

  static bool isValid(String? method) => method != null && all.contains(method);
}

class RememberMeService extends GetxService {
  static const String _boxName = 'auth_preferences';
  static const String _rememberMeFlagKey = 'remember_me';
  static const String _accessTokenKey = 'remembered_access_token';
  static const String _refreshTokenKey = 'remembered_refresh_token';
  // Last-used auth method memory (req: remember & pre-select last method).
  static const String _lastMethodKey = 'last_auth_method';
  static const String _lastIdentifierMaskedKey = 'last_identifier_masked';

  late final GetStorage _storage;
  final RxBool isEnabled = false.obs;

  /// Last-used auth method (one of [AuthMethods]); null if none recorded.
  final RxnString lastMethod = RxnString();

  /// Masked last identifier (e.g. `j***@gmail.com`, `+91 98****3210`).
  final RxnString lastIdentifierMasked = RxnString();

  /// Initialize the service
  Future<RememberMeService> init() async {
    await GetStorage.init(_boxName);
    _storage = GetStorage(_boxName);
    isEnabled.value = _storage.read<bool>(_rememberMeFlagKey) ?? false;
    lastMethod.value = _storage.read<String>(_lastMethodKey);
    lastIdentifierMasked.value = _storage.read<String>(
      _lastIdentifierMaskedKey,
    );
    AppLogger.info(
      'RememberMeService initialized. Enabled: ${isEnabled.value}, '
      'lastMethod: ${lastMethod.value}',
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

  // ---------------------------------------------------------------------------
  // Last-used auth method memory
  // ---------------------------------------------------------------------------

  /// Persist the last-used auth method and a masked identifier so the login
  /// screen can pre-select / highlight it on the next visit.
  Future<void> setLastMethod({
    required String method,
    String? identifier,
  }) async {
    if (!AuthMethods.isValid(method)) {
      AppLogger.warning('Ignoring unknown last auth method: $method');
      return;
    }
    lastMethod.value = method;
    await _storage.write(_lastMethodKey, method);

    if (identifier != null && identifier.trim().isNotEmpty) {
      final masked = maskIdentifier(identifier.trim());
      lastIdentifierMasked.value = masked;
      await _storage.write(_lastIdentifierMaskedKey, masked);
    }
    AppLogger.info('Saved last auth method: $method');
  }

  /// Returns the stored last-used auth method (or null).
  String? getLastMethod() =>
      lastMethod.value ?? _storage.read<String>(_lastMethodKey);

  /// Returns the stored masked identifier (or null).
  String? getLastIdentifierMasked() =>
      lastIdentifierMasked.value ??
      _storage.read<String>(_lastIdentifierMaskedKey);

  Future<void> clearLastMethod() async {
    lastMethod.value = null;
    lastIdentifierMasked.value = null;
    await _storage.remove(_lastMethodKey);
    await _storage.remove(_lastIdentifierMaskedKey);
  }

  /// Masks an email or phone identifier for safe local display.
  /// `john@gmail.com` -> `j***@gmail.com`; `+919876543210` -> `+91 98****10`.
  static String maskIdentifier(String identifier) {
    final value = identifier.trim();
    if (value.contains('@')) {
      final parts = value.split('@');
      final local = parts.first;
      final domain = parts.length > 1 ? parts[1] : '';
      if (local.isEmpty) return value;
      final visible = local[0];
      return '$visible***@$domain';
    }
    // Treat as phone: keep last 2 digits, mask the rest.
    final digits = value.replaceAll(RegExp(r'[^0-9+]'), '');
    if (digits.length <= 4) return digits;
    final prefix = digits.startsWith('+')
        ? digits.substring(0, digits.length >= 5 ? 5 : digits.length)
        : digits.substring(0, 2);
    final suffix = digits.substring(digits.length - 2);
    return '$prefix****$suffix';
  }
}
