import 'dart:async';

import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:stays_app/app/data/repositories/auth_repository.dart';
import 'package:stays_app/app/data/models/user_model.dart';
import 'package:stays_app/app/data/providers/auth/i_auth_provider.dart';
import 'package:stays_app/app/routes/app_routes.dart';
import 'package:stays_app/config/app_config.dart';
import 'package:stays_app/app/utils/logger/app_logger.dart';
import 'package:stays_app/app/utils/exceptions/app_exceptions.dart';
import 'package:stays_app/app/data/repositories/profile_repository.dart';
import 'package:stays_app/app/data/providers/users_provider.dart';
import 'package:stays_app/app/data/services/storage_service.dart';
import 'package:stays_app/app/utils/services/token_service.dart';
import 'package:stays_app/app/utils/helpers/app_snackbar.dart';
import 'package:stays_app/app/controllers/base/base_controller.dart';
import 'package:stays_app/app/data/services/analytics_service.dart';
import 'package:stays_app/app/data/services/apple_sign_in_service.dart';
import 'package:stays_app/app/data/services/remember_me_service.dart';
import 'form_validation_controller.dart';
import 'otp_controller.dart';

class AuthController extends BaseController {
  // Storage keys dedicated to the remember-me preference and cached tokens.
  static const String _rememberMeBox = 'auth_preferences';
  static const String _rememberMeFlagKey = 'remember_me';
  // Last-used auth method memory (mirrors RememberMeService keys; same box).
  static const String _lastMethodKey = 'last_auth_method';
  static const String _lastIdentifierMaskedKey = 'last_identifier_masked';
  // Legacy keys from older builds (plaintext tokens). Kept for one-time cleanup.
  static const String _rememberedAccessTokenKey = 'remembered_access_token';
  static const String _rememberedRefreshTokenKey = 'remembered_refresh_token';

  final AuthRepository _authRepository;
  final TokenService _tokenService;
  late final FormValidationController _validation;

  AuthController({
    required AuthRepository authRepository,
    required TokenService tokenService,
  }) : _authRepository = authRepository,
       _tokenService = tokenService {
    // Resolve the shared FormValidationController via GetX so lifecycle hooks run
    _validation = Get.isRegistered<FormValidationController>()
        ? Get.find<FormValidationController>()
        : Get.put<FormValidationController>(FormValidationController());
  }

  final Rx<UserModel?> currentUser = Rx<UserModel?>(null);
  final RxBool isAuthenticated = false.obs;
  final RxBool isPasswordVisible = false.obs;
  final RxBool rememberMe = false.obs;
  final RxBool isTermsAccepted = false.obs;

  // Last-used auth method memory, surfaced for the login screen to pre-select.
  final RxnString lastMethod = RxnString();
  final RxnString lastIdentifierMasked = RxnString();

  // True while a Google Sign-In round-trip is in flight.
  final RxBool isGoogleLoading = false.obs;

  // True between launching the Google OAuth redirect and the deep-link callback
  // delivering a session (so the post-sign-in routing runs once, from the
  // auth-state listener).
  bool _pendingGoogleRedirect = false;

  // True while a native Sign in with Apple round-trip is in flight.
  final RxBool isAppleLoading = false.obs;

  // Whether Apple Sign-In is available on this device (iOS 13+); resolved
  // asynchronously on init so the login/signup screens can show the button.
  final RxBool isAppleSignInAvailable = false.obs;

  /// Whether native Google Sign-In is configured for this build.
  bool get isGoogleSignInConfigured => AppConfig.I.isGoogleSignInConfigured;

  // Local storage for remember-me preference
  late final GetStorage _authPrefs;
  Future<void>? _rememberMeReady;

  // Backwards-compat alias used by phone-based views
  RxString get phoneError => emailOrPhoneError;

  StreamSubscription<AuthState>? _authSubscription;

  @override
  void onInit() {
    super.onInit();

    // Initialize storage asynchronously (GetStorage requires init before use)
    unawaited(_ensureRememberMePreferenceReady());

    // Defer initial auth status check until TokenService has loaded tokens
    unawaited(_initAuthStatus());
    _bindAuthStateListener();

    // Resolve Apple Sign-In availability (iOS 13+) for the login UI.
    unawaited(_resolveAppleAvailability());
  }

  Future<void> _resolveAppleAvailability() async {
    try {
      final service = Get.isRegistered<AppleSignInService>()
          ? Get.find<AppleSignInService>()
          : Get.put<AppleSignInService>(AppleSignInService());
      isAppleSignInAvailable.value = await service.isAvailable();
    } catch (e) {
      AppLogger.warning('Apple availability resolve failed: $e');
      isAppleSignInAvailable.value = false;
    }
  }

  @override
  void onReady() {
    super.onReady();
    unawaited(_loadSavedUser());
  }

  @override
  void onClose() {
    _authSubscription?.cancel();
    super.onClose();
  }

  void togglePasswordVisibility() {
    isPasswordVisible.value = !isPasswordVisible.value;
  }

  RxString get emailOrPhoneError => _validation.emailOrPhoneError;
  RxString get passwordError => _validation.passwordError;
  RxString get confirmPasswordError => _validation.confirmPasswordError;

  Future<void> _initAuthStatus() async {
    try {
      // Wait for TokenService readiness so returning users aren't treated as logged out
      await _tokenService.ready;
    } catch (_) {
      // If readiness throws, proceed with best-effort check
    }
    await _checkAuthStatus();
  }

