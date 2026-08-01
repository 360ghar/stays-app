import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../config/app_config.dart';
import '../../utils/logger/app_logger.dart';

class SupabaseService {
  SupabaseService({required this.url, required this.publishableKey});

  final String url;
  final String publishableKey;

  SupabaseClient get client => Supabase.instance.client;

  static bool _initialized = false;

  /// Last initialization error, if any. Set in the catch on failure and
  /// cleared at the start of each attempt so a later success (or placeholder
  /// skip) reports a clean slate. Startup never rethrows — callers can poll
  /// [isReady] / [lastInitError] instead.
  static Object? lastInitError;

  /// Whether Supabase has been initialized successfully.
  bool get isReady => _initialized;

  /// Optional shared init future. When the entry point sets this, the
  /// `InitialBinding` registration awaits the same promise instead of
  /// re-running `initialize()` (which would be a no-op but skip awaiting).
  static Future<void>? supabaseServiceReady;

  Future<void> initialize() async {
    lastInitError = null;
    if (_initialized) return;
    // Skip initialization if either value is a placeholder; the same set of
    // patterns is enforced in AppConfig._validateEnvironment.
    if (AppConfig.isPlaceholderValue(url) ||
        AppConfig.isPlaceholderValue(publishableKey)) {
      AppLogger.warning('Supabase not configured. Skipping initialization.');
      return;
    }
    try {
      // ponytail: pin is supabase_flutter ^2.6.0; `publishableKey` is added in
      // the v3.x major. Switch to `publishableKey:` on the next bump.
      await Supabase.initialize(url: url, anonKey: publishableKey);
      _initialized = true;
    } catch (e, st) {
      _initialized = false;
      lastInitError = e;
      AppLogger.error('Supabase initialize failed', e, st);
    }
  }
}
