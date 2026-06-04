import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart' show sha256;

import '../logger/app_logger.dart';

/// Simple certificate pinning using SHA-256 of the DER-encoded certificate.
/// Provide a comma-separated list of allowed base64 SHA-256 pins via
/// env var API_CERT_SHA256. Only applies to the API host from AppConfig.
class PinningHttpOverrides extends HttpOverrides {
  final Set<String> allowedPins;
  final String host;

  PinningHttpOverrides({required this.allowedPins, required this.host});

  @override
  HttpClient createHttpClient(SecurityContext? context) {
    final client = super.createHttpClient(context);
    client.badCertificateCallback = (cert, h, port) {
      if (h != host) return false;
      try {
        final der = cert.der;
        final digest = sha256.convert(der).bytes;
        final b64 = base64.encode(digest);
        final ok = allowedPins.contains(b64);
        if (!ok) {
          AppLogger.error('TLS pin mismatch for $host', 'pin=$b64');
        }
        return ok;
      } catch (e) {
        AppLogger.error('Failed to verify certificate pin', e);
        return false;
      }
    };
    return client;
  }
}

// No additional helpers required; using package:crypto's sha256
