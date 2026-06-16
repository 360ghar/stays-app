import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import '../../utils/logger/app_logger.dart';

/// Tokens returned by a successful native Sign in with Apple.
///
/// [rawNonce] is the un-hashed nonce that must be forwarded to
/// `supabase.auth.signInWithIdToken(nonce: rawNonce)`; Apple embeds the
/// SHA-256 hash of this nonce inside [idToken].
class AppleIdTokenResult {
  const AppleIdTokenResult({
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

/// Thin wrapper around `sign_in_with_apple` for the native ID-token flow used
/// with Supabase. Handles nonce generation/hashing and full-name assembly.
class AppleSignInService {
  AppleSignInService();

  /// Apple Sign-In is only offered on iOS in this app (Android/web would
  /// require the web redirect flow + a Service ID, which is out of scope).
  bool get isSupportedPlatform => Platform.isIOS;

  Future<bool> isAvailable() async {
    if (!isSupportedPlatform) return false;
    try {
      return await SignInWithApple.isAvailable();
    } catch (e) {
      AppLogger.warning('Apple Sign-In availability check failed: $e');
      return false;
    }
  }

  /// Triggers the native Apple credential sheet and returns an ID token + raw
  /// nonce. Returns null when the user cancels.
  Future<AppleIdTokenResult?> signIn() async {
    final rawNonce = _generateNonce();
    final hashedNonce = _sha256ofString(rawNonce);

    try {
      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: const [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        nonce: hashedNonce,
      );

      final idToken = credential.identityToken;
      if (idToken == null || idToken.isEmpty) {
        AppLogger.warning('Apple Sign-In: no identityToken returned');
        return null;
      }

      // Apple only returns name/email on the FIRST authorization.
      final displayName = [
        credential.givenName,
        credential.familyName,
      ].where((p) => p != null && p.trim().isNotEmpty).join(' ').trim();

      return AppleIdTokenResult(
        idToken: idToken,
        rawNonce: rawNonce,
        email: credential.email,
        displayName: displayName.isEmpty ? null : displayName,
      );
    } on SignInWithAppleAuthorizationException catch (e) {
      // User canceled — treat as a no-op rather than an error.
      if (e.code == AuthorizationErrorCode.canceled) {
        AppLogger.info('Apple Sign-In canceled by user');
        return null;
      }
      AppLogger.error('Apple Sign-In failed: ${e.code} ${e.message}', e);
      rethrow;
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
