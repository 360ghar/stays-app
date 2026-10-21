/// Auth-layer slice of [AppConfig].
///
/// Additive split: new code should read `AppConfig.I.auth.*` instead of the
/// top-level fields.
class AuthConfig {
  const AuthConfig({
    required this.supabaseUrl,
    required this.supabasePublishableKey,
    this.googleWebClientId,
    this.googleIosClientId,
  });

  final String supabaseUrl;
  final String supabasePublishableKey;

  /// Google OAuth Web client ID (Android `serverClientId`).
  final String? googleWebClientId;

  /// Google OAuth iOS client ID (iOS `clientId`).
  final String? googleIosClientId;

  /// Whether native Google Sign-In is configured (at least one client ID).
  bool get isGoogleSignInConfigured =>
      (googleWebClientId != null && googleWebClientId!.isNotEmpty) ||
      (googleIosClientId != null && googleIosClientId!.isNotEmpty);
}
