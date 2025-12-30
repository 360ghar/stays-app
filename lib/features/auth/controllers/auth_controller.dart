import 'dart:async';

import 'package:get/get.dart';

import 'package:stays_app/app/data/repositories/auth_repository.dart';
import 'package:stays_app/app/data/models/user_model.dart';
import 'package:stays_app/app/routes/app_routes.dart';
import 'package:stays_app/app/utils/logger/app_logger.dart';
import 'package:stays_app/app/utils/exceptions/app_exceptions.dart';
import 'package:stays_app/app/utils/helpers/app_snackbar.dart';
import 'package:stays_app/app/controllers/base/base_controller.dart';
import 'form_validation_controller.dart';
import 'session_controller.dart';
import 'user_profile_controller.dart';

/// Controller responsible for authentication operations.
/// Handles login, logout, and registration flows.
/// Delegates session management to SessionController and profile to UserProfileController.
class AuthController extends BaseController {
  AuthController({
    required AuthRepository authRepository,
    required SessionController sessionController,
  }) : _authRepository = authRepository,
       _sessionController = sessionController {
    // Resolve the shared FormValidationController via GetX
    _validation = Get.isRegistered<FormValidationController>()
        ? Get.find<FormValidationController>()
        : Get.put<FormValidationController>(FormValidationController());

    // Resolve or create UserProfileController
    _userProfileController = Get.isRegistered<UserProfileController>()
        ? Get.find<UserProfileController>()
        : Get.put<UserProfileController>(UserProfileController());
  }

  final AuthRepository _authRepository;
  final SessionController _sessionController;
  late final FormValidationController _validation;
  late final UserProfileController _userProfileController;

  // Expose session state for backwards compatibility
  RxBool get isAuthenticated => _sessionController.isAuthenticated;
  RxBool get rememberMe => _sessionController.rememberMe;

  // Expose current user from profile controller
  Rx<UserModel?> get currentUser => _userProfileController.currentUser;

  final RxBool isPasswordVisible = false.obs;

  // Backwards-compat alias used by phone-based views
  RxString get phoneError => emailOrPhoneError;
  RxString get emailOrPhoneError => _validation.emailOrPhoneError;
  RxString get passwordError => _validation.passwordError;
  RxString get confirmPasswordError => _validation.confirmPasswordError;

  @override
  void onInit() {
    super.onInit();
    unawaited(_initAuthStatus());
  }

  @override
  void onReady() {
    super.onReady();
    unawaited(_loadSavedUser());
    if (isAuthenticated.value) {
      unawaited(_userProfileController.fetchAndCacheProfile());
    }
  }

  void togglePasswordVisibility() {
    isPasswordVisible.value = !isPasswordVisible.value;
  }

  Future<void> _initAuthStatus() async {
    try {
      await _sessionController.ready;
    } catch (_) {
      // If readiness throws, proceed with best-effort check
    }
    await _checkAuthStatus();
  }

  Future<void> _checkAuthStatus() async {
    try {
      var tokenAuth = _sessionController.isAuthenticated.value;
      final repoAuth = await _authRepository.isAuthenticated();

      if (repoAuth && !tokenAuth) {
        await _sessionController.updateTokenServiceFromCurrentSession();
        tokenAuth = _sessionController.isAuthenticated.value;
      }

      _sessionController.setAuthenticated(value: tokenAuth && repoAuth);
      AppLogger.info(
        isAuthenticated.value
            ? 'User is authenticated'
            : 'No valid tokens found. User needs to login.',
      );

      if (isAuthenticated.value) {
        unawaited(_userProfileController.fetchAndCacheProfile());
      }
    } catch (e) {
      AppLogger.error('Auth check failed', e);
      _sessionController.setAuthenticated(value: false);
    }
  }

  Future<void> _loadSavedUser() async {
    try {
      final user = await _authRepository.getCurrentUser();
      if (user != null) {
        _userProfileController.setUser(user);
        AppLogger.info('Loaded saved user: ${user.email ?? user.phone}');
      }
    } catch (e) {
      AppLogger.error('Failed to load saved user', e);
    }
  }

  /// Login with email or phone
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

      _userProfileController.setUser(user);
      _sessionController.setAuthenticated(value: true);

      final displayName =
          user.name ?? user.firstName ?? user.email ?? user.phone ?? 'User';
      _showSuccessSnackbar(
        title: 'Welcome Back!',
        message: 'Hello $displayName',
      );

      await _sessionController.syncRememberMeStateAfterLogin();
      unawaited(_userProfileController.fetchAndCacheProfile());
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

  /// Phone-based login (delegates to unified login path)
  Future<void> loginWithPhone({
    required String phone,
    required String password,
  }) async {
    return login(email: phone, password: password);
  }

  /// Phone signup via Supabase: sends OTP for first-time validation
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

  /// Send forgot password OTP (stub until backend supports it)
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

  /// Reset password (stub until backend supports it)
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
      await _sessionController.clearSession();
      await _userProfileController.clearUser();

      // Reset form/UI state
      emailOrPhoneError.value = '';
      passwordError.value = '';
      confirmPasswordError.value = '';
      isPasswordVisible.value = false;
      isLoading.value = false;

      _showSuccessSnackbar(
        title: 'Logged Out',
        message: 'You have been successfully logged out.',
      );

      await Get.offAllNamed(Routes.login);
    } catch (e) {
      AppLogger.error('Logout failed', e);
      _showErrorSnackbar(
        title: 'Logout Failed',
        message: 'Failed to logout properly.',
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> register({
    required String email,
    required String password,
    String? confirmPassword,
    String? name,
    String? firstName,
    String? lastName,
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
        final parts = <String>[
          (firstName ?? '').trim(),
          (lastName ?? '').trim(),
        ]..removeWhere((value) => value.isEmpty);
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
      _userProfileController.setUser(user);
      _sessionController.setAuthenticated(value: true);

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

  /// Update the remember-me preference
  Future<void> setRememberMe({required bool value}) async {
    await _sessionController.setRememberMe(value: value);
  }

  /// Fetch and cache user profile (delegates to UserProfileController)
  Future<UserModel?> fetchAndCacheProfile() async {
    return _userProfileController.fetchAndCacheProfile();
  }

  /// Update user profile data (delegates to UserProfileController)
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
    return _userProfileController.updateProfile(
      firstName: firstName,
      lastName: lastName,
      fullName: fullName,
      bio: bio,
      phone: phone,
      dateOfBirth: dateOfBirth,
      avatarUrl: avatarUrl,
      agentId: agentId,
    );
  }

  /// Update user preferences (delegates to UserProfileController)
  Future<UserModel?> updateUserPreferences(
    Map<String, dynamic> preferences,
  ) async {
    return _userProfileController.updatePreferences(preferences);
  }

  /// Update user location (delegates to UserProfileController)
  Future<UserModel?> updateUserLocation({
    required double latitude,
    required double longitude,
    bool shareLocation = true,
  }) async {
    return _userProfileController.updateLocation(
      latitude: latitude,
      longitude: longitude,
      shareLocation: shareLocation,
    );
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
