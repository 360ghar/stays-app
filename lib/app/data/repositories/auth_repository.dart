import 'package:get/get.dart';

import '../services/storage_service.dart';
import '../../utils/services/token_service.dart';
import '../models/user_model.dart';
import '../../utils/logger/app_logger.dart';
import '../../utils/exceptions/app_exceptions.dart';
import '../providers/auth/i_auth_provider.dart';
import '../providers/auth_api_provider.dart';

/// Repository-level outcome of a Google sign-in attempt.
/// - [session]: native ID-token flow succeeded; [user] is populated.
/// - [redirectLaunched]: OAuth redirect started; session arrives async.
/// - [canceled]: user dismissed the flow / launch failed.
enum GoogleLoginStatus { session, redirectLaunched, canceled }

class GoogleLoginResult {
  final GoogleLoginStatus status;
  final UserModel? user;

  const GoogleLoginResult._(this.status, [this.user]);

  const GoogleLoginResult.session(UserModel user)
    : this._(GoogleLoginStatus.session, user);
  const GoogleLoginResult.redirectLaunched()
    : this._(GoogleLoginStatus.redirectLaunched);
  const GoogleLoginResult.canceled() : this._(GoogleLoginStatus.canceled);

  bool get hasSession => status == GoogleLoginStatus.session;
  bool get isRedirect => status == GoogleLoginStatus.redirectLaunched;
  bool get isCanceled => status == GoogleLoginStatus.canceled;
}

class AuthRepository {
  final IAuthProvider _provider;
  final AuthApiProvider _authApi;
  final StorageService _storage = Get.find<StorageService>();

  AuthRepository({required IAuthProvider provider, AuthApiProvider? authApi})
    : _provider = provider,
      _authApi = authApi ?? AuthApiProvider();

