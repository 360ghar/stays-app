import 'package:supabase_flutter/supabase_flutter.dart';
import '../../utils/logger/app_logger.dart';

class SupabaseService {
  final String url;
  final String anonKey;

  SupabaseService({required this.url, required this.anonKey});

  SupabaseClient get client => Supabase.instance.client;

  static bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;
    // Skip initialization if keys are placeholders
    final looksPlaceholder = url.contains('YOUR_') || anonKey.contains('YOUR_');
    if (looksPlaceholder) {
      AppLogger.warning('Supabase not configured. Skipping initialization.');
      return;
    }
    try {
      await Supabase.initialize(url: url, anonKey: anonKey);
      _initialized = true;
    } catch (e, st) {
      AppLogger.error('Supabase initialize failed', e, st);
    }
  }
}
