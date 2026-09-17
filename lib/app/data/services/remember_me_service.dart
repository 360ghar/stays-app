import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../utils/logger/app_logger.dart';

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

/// Manages the "Remember Me" preference and last-used auth method memory.
///
/// SECURITY CONTRACT: this service NEVER stores tokens. Session tokens live
/// exclusively in TokenService/StorageService (flutter_secure_storage);
/// shared preferences here hold only a boolean flag and masked identifiers.
class RememberMeService {
  factory RememberMeService() => _shared;
  RememberMeService._internal();

  // Shared instance so the whole app shares one preference state.
  static final RememberMeService _shared = RememberMeService._internal();

  static const String _rememberMeFlagKey = 'remember_me';
  // Last-used auth method memory (req: remember & pre-select last method).
  static const String _lastMethodKey = 'last_auth_method';
  static const String _lastIdentifierMaskedKey = 'last_identifier_masked';

  SharedPreferences? _prefs;
  final ValueNotifier<bool> isEnabled = ValueNotifier<bool>(false);
  bool _initialized = false;

  /// Last-used auth method (one of [AuthMethods]); null if none recorded.
  final ValueNotifier<String?> lastMethod = ValueNotifier<String?>(null);

  /// Masked last identifier (e.g. `j***@gmail.com`, `+91 98****3210`).
  final ValueNotifier<String?> lastIdentifierMasked =
      ValueNotifier<String?>(null);

  /// Initialize the service (idempotent — safe to call from multiple
  /// controllers during startup).
  Future<RememberMeService> init() async {
    if (_initialized) return this;
    _prefs ??= await SharedPreferences.getInstance();
    isEnabled.value = _prefs?.getBool(_rememberMeFlagKey) ?? false;
    lastMethod.value = _prefs?.getString(_lastMethodKey);
    lastIdentifierMasked.value = _prefs?.getString(_lastIdentifierMaskedKey);
    _initialized = true;
    AppLogger.info(
      'RememberMeService initialized. Enabled: ${isEnabled.value}, '
      'lastMethod: ${lastMethod.value}',
    );
    return this;
  }

  /// Check if remember-me is enabled
  bool get enabled => isEnabled.value;

  /// Enable or disable remember-me
  Future<void> setEnabled({required bool value}) async {
    isEnabled.value = value;
    final prefs = _prefs ??= await SharedPreferences.getInstance();
    await prefs.setBool(_rememberMeFlagKey, value);
  }

  /// Sync remember-me state after login (flag only — tokens are handled by
  /// TokenService).
  Future<void> syncAfterLogin() async {
    final prefs = _prefs ??= await SharedPreferences.getInstance();
    await prefs.setBool(_rememberMeFlagKey, isEnabled.value);
  }

  /// Handle sign-out by clearing the preference flag.
  Future<void> onSignOut() async {
    await setEnabled(value: false);
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
    final prefs = _prefs ??= await SharedPreferences.getInstance();
    await prefs.setString(_lastMethodKey, method);

    if (identifier != null && identifier.trim().isNotEmpty) {
      final masked = maskIdentifier(identifier.trim());
      lastIdentifierMasked.value = masked;
      await prefs.setString(_lastIdentifierMaskedKey, masked);
    }
    AppLogger.info('Saved last auth method: $method');
  }

  /// Returns the stored last-used auth method (or null).
  String? getLastMethod() =>
      lastMethod.value ?? _prefs?.getString(_lastMethodKey);

  /// Returns the stored masked identifier (or null).
  String? getLastIdentifierMasked() =>
      lastIdentifierMasked.value ?? _prefs?.getString(_lastIdentifierMaskedKey);

  Future<void> clearLastMethod() async {
    lastMethod.value = null;
    lastIdentifierMasked.value = null;
    final prefs = _prefs ??= await SharedPreferences.getInstance();
    await prefs.remove(_lastMethodKey);
    await prefs.remove(_lastIdentifierMaskedKey);
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
