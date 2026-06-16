import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;
import 'package:url_launcher/url_launcher.dart' show LaunchMode;

import '../services/storage_service.dart';
import '../services/google_sign_in_service.dart';
import '../services/apple_sign_in_service.dart';
import 'auth/i_auth_provider.dart';
import '../../utils/logger/app_logger.dart';

class SupabaseAuthProvider extends GetxService implements IAuthProvider {
  final supabase.SupabaseClient _supabase = supabase.Supabase.instance.client;
  final StorageService _storage = Get.find<StorageService>();

  GoogleSignInService get _google => Get.isRegistered<GoogleSignInService>()
      ? Get.find<GoogleSignInService>()
      : Get.put<GoogleSignInService>(GoogleSignInService());

  AppleSignInService get _apple => Get.isRegistered<AppleSignInService>()
      ? Get.find<AppleSignInService>()
      : Get.put<AppleSignInService>(AppleSignInService());

  @override
  Future<ProviderAuthResult> loginWithEmail({
    required String email,
    required String password,
  }) async {
    final res = await _supabase.auth.signInWithPassword(
      email: email,
      password: password,
    );
    return ProviderAuthResult(
      accessToken: res.session?.accessToken,
      refreshToken: res.session?.refreshToken,
      rawUser: _mapUser(res.user),
    );
  }

  @override
  Future<ProviderAuthResult> loginWithPhone({
    required String phone,
    required String password,
  }) async {
    final res = await _supabase.auth.signInWithPassword(
      phone: _ensureE164(phone),
      password: password,
    );
    return ProviderAuthResult(
      accessToken: res.session?.accessToken,
      refreshToken: res.session?.refreshToken,
      rawUser: _mapUser(res.user),
    );
  }

  @override
  Future<ProviderAuthResult> register({
    required String name,
    required String email,
    required String password,
  }) async {
    // Send 6-digit OTP (creates user without password; password is set after
    // OTP verification via [verifyEmailOtp] + [updatePassword]).
    await _supabase.auth.signInWithOtp(
      email: email,
      data: {'full_name': name},
      shouldCreateUser: true,
      emailRedirectTo: googleRedirectUrl,
    );
    return ProviderAuthResult(
      accessToken: null,
      refreshToken: null,
      rawUser: null,
    );
  }

  @override
  Future<bool> signUpWithPhone({
    required String phone,
    required String password,
    Map<String, String>? data,
  }) async {
    final res = await _supabase.auth.signUp(
      phone: _ensureE164(phone),
      password: password,
      data: data,
    );
    AppLogger.info('Supabase phone signUp: user=${res.user?.id}');
    return true;
  }

  @override
  Future<void> updatePassword({
    required String newPassword,
    String? currentPassword,
  }) async {
    await _supabase.auth.updateUser(
      supabase.UserAttributes(password: newPassword),
    );
    if (currentPassword != null && currentPassword.isNotEmpty) {
      final email = _supabase.auth.currentUser?.email;
      if (email != null) {
        await _supabase.auth.signInWithPassword(
          email: email,
          password: newPassword,
        );
      }
    }
  }

  /// Deep-link callback used by the Supabase OAuth redirect flow. Uses the
  /// app's existing custom scheme (registered in iOS Info.plist /
  /// AndroidManifest as `stays360`).
  static const String googleRedirectUrl = 'stays360://login-callback';

  @override
  Future<GoogleSignInOutcome> signInWithGoogle() async {
    // Prefer the native ID-token flow only when a web client ID is configured.
    if (_google.isConfigured) {
      try {
        final tokens = await _google.signIn();
        if (tokens == null) {
          // signIn() returns null ONLY on user cancellation — never fall back.
          return const GoogleSignInOutcome(GoogleSignInStatus.canceled);
        }
        final res = await _supabase.auth.signInWithIdToken(
          provider: supabase.OAuthProvider.google,
          idToken: tokens.idToken,
          nonce: tokens.rawNonce,
        );
        AppLogger.info('Supabase Google signIn (native): user=${res.user?.id}');
        return GoogleSignInOutcome(
          GoogleSignInStatus.session,
          ProviderAuthResult(
            accessToken: res.session?.accessToken,
            refreshToken: res.session?.refreshToken,
            rawUser: _mapUser(res.user),
          ),
        );
      } catch (e) {
        // Native path failed for a NON-cancellation reason (e.g. iOS/Android
        // OAuth clients or SHA fingerprints not yet provisioned, missing
        // oauth_clients in google-services.json, token-exchange error).
        // Fall back to the Supabase OAuth redirect flow, which works against
        // the already-enabled provider. Upgrades to native automatically once
        // the native clients are provisioned.
        AppLogger.warning(
          'Native Google sign-in failed ($e); falling back to OAuth redirect.',
        );
        return _googleOAuthRedirect();
      }
    }

    return _googleOAuthRedirect();
  }

