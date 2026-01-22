import 'dart:async';

import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:stays_app/app/data/repositories/auth_repository.dart';
import 'package:stays_app/app/data/models/user_model.dart';
import 'package:stays_app/app/routes/app_routes.dart';
import 'package:stays_app/app/utils/logger/app_logger.dart';
import 'package:stays_app/app/utils/exceptions/app_exceptions.dart';
import 'package:stays_app/app/data/repositories/profile_repository.dart';
import 'package:stays_app/app/data/providers/users_provider.dart';
import 'package:stays_app/app/data/services/storage_service.dart';
import 'package:stays_app/app/utils/services/token_service.dart';
import 'package:stays_app/app/utils/helpers/app_snackbar.dart';
import 'package:stays_app/app/controllers/base/base_controller.dart';
import 'package:stays_app/app/data/services/analytics_service.dart';
import 'form_validation_controller.dart';

class AuthController extends BaseController {
  // Storage keys dedicated to the remember-me preference and cached tokens.
  static const String _rememberMeBox = 'auth_preferences';
  static const String _rememberMeFlagKey = 'remember_me';
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

  // Local storage for remember-me preference
  late final GetStorage _authPrefs;

  // Backwards-compat alias used by phone-based views
  RxString get phoneError => emailOrPhoneError;

  StreamSubscription<AuthState>? _authSubscription;

  @override
  void onInit() {
    super.onInit();

    // Initialize storage asynchronously (GetStorage requires init before use)
    unawaited(_initializeRememberMePreference());

    // Defer initial auth status check until TokenService has loaded tokens
    _initAuthStatus();
    _bindAuthStateListener();
  }

  @override
  void onReady() {
    super.onReady();
    unawaited(_loadSavedUser());
    // Attempt to refresh profile details once ready
    if (isAuthenticated.value) {
      // fire-and-forget; UI will react when currentUser updates
      unawaited(fetchAndCacheProfile());
    }
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
    await _migrateLegacyRememberedTokens();
  }

  void _bindAuthStateListener() {
    _authSubscription?.cancel();
    _authSubscription = trackSubscription(
      Supabase.instance.client.auth.onAuthStateChange.listen(
        (data) async {
          final event = data.event;
          final session = data.session;
          if (event == AuthChangeEvent.signedOut) {
            // Keep TokenService in sync on sign-out events
            await _tokenService.clearTokens();
            await _clearRememberedSession();
            return;
          }
          if (session == null) {
            return;
          }
          if (event == AuthChangeEvent.signedIn ||
              event == AuthChangeEvent.tokenRefreshed) {
            // Update TokenService with latest tokens so late-bound controllers see auth state
            await _updateTokenServiceFromSession(session);
            // Only persist to local remember-me storage if opted in
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

  // Update the remember-me flag and synchronise it to disk for future launches.
  Future<void> setRememberMe(bool value) async {
    rememberMe.value = value;
    await _authPrefs.write(_rememberMeFlagKey, value);
    if (!value) {
      await _clearRememberedSession();
    }
  }

  // Persist the latest Supabase session details when the user opts in.
  Future<void> _persistRememberedSession({Session? session}) async {
    // Tokens are already stored securely via TokenService/StorageService.
    // We only keep a boolean flag in GetStorage to control auto-login.
    await _authPrefs.write(_rememberMeFlagKey, true);
    await _clearLegacyRememberedSession();
  }

  // Drop any cached credentials when the user opts out or signs out.
  Future<void> _clearRememberedSession() async {
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
          AppLogger.info('Migrated legacy remember-me tokens to secure storage');
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
      } else {
        user = await _authRepository.loginWithPhone(
          phone: email,
          password: password,
        );
        if (Get.isRegistered<AnalyticsService>()) {
          Get.find<AnalyticsService>().logLogin('phone');
        }
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

      // Navigate to home
      await Get.offAllNamed(Routes.home);
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

  // Phone signup via Supabase: sends OTP for first-time validation
  Future<bool> registerWithPhone({
    required String phone,
    required String password,
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

      final sent = await _authRepository.signUpWithPhone(
        phone: phone,
        password: password,
      );
      if (sent) {
        _showSuccessSnackbar(
          title: 'OTP Sent',
          message: 'We have sent an OTP to +91 $phone',
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

  // Backwards-compat: the current UI triggers an OTP flow for forgot password.
  // Provide a graceful error until a backend endpoint is available.
  Future<bool> sendForgotPasswordOTP(String phone) async {
    final validation = _validation.validateEmailOrPhone(phone);
    if (validation != null) {
      emailOrPhoneError.value = validation;
      return false;
    }
    _showErrorSnackbar(
      title: 'Not Supported',
      message: 'Forgot password via phone OTP is not supported.',
    );
    return false;
  }

  // Backwards-compat stub, replace with real backend call when available
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
    _showErrorSnackbar(
      title: 'Not Supported',
      message: 'Password reset via OTP is not supported.',
    );
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
      unawaited(Get.offAllNamed(Routes.home));
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
