import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../../config/app_config.dart';
import '../../utils/logger/app_logger.dart';

/// Tokens returned by a successful native Google Sign-In.
///
/// [rawNonce] is the un-hashed nonce that must be forwarded to
/// `supabase.auth.signInWithIdToken(nonce: rawNonce)`; Google embeds the
/// SHA-256 hash of this nonce inside [idToken].
class GoogleIdTokenResult {
  const GoogleIdTokenResult({
    required this.idToken,
    this.rawNonce,
    this.email,
    this.displayName,
  });

  final String idToken;
  final String? rawNonce;
  final String? email;
  final String? displayName;
}

/// Raised when Google Sign-In is invoked but no client IDs are configured.
class GoogleSignInNotConfigured implements Exception {
  @override
  String toString() =>
      'GoogleSignInNotConfigured: GOOGLE_WEB_CLIENT_ID / GOOGLE_IOS_CLIENT_ID '
      'are not set in the active environment.';
}

/// Thin wrapper around the `google_sign_in` v7 API for the native ID-token
/// flow used with Supabase. Handles one-time initialization and nonce
/// generation so the auth provider stays focused on Supabase concerns.
class GoogleSignInService {
  GoogleSignInService();

  bool _initialized = false;

  bool get isConfigured => AppConfig.I.isGoogleSignInConfigured;

  Future<void> _ensureInitialized({String? hashedNonce}) async {
    // The nonce must be supplied at initialize() time on the v7 API so it is
    // embedded into the issued ID token. We therefore re-initialize per
    // sign-in attempt with a fresh hashed nonce.
    await GoogleSignIn.instance.initialize(
      clientId: AppConfig.I.googleIosClientId,
      serverClientId: AppConfig.I.googleWebClientId,
      nonce: hashedNonce,
    );
    _initialized = true;
  }

  /// Triggers the native account picker and returns an ID token + raw nonce.
  /// Returns null when the user cancels.
  Future<GoogleIdTokenResult?> signIn() async {
    if (!isConfigured) {
      throw GoogleSignInNotConfigured();
    }

    final rawNonce = _generateNonce();
    final hashedNonce = _sha256ofString(rawNonce);

    await _ensureInitialized(hashedNonce: hashedNonce);

    if (!GoogleSignIn.instance.supportsAuthenticate()) {
      AppLogger.warning(
        'Google Sign-In: platform does not support authenticate()',
      );
      throw GoogleSignInNotConfigured();
    }

    try {
      final account = await GoogleSignIn.instance.authenticate();
      final auth = account.authentication;
      final idToken = auth.idToken;
      if (idToken == null || idToken.isEmpty) {
        AppLogger.warning('Google Sign-In: no idToken returned');
        return null;
      }
      return GoogleIdTokenResult(
        idToken: idToken,
        rawNonce: rawNonce,
        email: account.email,
        displayName: account.displayName,
      );
    } on GoogleSignInException catch (e) {
      // User canceled — treat as a no-op rather than an error.
      if (e.code == GoogleSignInExceptionCode.canceled) {
        AppLogger.info('Google Sign-In canceled by user');
        return null;
      }
      AppLogger.error('Google Sign-In failed: ${e.code} ${e.description}', e);
      rethrow;
    }
  }

  Future<void> signOut() async {
    if (!_initialized) return;
    try {
      await GoogleSignIn.instance.signOut();
    } catch (e) {
      AppLogger.warning('Google signOut failed: $e');
    }
  }

  // Cryptographically-secure random nonce (RFC-style charset).
  String _generateNonce([int length = 32]) {
    const charset =
        '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';
    final random = Random.secure();
    return List.generate(
      length,
      (_) => charset[random.nextInt(charset.length)],
    ).join();
  }

  String _sha256ofString(String input) {
    final bytes = utf8.encode(input);
    return sha256.convert(bytes).toString();
  }
}
