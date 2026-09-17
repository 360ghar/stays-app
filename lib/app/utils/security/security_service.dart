import 'package:get/get.dart';

import '../../../config/app_config.dart';
import '../logger/app_logger.dart';

class SecurityService extends GetxService {
  static SecurityService get I => Get.find<SecurityService>();

  /// Pure static validator: reads [AppConfig] only, never touches GetX, so
  /// entry points can call it before any binding runs. Do not make this an
  /// instance method — `SecurityService()` construction before
  /// InitialBinding breaks the startup DI order.
  static void validateApiKeys() {
    _validateKey('SUPABASE_URL', AppConfig.I.auth.supabaseUrl);
    _validateKey(
      'SUPABASE_PUBLISHABLE_KEY',
      AppConfig.I.auth.supabasePublishableKey,
    );
  }

  static void _validateKey(String name, String value) {
    if (value.isEmpty || value.contains('YOUR_DEV_SUPABASE')) {
      // Never log the configured value itself — only a masked form.
      AppLogger.warning('Potentially invalid $name configured', {
        'value': obfuscate(value),
      });
    }
  }

  static String obfuscate(String input, {int visible = 4}) {
    if (input.length <= visible) return '*' * input.length;
    final prefix = input.substring(0, visible);
    final suffix = input.substring(input.length - visible);
    return '$prefix****$suffix';
  }
}