  Future<void> _checkAuthStatus() async {
    try {
      // Use TokenService for authentication status
      var tokenAuth = _tokenService.isAuthenticated.value;
      final repoAuth = await _authRepository.isAuthenticated();

      // If repository reports a valid session but TokenService hasn't caught up yet,
      // refresh TokenService from the active session to prevent false negatives.
      if (repoAuth && !tokenAuth) {
        await _updateTokenServiceFromCurrentSession();
        tokenAuth = _tokenService.isAuthenticated.value;
      }

      isAuthenticated.value = tokenAuth && repoAuth;
      AppLogger.info(
        isAuthenticated.value
            ? 'User is authenticated'
            : 'No valid tokens found. User needs to login.',
      );

      if (isAuthenticated.value) {
        // Proactively refresh profile so dependent screens can prefill
        unawaited(fetchAndCacheProfile());
      }
    } catch (e) {
      AppLogger.error('Auth check failed', e);
      isAuthenticated.value = false;
    }
  }

  Future<void> _loadSavedUser() async {
    try {
      final user = await _authRepository.getCurrentUser();
      if (user != null) {
        currentUser.value = user;
        AppLogger.info('Loaded saved user: ${user.email ?? user.phone}');
      }
    } catch (e) {
      AppLogger.error('Failed to load saved user', e);
    }
  }

  // Prepare the remember-me toggle with any value persisted from a previous run.
  Future<void> _initializeRememberMePreference() async {
    await GetStorage.init(_rememberMeBox);
    _authPrefs = GetStorage(_rememberMeBox);
    final storedPreference = _authPrefs.read<bool>(_rememberMeFlagKey) ?? false;
    rememberMe.value = storedPreference;
    // Surface the last-used method so the login screen can pre-select it.
    lastMethod.value = _authPrefs.read<String>(_lastMethodKey);
    lastIdentifierMasked.value = _authPrefs.read<String>(
      _lastIdentifierMaskedKey,
    );
    await _migrateLegacyRememberedTokens();
  }

  // Persist the last-used auth method + masked identifier (see AuthMethods).
  Future<void> _saveLastMethod(String method, {String? identifier}) async {
    if (!AuthMethods.isValid(method)) return;
    await _ensureRememberMePreferenceReady();
    lastMethod.value = method;
    await _authPrefs.write(_lastMethodKey, method);
    if (identifier != null && identifier.trim().isNotEmpty) {
      final masked = RememberMeService.maskIdentifier(identifier.trim());
      lastIdentifierMasked.value = masked;
      await _authPrefs.write(_lastIdentifierMaskedKey, masked);
    }
    // Mirror to the backend (best-effort, never blocks the UX).
    unawaited(_authRepository.recordLastMethod(method));
  }

  Future<void> _ensureRememberMePreferenceReady() async {
    _rememberMeReady ??= _initializeRememberMePreference();
    try {
      await _rememberMeReady;
    } catch (e) {
      // A failed future would otherwise persist forever, making every
      // subsequent call fail too. Reset so the next call retries, and
      // continue with defaults (rememberMe already false) this time.
      AppLogger.warning('Remember-me init failed, resetting for retry: $e');
      _rememberMeReady = null;
    }
  }

  void _bindAuthStateListener() {
    _authSubscription?.cancel();
    _authSubscription = trackSubscription(
      Supabase.instance.client.auth.onAuthStateChange.listen(
        (data) async {
          final event = data.event;
          final session = data.session;
          // SessionController is the single source of truth for session/token
          // persistence and the `isAuthenticated` observable on auth events.
          // This listener is intentionally narrow: it only completes a pending
          // Google OAuth-redirect sign-in, avoiding the sign-out race that
          // previously existed when both controllers cleared tokens.
          if (session == null) {
            return;
          }
          if (event == AuthChangeEvent.signedIn && _pendingGoogleRedirect) {
            _pendingGoogleRedirect = false;
            isGoogleLoading.value = false;
            await _completeGoogleSignIn(_userFromSession(session));
          }
        },
        onError: (Object error) {
          AppLogger.warning('Auth state listener error: $error');
        },
      ),
    );
  }

  // Update the remember-me flag and synchronise it to disk for future launches.
  Future<void> setRememberMe(bool value) async {
    await _ensureRememberMePreferenceReady();
    rememberMe.value = value;
    await _authPrefs.write(_rememberMeFlagKey, value);
    if (!value) {
      await _clearRememberedSession();
    }
  }

  // Persist the latest Supabase session details when the user opts in.
  Future<void> _persistRememberedSession({Session? session}) async {
    await _ensureRememberMePreferenceReady();
    // Tokens are already stored securely via TokenService/StorageService.
    // We only keep a boolean flag in GetStorage to control auto-login.
    await _authPrefs.write(_rememberMeFlagKey, true);
    await _clearLegacyRememberedSession();
  }

  // Drop any cached credentials when the user opts out or signs out.
  Future<void> _clearRememberedSession() async {
    await _ensureRememberMePreferenceReady();
    await _clearLegacyRememberedSession();
  }

  Future<void> _clearLegacyRememberedSession() async {
    await _authPrefs.remove(_rememberedAccessTokenKey);
    await _authPrefs.remove(_rememberedRefreshTokenKey);
  }

