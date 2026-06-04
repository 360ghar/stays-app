import 'dart:async';

import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:stays_app/app/controllers/base/base_controller.dart';
import 'package:stays_app/app/utils/logger/app_logger.dart';
import 'package:stays_app/app/utils/services/token_service.dart';

/// Controller responsible for session management and remember-me functionality.
/// Handles token persistence, session restoration, and auth state listening.
class SessionController extends BaseController {
  SessionController({required TokenService tokenService})
    : _tokenService = tokenService;

  static const String _rememberMeBox = 'auth_preferences';
  static const String _rememberMeFlagKey = 'remember_me';
  static const String _rememberedAccessTokenKey = 'remembered_access_token';
  static const String _rememberedRefreshTokenKey = 'remembered_refresh_token';

  final TokenService _tokenService;
  late final GetStorage _authPrefs;
  late final Future<void> _rememberMeInit;
  bool _isRememberMeStorageReady = false;
  bool _isDisposed = false;
  StreamSubscription<AuthState>? _authSubscription;

  final RxBool rememberMe = false.obs;
  final RxBool isAuthenticated = false.obs;

  @override
  void onInit() {
    super.onInit();
    _rememberMeInit = _initializeRememberMePreference();
    unawaited(_initAuthStatus());
    unawaited(
      _rememberMeInit.whenComplete(() {
        if (_isDisposed) return;
        _bindAuthStateListener();
      }),
    );
  }

  @override
  void onClose() {
    _isDisposed = true;
    unawaited(_authSubscription?.cancel());
    _authSubscription = null;
    super.onClose();
  }

  /// Wait for the session controller to be ready (tokens loaded)
  Future<void> get ready async {
    await _tokenService.ready;
  }

  /// Initialize remember-me preference from storage
  Future<void> _initializeRememberMePreference() async {
    _authPrefs = GetStorage(_rememberMeBox);
    try {
      await GetStorage.init(_rememberMeBox);
      _isRememberMeStorageReady = true;
      final storedPreference =
          _authPrefs.read<bool>(_rememberMeFlagKey) ?? false;
      rememberMe.value = storedPreference;
    } catch (e, stackTrace) {
      _isRememberMeStorageReady = false;
      rememberMe.value = false;
      AppLogger.error(
        'Failed to initialize remember-me preference',
        e,
        stackTrace,
      );
    }
  }

  /// Check initial authentication status
  Future<void> _initAuthStatus() async {
    try {
      await _tokenService.ready;
    } catch (_) {
      // If readiness throws, proceed with best-effort check
    }
    await _checkAuthStatus();
  }

  /// Check if user is authenticated
  Future<void> _checkAuthStatus() async {
    try {
      final tokenAuth = _tokenService.isAuthenticated.value;
      isAuthenticated.value = tokenAuth;
      AppLogger.info(
        isAuthenticated.value
            ? 'Session: User is authenticated'
            : 'Session: No valid tokens found',
      );
    } catch (e) {
      AppLogger.error('Session auth check failed', e);
      isAuthenticated.value = false;
    }
  }

  /// Bind to Supabase auth state changes
  void _bindAuthStateListener() {
    if (_isDisposed) return;
    unawaited(_authSubscription?.cancel());
    _authSubscription = trackSubscription(
      Supabase.instance.client.auth.onAuthStateChange.listen(
        (data) async {
          final event = data.event;
          final session = data.session;

          if (event == AuthChangeEvent.signedOut) {
            await _tokenService.clearTokens();
            await _clearRememberedSession();
            isAuthenticated.value = false;
            return;
          }

          if (session == null) return;

          if (event == AuthChangeEvent.signedIn ||
              event == AuthChangeEvent.tokenRefreshed) {
            await _updateTokenServiceFromSession(session);
            isAuthenticated.value = true;
            if (rememberMe.value) {
              await _persistRememberedSession(session: session);
            }
          }
        },
        onError: (Object error) {
          AppLogger.warning('Auth state listener error: $error');
        },
      ),
    );
  }

  /// Update the remember-me flag and synchronise it to disk
  Future<void> setRememberMe({required bool value}) async {
    rememberMe.value = value;
    await _rememberMeInit;
    if (!_isRememberMeStorageReady) return;
    await _authPrefs.write(_rememberMeFlagKey, value);
    if (!value) {
      await _clearRememberedSession();
    }
  }

  /// Persist the latest Supabase session when the user opts in
  Future<void> _persistRememberedSession({Session? session}) async {
    await _rememberMeInit;
    if (!_isRememberMeStorageReady) return;
    final activeSession =
        session ?? Supabase.instance.client.auth.currentSession;
    if (activeSession == null) {
      AppLogger.warning(
        'Unable to persist remember-me session: no active session',
      );
      return;
    }
    await _authPrefs.write(_rememberMeFlagKey, true);
    await _authPrefs.write(
      _rememberedAccessTokenKey,
      activeSession.accessToken,
    );
    final refreshToken = activeSession.refreshToken;
    if (refreshToken != null && refreshToken.isNotEmpty) {
      await _authPrefs.write(_rememberedRefreshTokenKey, refreshToken);
    }
  }

  /// Drop cached credentials when the user opts out or signs out
  Future<void> _clearRememberedSession() async {
    await _rememberMeInit;
    if (!_isRememberMeStorageReady) return;
    await _authPrefs.remove(_rememberedAccessTokenKey);
    await _authPrefs.remove(_rememberedRefreshTokenKey);
  }

  /// Sync remember-me state after successful login
  Future<void> syncRememberMeStateAfterLogin() async {
    await _rememberMeInit;
    if (!_isRememberMeStorageReady) return;
    if (rememberMe.value) {
      await _persistRememberedSession();
      return;
    }
    await _authPrefs.write(_rememberMeFlagKey, false);
    await _clearRememberedSession();
  }

  /// Sync TokenService state from a provided Supabase session
  Future<void> _updateTokenServiceFromSession(Session session) async {
    try {
      final access = session.accessToken;
      final refresh = session.refreshToken;
      await _tokenService.storeTokens(
        accessToken: access,
        refreshToken: refresh,
      );
    } catch (e) {
      AppLogger.warning('Failed to sync TokenService from session: $e');
    }
  }

  /// Sync TokenService using the current Supabase session if available
  Future<void> updateTokenServiceFromCurrentSession() async {
    final session = Supabase.instance.client.auth.currentSession;
    if (session != null) {
      await _updateTokenServiceFromSession(session);
    }
  }

  /// Clear all session data (on logout)
  Future<void> clearSession() async {
    await _tokenService.clearTokens();
    await setRememberMe(value: false);
    isAuthenticated.value = false;
  }

  /// Mark user as authenticated
  void setAuthenticated({required bool value}) {
    isAuthenticated.value = value;
  }
}
