import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../utils/logger/app_logger.dart';

/// Manages the "Remember Me" preference.
///
/// SECURITY CONTRACT: this service NEVER stores tokens. Session tokens live
/// exclusively in TokenService/StorageService (flutter_secure_storage);
/// shared preferences here hold only a boolean flag.
class RememberMeService {
  factory RememberMeService() => _shared;
  RememberMeService._internal();

  // Shared instance so the whole app shares one preference state.
  static final RememberMeService _shared = RememberMeService._internal();

  static const String _rememberMeFlagKey = 'remember_me';

  SharedPreferences? _prefs;
  final ValueNotifier<bool> isEnabled = ValueNotifier<bool>(false);
  bool _initialized = false;

  /// Initialize the service (idempotent — safe to call from multiple
  /// controllers during startup).
  Future<RememberMeService> init() async {
    if (_initialized) return this;
    _prefs ??= await SharedPreferences.getInstance();
    isEnabled.value = _prefs?.getBool(_rememberMeFlagKey) ?? false;
    _initialized = true;
    AppLogger.info(
      'RememberMeService initialized. Enabled: ${isEnabled.value}',
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