  Future<void> _migrateLegacyRememberedTokens() async {
    // If legacy plaintext tokens exist, migrate them to secure storage once.
    try {
      final legacyAccess = _authPrefs.read<String>(_rememberedAccessTokenKey);
      final legacyRefresh = _authPrefs.read<String>(_rememberedRefreshTokenKey);

      if ((legacyAccess == null || legacyAccess.isEmpty) &&
          (legacyRefresh == null || legacyRefresh.isEmpty)) {
        return;
      }

      if (rememberMe.value && legacyAccess != null && legacyAccess.isNotEmpty) {
        try {
          await _tokenService.ready;
          await _tokenService.storeTokens(
            accessToken: legacyAccess,
            refreshToken: legacyRefresh,
          );
          AppLogger.info(
            'Migrated legacy remember-me tokens to secure storage',
          );
        } catch (e) {
          // Fallback to StorageService if TokenService not ready yet
          if (Get.isRegistered<StorageService>()) {
            final storage = Get.find<StorageService>();
            await storage.saveTokens(
              accessToken: legacyAccess,
              refreshToken: legacyRefresh,
            );
          }
        }
      }
    } catch (e) {
      AppLogger.warning('Failed to migrate legacy remember-me tokens: $e');
    } finally {
      await _clearLegacyRememberedSession();
    }
  }

  // Centralised helper that applies the user's remember-me choice post-login.
  Future<void> _syncRememberMeStateAfterLogin() async {
    await _ensureRememberMePreferenceReady();
    if (rememberMe.value) {
      await _persistRememberedSession();
      return;
    }
    await _authPrefs.write(_rememberMeFlagKey, false);
    await _clearRememberedSession();
  }

  // Login with email or phone
  Future<void> login({required String email, required String password}) async {
    try {
      isLoading.value = true;

      _validation.clearErrors();

      final emailValidation = _validation.validateEmailOrPhone(email);
      final passwordValidation = _validation.validatePassword(password);
      if (emailValidation != null) {
        emailOrPhoneError.value = emailValidation;
        return;
      }
      if (passwordValidation != null) {
        passwordError.value = passwordValidation;
        return;
      }

      UserModel user;
      // Check if input is email or phone
      if (GetUtils.isEmail(email)) {
        user = await _authRepository.loginWithEmail(
          email: email,
          password: password,
        );
        if (Get.isRegistered<AnalyticsService>()) {
          Get.find<AnalyticsService>().logLogin('email');
        }
        await _saveLastMethod(AuthMethods.emailPassword, identifier: email);
      } else {
        user = await _authRepository.loginWithPhone(
          phone: email,
          password: password,
        );
        if (Get.isRegistered<AnalyticsService>()) {
          Get.find<AnalyticsService>().logLogin('phone');
        }
        await _saveLastMethod(AuthMethods.phonePassword, identifier: email);
      }

      currentUser.value = user;
      isAuthenticated.value = true;

      // Tokens already persisted via TokenService in repository

      final displayName =
          user.name ?? user.firstName ?? user.email ?? user.phone ?? 'User';
      _showSuccessSnackbar(
        title: 'Welcome Back!',
        message: 'Hello $displayName',
      );

      await _syncRememberMeStateAfterLogin();

      // Refresh full profile and cache for later prefilling
      unawaited(fetchAndCacheProfile());

      // Navigate based on backend gate evaluation
      await _navigatePostAuth();
    } on ApiException catch (e) {
      AppLogger.error('Login failed: ${e.message}', e);
      _handleApiError('Login Failed', e);
    } catch (e) {
      AppLogger.error('Login error', e);
      _showErrorSnackbar(
        title: 'Login Failed',
        message: 'An unexpected error occurred. Please try again.',
      );
    } finally {
      isLoading.value = false;
    }
  }

  // Phone-based login (if backend supports phone on same endpoint)
  Future<void> loginWithPhone({
    required String phone,
    required String password,
  }) async {
    // Delegate to the unified login path
    return login(email: phone, password: password);
  }

  // ---------------------------------------------------------------------------
  // Login state-machine: identifier -> status -> password | OTP-first
  // ---------------------------------------------------------------------------

  /// Resolves the next login step for [identifier] via the backend.
  /// Returns null on failure (caller should surface a snackbar / fall back).
  Future<IdentifierStatus?> checkIdentifierStatus(String identifier) async {
    try {
      isLoading.value = true;
      _validation.clearErrors();
      final validation = _validation.validateEmailOrPhone(identifier);
      if (validation != null) {
        emailOrPhoneError.value = validation;
        return null;
      }
      return await _authRepository.checkIdentifierStatus(identifier.trim());
    } on ApiException catch (e) {
      AppLogger.error('identifier-status failed: ${e.message}', e);
      _handleApiError('Sign In', e);
      return null;
    } catch (e) {
      AppLogger.error('identifier-status error', e);
      _showErrorSnackbar(
        title: 'Sign In',
        message: 'Unable to continue right now. Please try again.',
      );
      return null;
    } finally {
      isLoading.value = false;
    }
  }

  // ---------------------------------------------------------------------------
  // Google Sign-In (native ID-token flow OR Supabase OAuth redirect flow)
  // ---------------------------------------------------------------------------