  Future<UserModel> loginWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final res = await _provider.loginWithEmail(
        email: email,
        password: password,
      );
      await _persistTokens(res);
      final user = _mapUser(res.rawUser);
      await _persistUserData(user);
      return user;
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(message: e.toString(), statusCode: 400);
    }
  }

  Future<UserModel> loginWithPhone({
    required String phone,
    required String password,
  }) async {
    try {
      final res = await _provider.loginWithPhone(
        phone: phone,
        password: password,
      );
      await _persistTokens(res);
      final user = _mapUser(res.rawUser);
      await _persistUserData(user);
      return user;
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(message: e.toString(), statusCode: 400);
    }
  }

  Future<UserModel> register({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      final res = await _provider.register(
        name: name,
        email: email,
        password: password,
      );
      await _persistTokens(res);
      final user = _mapUser(res.rawUser);
      await _persistUserData(user);
      return user;
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(message: e.toString(), statusCode: 400);
    }
  }

  Future<bool> signUpWithPhone({
    required String phone,
    required String password,
    Map<String, String>? data,
  }) => _provider.signUpWithPhone(phone: phone, password: password, data: data);

  Future<void> updatePassword({
    required String newPassword,
    String? currentPassword,
  }) => _provider.updatePassword(
    newPassword: newPassword,
    currentPassword: currentPassword,
  );

  // ---------------------------------------------------------------------------
  // Login state-machine
  // ---------------------------------------------------------------------------

  /// Calls the backend `/auth/identifier-status` endpoint. Throws on error.
  Future<IdentifierStatus> checkIdentifierStatus(String identifier) async {
    try {
      return await _authApi.identifierStatus(identifier);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(message: e.toString(), statusCode: 400);
    }
  }

  /// Records the last-used auth method (best-effort, never throws).
  Future<void> recordLastMethod(String method) =>
      _authApi.recordLastMethod(method);

  /// Fetches the auth gate state from the backend.
  /// Returns a map with `stage`, `next_action`, and `missing_fields`.
  Future<Map<String, dynamic>> getAuthGateState({String app = 'stays'}) =>
      _authApi.getAuthGateState(app: app);

  /// Marks the given app's onboarding as complete. Best-effort.
  Future<void> completeOnboarding({String app = 'stays'}) =>
      _authApi.completeOnboarding(app: app);

  // ---------------------------------------------------------------------------
  // Google Sign-In (native ID-token flow OR Supabase OAuth redirect flow)
  // ---------------------------------------------------------------------------

  /// Drives Google sign-in. On the native path, persists tokens and returns a
  /// [GoogleLoginResult] with the user. On the redirect path, the browser is
  /// launched and the session arrives later via `onAuthStateChange`.
  Future<GoogleLoginResult> signInWithGoogle() async {
    try {
      final outcome = await _provider.signInWithGoogle();
      switch (outcome.status) {
        case GoogleSignInStatus.session:
          final res = outcome.result!;
          await _persistTokens(res);
          final user = _mapUser(res.rawUser);
          await _persistUserData(user);
          return GoogleLoginResult.session(user);
        case GoogleSignInStatus.redirectLaunched:
          return const GoogleLoginResult.redirectLaunched();
        case GoogleSignInStatus.canceled:
          return const GoogleLoginResult.canceled();
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(message: e.toString(), statusCode: 400);
    }
  }

  // ---------------------------------------------------------------------------
  // Sign in with Apple (native ID-token flow, iOS)
  // ---------------------------------------------------------------------------

  /// Returns a [UserModel] on success, or null if the user canceled.
  Future<UserModel?> signInWithApple() async {
    try {
      final res = await _provider.signInWithApple();
      if (res == null) return null;
      await _persistTokens(res);
      final user = _mapUser(res.rawUser);
      await _persistUserData(user);
      return user;
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(message: e.toString(), statusCode: 400);
    }
  }

  // ---------------------------------------------------------------------------
  // Email OTP
  // ---------------------------------------------------------------------------

  Future<void> sendEmailOtp({
    required String email,
    bool shouldCreateUser = false,
  }) async {
    try {
      await _provider.sendEmailOtp(
        email: email,
        shouldCreateUser: shouldCreateUser,
      );
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(message: e.toString(), statusCode: 400);
    }
  }

  Future<UserModel> verifyEmailOtp({
    required String email,
    required String token,
  }) async {
    try {
      final res = await _provider.verifyEmailOtp(email: email, token: token);
      await _persistTokens(res);
      final user = _mapUser(res.rawUser);
      await _persistUserData(user);
      return user;
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(message: e.toString(), statusCode: 400);
    }
  }

  Future<void> resendEmailOtp({
    required String email,
    bool shouldCreateUser = false,
  }) async {
    try {
      await _provider.resendEmailOtp(
        email: email,
        shouldCreateUser: shouldCreateUser,
      );
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(message: e.toString(), statusCode: 400);
    }
  }

  // ---------------------------------------------------------------------------
  // Add + verify phone (for Google/passwordless accounts)
  // ---------------------------------------------------------------------------

  Future<void> addPhone({required String phone}) async {
    try {
      await _provider.addPhone(phone: phone);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(message: e.toString(), statusCode: 400);
    }
  }

  Future<UserModel> verifyPhoneChangeOtp({
    required String phone,
    required String token,
  }) async {
    try {
      final res = await _provider.verifyPhoneChangeOtp(
        phone: phone,
        token: token,
      );
      await _persistTokens(res);
      final user = _mapUser(res.rawUser);
      await _persistUserData(user);
      return user;
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(message: e.toString(), statusCode: 400);
    }
  }

  Future<void> logout() async {
    try {
      await _provider.logout();
    } finally {
      try {
        final tokenService = Get.find<TokenService>();
        await tokenService.ready;
        await tokenService.clearTokens();
      } catch (_) {
        await _storage.clearTokens();
      }
      await _storage.clearUserData();
    }
  }

  Future<UserModel?> getCurrentUser() async {
    final raw = await _provider.getCurrentUserRaw();
    if (raw != null) {
      final user = _mapUser(raw);
      await _persistUserData(user);
      return user;
    }
    final userData = await _storage.getUserData();
    if (userData != null) {
      return UserModel.fromMap(userData);
    }
    return null;
  }

  Future<bool> isAuthenticated() => _provider.isAuthenticated();

  /// Permanently deletes the authenticated user's account via the backend API.
  Future<void> deleteAccount() => _authApi.deleteAccount();

  // Helpers
  UserModel _mapUser(Map<String, dynamic>? raw) {
    final m = raw ?? const <String, dynamic>{};
    return UserModel(
      id: (m['id'] ?? m['user_id'] ?? '').toString(),
      email: m['email'] as String?,
      phone: m['phone'] as String?,
      firstName: m['first_name'] as String?,
      lastName: m['last_name'] as String?,
      name: (m['full_name'] as String?) ?? (m['name'] as String?),
    );
  }

  Future<void> _persistTokens(ProviderAuthResult res) async {
    if (res.accessToken == null) return;
    try {
      final tokenService = Get.find<TokenService>();
      await tokenService.ready;
      await tokenService.storeTokens(
        accessToken: res.accessToken!,
        refreshToken: res.refreshToken,
      );
    } catch (e) {
      AppLogger.warning('Failed to persist tokens: $e');
    }
  }

  Future<void> _persistUserData(UserModel user) =>
      _storage.saveUserData(user.toMap());
}