  /// Supabase OAuth redirect flow. Launches the browser and returns; the
  /// session is delivered via the deep-link callback + onAuthStateChange
  /// (detectSessionInUri defaults to true).
  Future<GoogleSignInOutcome> _googleOAuthRedirect() async {
    final launched = await _supabase.auth.signInWithOAuth(
      supabase.OAuthProvider.google,
      redirectTo: googleRedirectUrl,
      authScreenLaunchMode: LaunchMode.externalApplication,
    );
    AppLogger.info('Supabase Google signIn (redirect) launched=$launched');
    return launched
        ? const GoogleSignInOutcome(GoogleSignInStatus.redirectLaunched)
        : const GoogleSignInOutcome(GoogleSignInStatus.canceled);
  }

  @override
  Future<ProviderAuthResult?> signInWithApple() async {
    final tokens = await _apple.signIn();
    if (tokens == null) {
      // User canceled or no token returned.
      return null;
    }
    final res = await _supabase.auth.signInWithIdToken(
      provider: supabase.OAuthProvider.apple,
      idToken: tokens.idToken,
      nonce: tokens.rawNonce,
    );
    AppLogger.info('Supabase Apple signIn: user=${res.user?.id}');
    return ProviderAuthResult(
      accessToken: res.session?.accessToken,
      refreshToken: res.session?.refreshToken,
      rawUser: _mapUser(res.user),
    );
  }

  @override
  Future<void> sendEmailOtp({
    required String email,
    bool shouldCreateUser = false,
  }) async {
    await _supabase.auth.signInWithOtp(
      email: email,
      emailRedirectTo: googleRedirectUrl,
      shouldCreateUser: shouldCreateUser,
    );
  }

  @override
  Future<ProviderAuthResult> verifyEmailOtp({
    required String email,
    required String token,
  }) async {
    final res = await _supabase.auth.verifyOTP(
      email: email,
      token: token,
      type: supabase.OtpType.email,
    );
    return ProviderAuthResult(
      accessToken: res.session?.accessToken,
      refreshToken: res.session?.refreshToken,
      rawUser: _mapUser(res.user),
    );
  }

  @override
  Future<void> resendEmailOtp({
    required String email,
    bool shouldCreateUser = false,
  }) async {
    // Re-issuing the OTP via signInWithOtp is reliable for unverified users.
    await _supabase.auth.signInWithOtp(
      email: email,
      emailRedirectTo: googleRedirectUrl,
      shouldCreateUser: shouldCreateUser,
    );
  }

  @override
  Future<void> addPhone({required String phone}) async {
    await _supabase.auth.updateUser(
      supabase.UserAttributes(phone: _ensureE164(phone)),
    );
  }

  @override
  Future<ProviderAuthResult> verifyPhoneChangeOtp({
    required String phone,
    required String token,
  }) async {
    final res = await _supabase.auth.verifyOTP(
      phone: _ensureE164(phone),
      token: token,
      type: supabase.OtpType.phoneChange,
    );
    return ProviderAuthResult(
      accessToken: res.session?.accessToken,
      refreshToken: res.session?.refreshToken,
      rawUser: _mapUser(res.user),
    );
  }

  @override
  Future<void> logout() async {
    try {
      await _supabase.auth.signOut();
      await _google.signOut();
    } finally {
      await _storage.clearTokens();
      await _storage.clearUserData();
    }
  }

  @override
  Future<Map<String, dynamic>?> getCurrentUserRaw() async {
    final u = _supabase.auth.currentUser;
    return _mapUser(u);
  }

  @override
  Future<bool> isAuthenticated() async {
    final session = _supabase.auth.currentSession;
    return session != null && session.accessToken.isNotEmpty;
  }

  // Token persistence is handled at repository/service layer to avoid
  // duplicate keychain writes and race conditions.

  Map<String, dynamic>? _mapUser(supabase.User? user) {
    if (user == null) return null;
    final meta = user.userMetadata ?? {};
    return {
      'id': user.id,
      'email': user.email,
      'phone': user.phone,
      'first_name': meta['first_name'],
      'last_name': meta['last_name'],
      'full_name': meta['full_name'] ?? meta['name'],
    };
  }

  String _ensureE164(String phone) {
    final trimmed = phone.replaceAll(RegExp(r'\s+'), '');
    if (trimmed.startsWith('+')) return trimmed;
    return '+91$trimmed';
  }
}