  /// Google login. Uses the native ID-token flow when configured, otherwise the
  /// Supabase OAuth redirect flow (session arrives via onAuthStateChange).
  /// On success records last_auth_method=google and (when the account lacks a
  /// phone) routes to the skippable add-phone screen.
  Future<void> loginWithGoogle() async {
    try {
      isGoogleLoading.value = true;
      _pendingGoogleRedirect = false;
      final outcome = await _authRepository.signInWithGoogle();

      if (outcome.isCanceled) {
        // User canceled the picker, or the browser failed to launch.
        return;
      }

      if (outcome.isRedirect) {
        // Browser launched; the session will arrive via the deep-link callback
        // and onAuthStateChange. Keep the spinner running until then.
        _pendingGoogleRedirect = true;
        return;
      }

      // Native ID-token flow returned a session synchronously.
      await _completeGoogleSignIn(outcome.user!);
    } on ApiException catch (e) {
      AppLogger.error('Google login failed: ${e.message}', e);
      _handleApiError('Google Sign-In Failed', e);
    } catch (e) {
      AppLogger.error('Google login error', e);
      _showErrorSnackbar(
        title: 'Google Sign-In Failed',
        message: 'An unexpected error occurred. Please try again.',
      );
    } finally {
      // For the redirect flow, the spinner is cleared once the callback lands.
      if (!_pendingGoogleRedirect) {
        isGoogleLoading.value = false;
      }
    }
  }

  /// Shared post-Google routing for both the native and redirect flows:
  /// records last_auth_method=google, then routes to the skippable add-phone
  /// step (passwordless) or home.
  Future<void> _completeGoogleSignIn(UserModel user) async {
    currentUser.value = user;
    isAuthenticated.value = true;
    if (Get.isRegistered<AnalyticsService>()) {
      Get.find<AnalyticsService>().logLogin('google');
    }
    await _saveLastMethod(AuthMethods.google, identifier: user.email);
    await _syncRememberMeStateAfterLogin();
    unawaited(fetchAndCacheProfile());

    final displayName = user.name ?? user.firstName ?? user.email ?? 'there';
    _showSuccessSnackbar(
      title: 'Welcome!',
      message: 'Signed in as $displayName',
    );

    // Passwordless Google accounts: prompt (skippable) to add a phone.
    final hasPhone = (user.phone ?? '').trim().isNotEmpty;
    if (!hasPhone) {
      final otpController = Get.find<OTPController>();
      otpController.initializeOTP(type: OTPType.addPhone, phone: '');
      await Get.toNamed(Routes.verification);
      return;
    }

    await _navigatePostAuth();
  }

  // ---------------------------------------------------------------------------
  // Sign in with Apple (native ID-token flow, iOS)
  // ---------------------------------------------------------------------------

  /// Native Apple login. On success records last_auth_method=apple and (when
  /// the account lacks a phone) routes to the skippable add-phone screen.
  Future<void> loginWithApple() async {
    try {
      isAppleLoading.value = true;
      final user = await _authRepository.signInWithApple();
      if (user == null) {
        // User canceled the Apple credential sheet.
        return;
      }

      currentUser.value = user;
      isAuthenticated.value = true;
      if (Get.isRegistered<AnalyticsService>()) {
        Get.find<AnalyticsService>().logLogin('apple');
      }
      await _saveLastMethod(AuthMethods.apple, identifier: user.email);
      await _syncRememberMeStateAfterLogin();
      unawaited(fetchAndCacheProfile());

      final displayName = user.name ?? user.firstName ?? user.email ?? 'there';
      _showSuccessSnackbar(
        title: 'Welcome!',
        message: 'Signed in as $displayName',
      );

      // Passwordless Apple accounts: prompt (skippable) to add a phone.
      final hasPhone = (user.phone ?? '').trim().isNotEmpty;
      if (!hasPhone) {
        final otpController = Get.find<OTPController>();
        otpController.initializeOTP(type: OTPType.addPhone, phone: '');
        await Get.toNamed(Routes.verification);
        return;
      }

      await _navigatePostAuth();
    } on ApiException catch (e) {
      AppLogger.error('Apple login failed: ${e.message}', e);
      _handleApiError('Apple Sign-In Failed', e);
    } catch (e) {
      AppLogger.error('Apple login error', e);
      _showErrorSnackbar(
        title: 'Apple Sign-In Failed',
        message: 'An unexpected error occurred. Please try again.',
      );
    } finally {
      isAppleLoading.value = false;
    }
  }

  // ---------------------------------------------------------------------------
  // Email OTP (6-digit, type: email)
  // ---------------------------------------------------------------------------

