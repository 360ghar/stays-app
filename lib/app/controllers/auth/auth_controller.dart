import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../data/repositories/auth_repository.dart';
import '../../data/models/user_model.dart';
import '../../routes/app_routes.dart';
import '../../utils/logger/app_logger.dart';
import '../../utils/exceptions/app_exceptions.dart';
import '../../data/repositories/profile_repository.dart';
import '../../data/providers/users_provider.dart';

class AuthController extends GetxController {
  // Storage keys dedicated to the remember-me preference and cached tokens.
  static const String _rememberMeBox = 'auth_preferences';
  static const String _rememberMeFlagKey = 'remember_me';
  static const String _rememberedAccessTokenKey = 'remembered_access_token';
  static const String _rememberedRefreshTokenKey = 'remembered_refresh_token';

  final AuthRepository _authRepository;

  AuthController({required AuthRepository authRepository})
    : _authRepository = authRepository;

  // Local storage handle used to persist remember-me selection and tokens.
  late final GetStorage _authPrefs;

  final Rx<UserModel?> currentUser = Rx<UserModel?>(null);
  final RxBool isLoading = false.obs;
  final RxBool isAuthenticated = false.obs;
  final RxBool isPasswordVisible = false.obs;
  final RxBool rememberMe = false.obs;

  // Form validation observables
  final RxString emailOrPhoneError = ''.obs;
  final RxString passwordError = ''.obs;
  final RxString confirmPasswordError = ''.obs;

  // Backwards-compat alias used by phone-based views
  RxString get phoneError => emailOrPhoneError;

  StreamSubscription<AuthState>? _authSubscription;

  @override
  void onInit() {
    super.onInit();
    _initializeRememberMePreference();
    _checkAuthStatus();
    _bindAuthStateListener();
  }

  @override
  void onReady() {
    super.onReady();
    _loadSavedUser();
  }

  @override
  void onClose() {
    _authSubscription?.cancel();
    super.onClose();
  }

  void togglePasswordVisibility() {
    isPasswordVisible.value = !isPasswordVisible.value;
  }

