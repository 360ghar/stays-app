import 'package:get/get.dart';

import '../../../config/app_config.dart';
import '../logger/app_logger.dart';

class SecurityService extends GetxService {
  static SecurityService get I => Get.find<SecurityService>();

  void validateApiKeys() {
    _validateKey('SUPABASE_URL', AppConfig.I.supabaseUrl);
    _validateKey('SUPABASE_ANON_KEY', AppConfig.I.supabaseAnonKey);
  }

  void _validateKey(String name, String value) {
    if (value.isEmpty || value.contains('YOUR_DEV_SUPABASE')) {
      AppLogger.warning('Potentially invalid $name configured', value);
    }
  }

  String obfuscate(String input, {int visible = 4}) {
    if (input.length <= visible) return '*' * input.length;
    final prefix = input.substring(0, visible);
    final suffix = input.substring(input.length - visible);
    return '$prefix****$suffix';
  }
}