  /// Sends a 6-digit email OTP. Returns true if the request succeeded.
  ///
  /// [shouldCreateUser] must be `false` for the login OTP-first path and for
  /// password reset (so an unknown/mistyped email is not silently registered);
  /// only the signup path passes `true`.
  Future<bool> sendEmailOtp(
    String email, {
    bool shouldCreateUser = false,
  }) async {
    try {
      isLoading.value = true;
      await _authRepository.sendEmailOtp(
        email: email.trim(),
        shouldCreateUser: shouldCreateUser,
      );
      _showSuccessSnackbar(
        title: 'Code Sent',
        message: 'We sent a 6-digit code to $email',
      );
      return true;
    } on ApiException catch (e) {
      _handleApiError('Could Not Send Code', e);
      return false;
    } catch (e) {
      _showErrorSnackbar(
        title: 'Could Not Send Code',
        message: 'Unable to send the code right now.',
      );
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  /// Verifies an email OTP and establishes a session. Returns the user or null.
  Future<UserModel?> verifyEmailOtp({
    required String email,
    required String token,
  }) async {
    final user = await _authRepository.verifyEmailOtp(
      email: email.trim(),
      token: token,
    );
    currentUser.value = user;
    isAuthenticated.value = true;
    if (Get.isRegistered<AnalyticsService>()) {
      Get.find<AnalyticsService>().logLogin('email_otp');
    }
    await _saveLastMethod(AuthMethods.emailOtp, identifier: email);
    await _syncRememberMeStateAfterLogin();
    unawaited(fetchAndCacheProfile());
    return user;
  }

  Future<void> resendEmailOtp(String email, {bool shouldCreateUser = false}) =>
      _authRepository.resendEmailOtp(
        email: email.trim(),
        shouldCreateUser: shouldCreateUser,
      );

  // ---------------------------------------------------------------------------
  // Add + verify phone (for Google / passwordless accounts)
  // ---------------------------------------------------------------------------

  /// Attaches a phone to the current account and triggers a verification SMS.
  Future<bool> addPhone(String phone) async {
    try {
      await _authRepository.addPhone(phone: phone.trim());
      return true;
    } on ApiException catch (e) {
      _handleApiError('Could Not Add Phone', e);
      return false;
    } catch (e) {
      _showErrorSnackbar(
        title: 'Could Not Add Phone',
        message: 'Unable to add this phone number right now.',
      );
      return false;
    }
  }

  /// Verifies the phone-change OTP, completing the add-phone flow.
  Future<UserModel?> verifyAddPhoneOtp({
    required String phone,
    required String token,
  }) async {
    final user = await _authRepository.verifyPhoneChangeOtp(
      phone: phone.trim(),
      token: token,
    );
    currentUser.value = user;
    unawaited(fetchAndCacheProfile());
    return user;
  }

  // ---------------------------------------------------------------------------
  // Mandatory set-password after OTP (requirement 6)
  // ---------------------------------------------------------------------------

  /// The method to record once the mandatory password is set
  /// (email_password / phone_password).
  String _pendingSetPasswordMethod = AuthMethods.emailPassword;
  String? _pendingSetPasswordIdentifier;

  /// Masked form of the identifier the mandatory set-password step is for
  /// (e.g. `j***@gmail.com`, `+91 98****10`), for display on that screen.
  /// Null when no identifier was captured.
  String? get pendingSetPasswordMaskedIdentifier {
    final id = _pendingSetPasswordIdentifier;
    if (id == null || id.trim().isEmpty) return null;
    return RememberMeService.maskIdentifier(id.trim());
  }

  /// Routes to the non-skippable set-password screen after a passwordless OTP
  /// verify. [method] is the final last_auth_method to record on success.
  void startMandatorySetPassword({required String method, String? identifier}) {
    _pendingSetPasswordMethod = method;
    _pendingSetPasswordIdentifier = identifier;
    // offNamed so the user can't navigate back to the OTP screen.
    unawaited(Get.offNamed(Routes.setPassword));
  }

  /// Completes the mandatory set-password step: validates, calls
  /// updatePassword, records the password-based last_auth_method, then enters
  /// the app. Returns true on success.
  Future<bool> setPasswordAfterOtp({
    required String password,
    required String confirmPassword,
  }) async {
    try {
      isLoading.value = true;
      _validation.clearErrors();

      final passwordValidation = _validation.validatePassword(password);
      final confirmValidation = _validation.validateConfirmPassword(
        password,
        confirmPassword,
      );
      if (passwordValidation != null) {
        passwordError.value = passwordValidation;
        return false;
      }
      if (confirmValidation != null) {
        confirmPasswordError.value = confirmValidation;
        return false;
      }

      await _authRepository.updatePassword(newPassword: password);

      await _saveLastMethod(
        _pendingSetPasswordMethod,
        identifier: _pendingSetPasswordIdentifier,
      );
      await _syncRememberMeStateAfterLogin();
      unawaited(fetchAndCacheProfile());

      _showSuccessSnackbar(
        title: 'All Set!',
        message: 'Your password has been set.',
      );
      await _navigatePostAuth();
      return true;
    } on ApiException catch (e) {
      _handleApiError('Could Not Set Password', e);
      return false;
    } catch (e) {
      AppLogger.error('Set password failed', e);
      _showErrorSnackbar(
        title: 'Could Not Set Password',
        message: 'Unable to set your password right now. Please try again.',
      );
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  // Fetch latest profile from API, update observable and cache for fast prefill
  Future<UserModel?> fetchAndCacheProfile() async {
    try {
      final repo = _ensureProfileRepository();
      final profile = await repo.getProfile();
      currentUser.value = profile;
      if (Get.isRegistered<StorageService>()) {
        final storage = Get.find<StorageService>();
        await storage.saveUserData(profile.toMap());
      }
      AppLogger.info('Profile refreshed for ${profile.email ?? profile.phone}');
      return profile;
    } catch (e) {
      AppLogger.warning('Failed to refresh user profile: $e');
      return null;
    }
  }

  // ── Post-auth gate evaluation ──────────────────────────────────────────
  // Calls GET /users/me/auth-state?app=stays and routes to the appropriate
  // screen.  This is the single source of truth for gate evaluation.

  /// Fetch the auth gate state from the backend.
  Future<Map<String, dynamic>?> _fetchAuthGateState() async {
    try {
      return await _authRepository.getAuthGateState(app: 'stays');
    } catch (e) {
      AppLogger.warning('Failed to fetch auth gate state: $e');
      return null;
    }
  }

  /// Navigate to the appropriate screen based on the backend gate state.
  /// Falls back to home if the gate endpoint fails.
  Future<void> _navigatePostAuth() async {
    final gateState = await _fetchAuthGateState();
    if (gateState == null) {
      // Fallback: go to home if gate endpoint fails.
      await Get.offAllNamed(Routes.home);
      return;
    }

    final stage = gateState['stage'] as String? ?? 'active';
    AppLogger.info('Auth gate stage: $stage');

    switch (stage) {
      case 'identifier_verification':
        // Shouldn't happen post-login.
        await Get.offAllNamed(Routes.home);
        break;
      case 'password_setup':
        await Get.offAllNamed(Routes.setPassword);
        break;
      case 'profile_completion':
        await Get.offAllNamed(Routes.profileCompletion);
        break;
      case 'app_onboarding':
        await Get.offAllNamed(Routes.onboarding);
        break;
      case 'active':
        await Get.offAllNamed(Routes.home);
        break;
      default:
        await Get.offAllNamed(Routes.home);
    }
  }

  // Phone signup via Supabase: sends OTP for first-time validation
  Future<bool> registerWithPhone({
    required String phone,
    required String password,
    String? fullName,
    String? email,
  }) async {
    try {
      isLoading.value = true;
      final phoneValidation = _validation.validateEmailOrPhone(phone);
      final passwordValidation = _validation.validatePassword(password);
      if (phoneValidation != null) {
        emailOrPhoneError.value = phoneValidation;
        return false;
      }
      if (passwordValidation != null) {
        passwordError.value = passwordValidation;
        return false;
      }

      // Build optional user metadata map
      final Map<String, String>? data = () {
        final map = <String, String>{};
        if (fullName != null && fullName.trim().isNotEmpty) {
          map['full_name'] = fullName.trim();
        }
        if (email != null && email.trim().isNotEmpty) {
          map['email'] = email.trim();
        }
        return map.isNotEmpty ? map : null;
      }();

      final sent = await _authRepository.signUpWithPhone(
        phone: phone,
        password: password,
        data: data,
      );
      if (sent) {
        _showSuccessSnackbar(
          title: 'OTP Sent',
          message: 'We have sent an OTP to ${_formatPhoneForDisplay(phone)}',
        );
      }
      return sent;
    } on ApiException catch (e) {
      _showErrorSnackbar(title: 'Signup Failed', message: e.message);
      return false;
    } catch (e) {
      _showErrorSnackbar(
        title: 'Signup Failed',
        message: 'Unable to sign up right now.',
      );
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  static const _noAccountFoundMessage =
      'No account found with this email or phone. Check the address or sign up.';

  /// UX-first exists probe before sending a reset OTP (decision: reveal via
  /// identifier-status, not anti-enumeration).
  Future<bool> _ensureAccountExistsForReset(String identifier) async {
    try {
      final status = await _authRepository.checkIdentifierStatus(
        identifier.trim(),
      );
      if (!status.exists) {
        emailOrPhoneError.value = _noAccountFoundMessage;
        return false;
      }
      return true;
    } on ApiException catch (e) {
      _handleApiError('Forgot Password', e);
      return false;
    } catch (e) {
      AppLogger.error('identifier-status failed during forgot-password', e);
      _showErrorSnackbar(
        title: 'Forgot Password',
        message:
            "Can't reach the server to verify your account. Check your connection and try again.",
      );
      return false;
    }
  }

  /// Sends a phone OTP for the forgot-password flow via Supabase.
  /// Uses `signInWithOtp` with `shouldCreateUser: false` so only existing
  /// accounts can receive a code.
  Future<bool> sendForgotPasswordOTP(String phone) async {
    final validation = _validation.validateEmailOrPhone(phone);
    if (validation != null) {
      emailOrPhoneError.value = validation;
      return false;
    }
    try {
      isLoading.value = true;
      final formattedPhone = phone.startsWith('+') ? phone : '+91$phone';
      if (!await _ensureAccountExistsForReset(formattedPhone)) return false;
      await Supabase.instance.client.auth.signInWithOtp(
        phone: formattedPhone,
        shouldCreateUser: false,
      );
      _showSuccessSnackbar(
        title: 'OTP Sent',
        message:
            'We have sent a verification code to ${_formatPhoneForDisplay(phone)}',
      );
      return true;
    } on ApiException catch (e) {
      _handleApiError('Forgot Password', e);
      return false;
    } catch (e) {
      AppLogger.error('Forgot password OTP failed', e);
      _showErrorSnackbar(
        title: 'Failed to Send OTP',
        message: 'Unable to send verification code. Please try again.',
      );
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  /// Sends an email OTP for the forgot-password flow via Supabase.
  /// Uses `shouldCreateUser: false` so only existing accounts can receive a
  /// code (mirrors the phone reset channel — decision 1: OTP for both).
  Future<bool> sendForgotPasswordEmailOtp(String email) async {
    final trimmed = email.trim();
    if (!GetUtils.isEmail(trimmed)) {
      emailOrPhoneError.value = 'Please enter a valid email address';
      return false;
    }
    try {
      isLoading.value = true;
      if (!await _ensureAccountExistsForReset(trimmed)) return false;
      await _authRepository.sendEmailOtp(
        email: trimmed,
        shouldCreateUser: false,
      );
      _showSuccessSnackbar(
        title: 'Code Sent',
        message: 'We sent a 6-digit code to $trimmed',
      );
      return true;
    } on ApiException catch (e) {
      _handleApiError('Forgot Password', e);
      return false;
    } catch (e) {
      AppLogger.error('Forgot password email OTP failed', e);
      _showErrorSnackbar(
        title: 'Failed to Send Code',
        message: 'Unable to send verification code. Please try again.',
      );
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  /// Verifies the phone OTP for the forgot-password flow. After successful
  /// verification the user has a valid Supabase session, allowing an immediate
  /// call to [resetPassword].
  Future<bool> verifyForgotPasswordOtp({
    required String phone,
    required String otp,
  }) async {
    try {
      isLoading.value = true;
      final formattedPhone = phone.startsWith('+') ? phone : '+91$phone';
      await Supabase.instance.client.auth.verifyOTP(
        phone: formattedPhone,
        token: otp,
        type: OtpType.sms,
      );
      return true;
    } catch (e) {
      AppLogger.error('Forgot password OTP verification failed', e);
      _showErrorSnackbar(
        title: 'Verification Failed',
        message: 'Invalid or expired OTP. Please try again.',
      );
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  /// Resets the user's password after a successful forgot-password OTP
  /// verification. Requires an active Supabase session (established by the
  /// OTP verify step).
  Future<void> resetPassword({
    required String newPassword,
    required String confirmPassword,
  }) async {
    final passwordValidation = _validation.validatePassword(newPassword);
    final confirmValidation = _validation.validateConfirmPassword(
      newPassword,
      confirmPassword,
    );
    if (passwordValidation != null) {
      passwordError.value = passwordValidation;
      return;
    }
    if (confirmValidation != null) {
      confirmPasswordError.value = confirmValidation;
      return;
    }
    try {
      isLoading.value = true;
      await _authRepository.updatePassword(newPassword: newPassword);
      _showSuccessSnackbar(
        title: 'Password Reset',
        message: 'Your password has been reset successfully.',
      );
      await Get.offAllNamed(Routes.login);
    } on ApiException catch (e) {
      _handleApiError('Reset Password', e);
    } catch (e) {
      AppLogger.error('Reset password failed', e);
      _showErrorSnackbar(
        title: 'Reset Failed',
        message: 'Unable to reset your password. Please try again.',
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> logout() async {
    try {
      isLoading.value = true;
      await _authRepository.logout();
      // Clear tokens from TokenService as well
      await _tokenService.clearTokens();
      await setRememberMe(false);
      currentUser.value = null;
      isAuthenticated.value = false;

      // Reset form/UI state before navigating so login screen starts enabled
      emailOrPhoneError.value = '';
      passwordError.value = '';
      confirmPasswordError.value = '';
      isPasswordVisible.value = false;
      isLoading.value = false;

      _showSuccessSnackbar(
        title: 'Logged Out',
        message: 'You have been successfully logged out.',
      );
      if (Get.isRegistered<AnalyticsService>()) {
        Get.find<AnalyticsService>().logLogout();
      }

      // Navigate to login after local state is reset
      await Get.offAllNamed(Routes.login);
    } catch (e) {
      AppLogger.error('Logout failed', e);
      _showErrorSnackbar(
        title: 'Logout Failed',
        message: 'Failed to logout properly.',
      );
    } finally {
      // Ensure loading is not stuck true in any race condition
      isLoading.value = false;
    }
  }

  Future<void> register({
    String? name,
    String? firstName,
    String? lastName,
    required String email,
    required String password,
    String? confirmPassword,
  }) async {
    try {
      isLoading.value = true;

      _validation.clearErrors();

      final emailValidation = _validation.validateEmailOrPhone(email);
      final passwordValidation = _validation.validatePassword(password);
      final confirmValidation = _validation.validateConfirmPassword(
        password,
        confirmPassword ?? password,
      );
      if (emailValidation != null) {
        emailOrPhoneError.value = emailValidation;
        return;
      }
      if (passwordValidation != null) {
        passwordError.value = passwordValidation;
        return;
      }
      if (confirmValidation != null) {
        confirmPasswordError.value = confirmValidation;
        return;
      }

      // Build a sensible full name for backend
      final computedName = () {
        final n = name;
        if (n != null && n.trim().isNotEmpty) return n.trim();
        final parts = <String>[];
        final fn = firstName;
        final ln = lastName;
        if ((fn ?? '').trim().isNotEmpty) parts.add(fn!.trim());
        if ((ln ?? '').trim().isNotEmpty) parts.add(ln!.trim());
        if (parts.isNotEmpty) return parts.join(' ');
        // Fallback: use email username
        final at = email.indexOf('@');
        return at > 0 ? email.substring(0, at) : email;
      }();

      final user = await _authRepository.register(
        name: computedName,
        email: email,
        password: password,
      );
      currentUser.value = user;
      isAuthenticated.value = true;
      if (Get.isRegistered<AnalyticsService>()) {
        Get.find<AnalyticsService>().logSignup('email');
      }

      // Tokens already persisted via TokenService in repository

      _showSuccessSnackbar(
        title: 'Welcome!',
        message:
            'Account created, logged in as ${user.firstName ?? user.email}',
      );
      unawaited(_navigatePostAuth());
    } on ApiException catch (e) {
      _showErrorSnackbar(title: 'Registration Failed', message: e.message);
    } catch (e) {
      _showErrorSnackbar(
        title: 'Error',
        message: 'An error occurred. Please try again.',
      );
    } finally {
      isLoading.value = false;
    }
  }

  // Sync TokenService state from a provided Supabase session
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

  // Sync TokenService using the current Supabase session if available
  Future<void> _updateTokenServiceFromCurrentSession() async {
    final session = Supabase.instance.client.auth.currentSession;
    if (session != null) {
      await _updateTokenServiceFromSession(session);
    }
  }

  // Map a Supabase session user to a UserModel (used by the OAuth redirect
  // flow, where no provider result is returned synchronously). The full
  // profile is refreshed from the backend right after via fetchAndCacheProfile.
  UserModel _userFromSession(Session session) {
    final user = session.user;
    final meta = user.userMetadata ?? const <String, dynamic>{};
    return UserModel(
      id: user.id,
      email: user.email,
      phone: user.phone,
      firstName: meta['first_name'] as String?,
      lastName: meta['last_name'] as String?,
      name: (meta['full_name'] as String?) ?? (meta['name'] as String?),
    );
  }

  /// Formats a phone number for display in user-facing messages, preserving
  /// the user's actual country code rather than hardcoding +91. When no
  /// country code is present, the default Indian code (+91) is used to match
  /// the value actually sent to Supabase.
  String _formatPhoneForDisplay(String phone) {
    final trimmed = phone.trim();
    if (trimmed.isEmpty) return trimmed;
    if (trimmed.startsWith('+')) return trimmed;
    return '+91$trimmed';
  }

  ProfileRepository _ensureProfileRepository() {
    if (Get.isRegistered<ProfileRepository>()) {
      return Get.find<ProfileRepository>();
    }
    if (!Get.isRegistered<UsersProvider>()) {
      Get.put<UsersProvider>(UsersProvider());
    }
    final repo = ProfileRepository(provider: Get.find<UsersProvider>());
    Get.put<ProfileRepository>(repo);
    return repo;
  }

  Future<UserModel?> updateUserProfileData({
    String? firstName,
    String? lastName,
    String? fullName,
    String? bio,
    String? phone,
    DateTime? dateOfBirth,
    String? avatarUrl,
    String? agentId,
  }) async {
    try {
      final repo = _ensureProfileRepository();
      final updated = await repo.updateProfile(
        firstName: firstName,
        lastName: lastName,
        fullName: fullName,
        bio: bio,
        phone: phone,
        dateOfBirth: dateOfBirth,
        avatarUrl: avatarUrl,
        agentId: agentId,
      );
      currentUser.value = updated;
      return updated;
    } catch (e, stack) {
      AppLogger.error('Failed to update user profile', e, stack);
      rethrow;
    }
  }

  Future<UserModel?> updateUserPreferences(
    Map<String, dynamic> preferences,
  ) async {
    try {
      final repo = _ensureProfileRepository();
      final updated = await repo.updatePreferences(preferences);
      currentUser.value = updated;
      return updated;
    } catch (e, stack) {
      AppLogger.error('Failed to update user preferences', e, stack);
      rethrow;
    }
  }

  Future<UserModel?> updateUserLocation({
    required double latitude,
    required double longitude,
    bool shareLocation = true,
  }) async {
    try {
      final repo = _ensureProfileRepository();
      final updated = await repo.updateLocation(
        latitude: latitude,
        longitude: longitude,
        shareLocation: shareLocation,
      );
      currentUser.value = updated;
      return updated;
    } catch (e, stack) {
      AppLogger.error('Failed to update user location', e, stack);
      rethrow;
    }
  }

  void _showSuccessSnackbar({required String title, required String message}) {
    AppSnackbar.success(title: title, message: message);
  }

  void _handleApiError(String title, ApiException e) {
    final lower = e.message.toLowerCase();
    if (lower.contains('email not confirmed') ||
        lower.contains('phone not confirmed') ||
        lower.contains('user not confirmed')) {
      _showErrorSnackbar(
        title: title,
        message:
            'Please verify your account before signing in. We can send you a new code.',
      );
      return;
    }

    String message;
    switch (e.statusCode) {
      case 401:
        message =
            'Invalid credentials. Please check your email/phone and password.';
        break;
      case 404:
        message =
            'Account not found. Please check your credentials or sign up.';
        break;
      case 422:
        message = 'Invalid input. Please check your information and try again.';
        break;
      case 429:
        message = 'Too many attempts. Please try again later.';
        break;
      case 500:
        message = 'Server error. Please try again later.';
        break;
      default:
        message = e.message.isNotEmpty
            ? e.message
            : 'An error occurred. Please try again.';
    }
    _showErrorSnackbar(title: title, message: message);
  }

  void _showErrorSnackbar({required String title, required String message}) {
    AppSnackbar.error(title: title, message: message);
  }
}