  String? _validateEmailOrPhone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Email or phone is required';
    }
    return null;
  }

  String? _validatePassword(String? password) {
    if (password == null || password.isEmpty) {
      return 'Password is required';
    }
    if (password.length < 6) {
      return 'Password must be at least 6 characters';
    }
    return null;
  }

  String? _validateConfirmPassword(String? password, String? confirmPassword) {
    if (confirmPassword == null || confirmPassword.isEmpty) {
      return 'Please confirm your password';
    }
    if (password != confirmPassword) {
      return 'Passwords do not match';
    }
    return null;
  }

  Future<void> _checkAuthStatus() async {
    try {
      final isAuth = await _authRepository.isAuthenticated();
      isAuthenticated.value = isAuth;
      AppLogger.info(
        isAuth
            ? 'User is authenticated'
            : 'No token found. Navigating to login.',
      );
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
  void _initializeRememberMePreference() {
    _authPrefs = GetStorage(_rememberMeBox);
    final storedPreference =
        _authPrefs.read<bool>(_rememberMeFlagKey) ?? false;
    rememberMe.value = storedPreference;
  }

  void _bindAuthStateListener() {
    _authSubscription?.cancel();
    _authSubscription =
        Supabase.instance.client.auth.onAuthStateChange.listen(
      (data) async {
        final event = data.event;
        final session = data.session;
        if (event == AuthChangeEvent.signedOut) {
          await _clearRememberedSession();
          return;
        }
        if (!rememberMe.value || session == null) {
          return;
        }
        if (event == AuthChangeEvent.signedIn ||
            event == AuthChangeEvent.tokenRefreshed) {
          await _persistRememberedSession(session: session);
        }
      },
      onError: (Object error) {
        AppLogger.warning('Auth state listener error: $error');
      },
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
    final activeSession =
        session ?? Supabase.instance.client.auth.currentSession;
    if (activeSession == null) {
      AppLogger.warning(
        'Unable to persist remember-me session because Supabase returned no session.',
      );
      return;
    }
    await _authPrefs.write(_rememberMeFlagKey, true);
    await _authPrefs.write(_rememberedAccessTokenKey, activeSession.accessToken);
    final refreshToken = activeSession.refreshToken;
    if (refreshToken != null && refreshToken.isNotEmpty) {
      await _authPrefs.write(_rememberedRefreshTokenKey, refreshToken);
    }
  }

  // Drop any cached credentials when the user opts out or signs out.
  Future<void> _clearRememberedSession() async {
    await _authPrefs.remove(_rememberedAccessTokenKey);
    await _authPrefs.remove(_rememberedRefreshTokenKey);
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

      emailOrPhoneError.value = '';
      passwordError.value = '';

      final emailValidation = _validateEmailOrPhone(email);
      final passwordValidation = _validatePassword(password);
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
      } else {
        user = await _authRepository.loginWithPhone(
          phone: email,
          password: password,
        );
      }

      currentUser.value = user;
      isAuthenticated.value = true;

      final displayName =
          user.name ?? user.firstName ?? user.email ?? user.phone ?? 'User';
      _showSuccessSnackbar(
        title: 'Welcome Back!',
        message: 'Hello $displayName',
      );

      await _syncRememberMeStateAfterLogin();

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
    AppLogger.info('Attempting to log in with phone: $phone');
    try {
      isLoading.value = true;

      // --- Validation logic ---
      emailOrPhoneError.value = '';
      passwordError.value = '';
      final phoneValidation = _validateEmailOrPhone(phone);
      final passwordValidation = _validatePassword(password);
      if (phoneValidation != null) {
        emailOrPhoneError.value = phoneValidation;
        isLoading.value = false; // Stop loading on validation fail
        return;
      }
      if (passwordValidation != null) {
        passwordError.value = passwordValidation;
        isLoading.value = false; // Stop loading on validation fail
        return;
      }
      // --- End of validation ---

      final user = await _authRepository.loginWithPhone(
        phone: phone,
        password: password,
      );
      currentUser.value = user;
      isAuthenticated.value = true;

      AppLogger.info(
        'Login successful for user: ${user.name ?? user.firstName ?? user.phone}',
      );

      await _syncRememberMeStateAfterLogin();

      _showSuccessSnackbar(
        title: 'Welcome Back!',
        message: 'Hello ${user.name ?? user.firstName ?? user.phone}',
      );
      Get.offAllNamed(Routes.home);
    } catch (e, stackTrace) {
      // Corrected logging for AppLogger
      AppLogger.error('LOGIN FAILED!', e, stackTrace);

      // Show the actual error message from the server
      String errorMessage = e.toString();
      if (e is ApiException) {
        errorMessage =
            e.message; // Use the specific message from your custom exception
      }

      _showErrorSnackbar(title: 'Login Failed', message: errorMessage);
    } finally {
      AppLogger.info('Login process finished. Setting isLoading to false.');
      isLoading.value = false;
    }
  }

  // Phone signup via Supabase: sends OTP for first-time validation
  Future<bool> registerWithPhone({
    required String phone,
    required String password,
  }) async {
    try {
      isLoading.value = true;
      final phoneValidation = _validateEmailOrPhone(phone);
      final passwordValidation = _validatePassword(password);
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
    final validation = _validateEmailOrPhone(phone);
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
    final passwordValidation = _validatePassword(newPassword);
    final confirmValidation = _validateConfirmPassword(
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

      emailOrPhoneError.value = '';
      passwordError.value = '';
      confirmPasswordError.value = '';

      final emailValidation = _validateEmailOrPhone(email);
      final passwordValidation = _validatePassword(password);
      final confirmValidation = _validateConfirmPassword(
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

      _showSuccessSnackbar(
        title: 'Welcome!',
        message:
            'Account created, logged in as ${user.firstName ?? user.email}',
      );
      Get.offAllNamed(Routes.home);
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
    Get.snackbar(
      '',
      '',
      titleText: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 18,
        ),
      ),
      messageText: Text(
        message,
        style: const TextStyle(color: Colors.white70, fontSize: 14),
      ),
      backgroundColor: const Color(0xFF4CAF50).withValues(alpha: 0.9),
      borderRadius: 16,
      margin: const EdgeInsets.all(16),
      duration: const Duration(seconds: 3),
      animationDuration: const Duration(milliseconds: 500),
      snackPosition: SnackPosition.TOP,
      icon: Container(
        padding: const EdgeInsets.all(8),
        decoration: const BoxDecoration(
          color: Colors.white24,
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.check_circle, color: Colors.white, size: 24),
      ),
    );
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
        message =
            e.message.isNotEmpty
                ? e.message
                : 'An error occurred. Please try again.';
    }
    _showErrorSnackbar(title: title, message: message);
  }

  void _showErrorSnackbar({required String title, required String message}) {
    Get.snackbar(
      '',
      '',
      titleText: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 18,
        ),
      ),
      messageText: Text(
        message,
        style: const TextStyle(color: Colors.white70, fontSize: 14),
      ),
      backgroundColor: const Color(0xFFE91E63).withValues(alpha: 0.9),
      borderRadius: 16,
      margin: const EdgeInsets.all(16),
      duration: const Duration(seconds: 4),
      animationDuration: const Duration(milliseconds: 500),
      snackPosition: SnackPosition.TOP,
      icon: Container(
        padding: const EdgeInsets.all(8),
        decoration: const BoxDecoration(
          color: Colors.white24,
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.error_outline, color: Colors.white, size: 24),
      ),
    );
  }
}


