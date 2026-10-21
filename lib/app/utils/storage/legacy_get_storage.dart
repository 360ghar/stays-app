import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:path_provider/path_provider.dart';

import 'package:stays_app/app/utils/logger/app_logger.dart';

/// Reads and removes the boxes that earlier builds kept with GetStorage
/// (`<documents>/<box>.gs`, a JSON map, plus a `.bak` copy). The app no
/// longer uses GetStorage; this lets the preferences survive the upgrade.
class LegacyGetStorage {
  const LegacyGetStorage._();

  static bool get _supported =>
      !kIsWeb && (Platform.isAndroid || Platform.isIOS);

  static Future<File> _file(String box, String ext) async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/$box.$ext');
  }

  /// The stored values of [box], or an empty map when there is none. GetStorage
  /// keeps a `.bak` copy for recovery: it is read when the `.gs` file is
  /// missing or unreadable.
  static Future<Map<String, dynamic>> read(String box) async {
    if (!_supported) return const {};
    for (final ext in const ['gs', 'bak']) {
      try {
        final file = await _file(box, ext);
        if (!file.existsSync()) continue;
        final decoded = jsonDecode(await file.readAsString());
        if (decoded is Map<String, dynamic>) return decoded;
      } catch (e) {
        // No plugin in unit tests, or an unreadable copy: try the next one.
        AppLogger.warning('Legacy box $box.$ext not read: $e');
      }
    }
    return const {};
  }

  /// Deletes [box]. A box may hold old plaintext values (for example the
  /// remember-me tokens of old builds), so it is removed after the migration.
  static Future<void> delete(String box) async {
    if (!_supported) return;
    try {
      for (final ext in const ['gs', 'bak']) {
        final file = await _file(box, ext);
        if (file.existsSync()) await file.delete();
      }
    } catch (e) {
      AppLogger.warning('Legacy box $box not deleted: $e');
    }
  }
}
