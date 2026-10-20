import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import 'package:stays_app/app/utils/logger/app_logger.dart';

/// Reads and removes the boxes that earlier builds kept with GetStorage
/// (`<documents>/<box>.gs`, a JSON map, plus a `.bak` copy). The app no
/// longer uses GetStorage; this lets the preferences survive the upgrade.
class LegacyGetStorage {
  const LegacyGetStorage._();

  static Future<File?> _file(String box, String ext) async {
    if (kIsWebLike) return null;
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/$box.$ext');
  }

  static bool get kIsWebLike => !(Platform.isAndroid || Platform.isIOS);

  /// The stored values of [box], or an empty map when there is none.
  static Future<Map<String, dynamic>> read(String box) async {
    try {
      final file = await _file(box, 'gs');
      if (file == null || !file.existsSync()) return const {};
      final decoded = jsonDecode(await file.readAsString());
      return decoded is Map<String, dynamic> ? decoded : const {};
    } catch (e) {
      // No plugin in unit tests, or an unreadable box: nothing to migrate.
      AppLogger.warning('Legacy box $box not read: $e');
      return const {};
    }
  }

  /// Deletes [box]. A box may hold old plaintext values (for example the
  /// remember-me tokens of old builds), so it is removed after the migration.
  static Future<void> delete(String box) async {
    try {
      for (final ext in const ['gs', 'bak']) {
        final file = await _file(box, ext);
        if (file != null && file.existsSync()) await file.delete();
      }
    } catch (e) {
      AppLogger.warning('Legacy box $box not deleted: $e');
    }
  }
}
