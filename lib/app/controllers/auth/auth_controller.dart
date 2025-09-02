import 'package:get/get.dart';

import '../../data/repositories/auth_repository.dart';
import '../../data/services/storage_service.dart';
import '../../data/models/user_model.dart';
import '../../routes/app_routes.dart';
import '../../utils/exceptions/app_exceptions.dart';
import '../../utils/logger/app_logger.dart';

class AuthController extends GetxController {
  final AuthRepository _authRepository;
  final StorageService _storageService;

  AuthController({required AuthRepository authRepository, required StorageService storageService})
      : _authRepository = authRepository,
        _storageService = storageService;

  final Rx<UserModel?> currentUser = Rx<UserModel?>(null);
  final RxBool isLoading = false.obs;
  final RxBool isAuthenticated = false.obs;

  @override
  void onInit() {
    super.onInit();
    _checkAuthStatus();
  }

  Future<void> _checkAuthStatus() async {
    try {
      final token = await _storageService.getAccessToken();
      if (token != null) {
        // In a real app, fetch profile
        isAuthenticated.value = true;
      }
    } catch (e) {
      AppLogger.error('Auth check failed', e);
    }
  }

  Future<void> login({required String email, required String password}) async {
    try {
      isLoading.value = true;
      final response = await _authRepository.login(email: email, password: password);
      await _storageService.saveTokens(accessToken: response.accessToken, refreshToken: response.refreshToken);
      currentUser.value = response.user;
      isAuthenticated.value = true;
      Get.offAllNamed(Routes.home);
    } on ApiException catch (e) {
      Get.snackbar('Error', e.message);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> logout() async {
    try {
      await _authRepository.logout(_storageService);
      await _storageService.clearTokens();
      currentUser.value = null;
      isAuthenticated.value = false;
      Get.offAllNamed(Routes.login);
    } catch (e) {
      AppLogger.error('Logout failed', e);
    }
  }

  Future<void> register({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
  }) async {
    try {
      isLoading.value = true;
      await Future.delayed(const Duration(milliseconds: 800));
      Get.snackbar('Success', 'Account created. Please login.');
      Get.offAllNamed(Routes.login);
    } catch (e) {
      Get.snackbar('Error', 'Registration failed');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> forgotPassword(String email) async {
    try {
      isLoading.value = true;
      await Future.delayed(const Duration(milliseconds: 800));
      Get.snackbar('Email sent', 'Check your inbox for reset link');
    } catch (e) {
      Get.snackbar('Error', 'Failed to send reset link');
    } finally {
      isLoading.value = false;
    }
  }
}
