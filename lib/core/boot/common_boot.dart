import 'dart:io';

import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'package:stays_app/app/utils/logger/app_logger.dart';
import 'package:stays_app/app/utils/security/cert_pinning.dart';
import 'package:stays_app/config/app_config.dart';

/// Shared boot helpers for all entry points
/// (`main.dart`, `main_dev.dart`, `main_staging.dart`, `main_prod.dart`).
///
/// The four mains previously copy-pasted this block 4x; they now call these.
/// Divergence is documented, not duplicated:
/// - `main_prod.dart` additionally calls `Firebase.initializeApp()`.
/// - `main.dart` defaults to the dev env (same as `main_dev.dart`).
/// - Log titles differ per flavor ("(Dev)"/"(Staging)"/none).
///
/// Cert pinning stays opt-in via the `API_CERT_SHA256` env var in every
/// flavor; see [applyCertPinning].
/// Opt-in certificate pinning from `API_CERT_SHA256` (comma-separated
/// base64 SPKI pins). No-op when unset/empty. Pure w.r.t. DI: touches only
/// [HttpOverrides.global], never GetX.
void applyCertPinning({bool log = false}) {
  final pinsRaw = dotenv.env['API_CERT_SHA256'];
  if (pinsRaw == null || pinsRaw.trim().isEmpty) return;
  final host = Uri.parse(AppConfig.I.api.apiBaseUrl).host;
  final pins = pinsRaw
      .split(',')
      .map((e) => e.trim())
      .where((e) => e.isNotEmpty)
      .toSet();
  if (pins.isEmpty) return;
  HttpOverrides.global = PinningHttpOverrides(allowedPins: pins, host: host);
  if (log) {
    AppLogger.info('Certificate pinning enabled for $host');
  }
}
