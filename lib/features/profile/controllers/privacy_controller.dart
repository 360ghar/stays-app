import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:stays_app/app/controllers/base/base_controller.dart';
import 'package:stays_app/features/auth/controllers/auth_controller.dart';
import 'package:stays_app/app/data/models/user_model.dart';
import 'package:stays_app/app/data/repositories/auth_repository.dart';
import 'package:stays_app/app/data/repositories/profile_repository.dart';
import 'package:stays_app/app/routes/app_routes.dart';
import 'package:stays_app/app/utils/logger/app_logger.dart';
import 'package:stays_app/features/profile/controllers/profile_controller.dart';

class PrivacyController extends BaseController {
  PrivacyController({
    required ProfileRepository profileRepository,
    required ProfileController profileController,
    required AuthRepository authRepository,
    required AuthController authController,
  }) : _profileRepository = profileRepository,
       _profileController = profileController,
       _authRepository = authRepository,
       _authController = authController;

  final ProfileRepository _profileRepository;
  final ProfileController _profileController;
  final AuthRepository _authRepository;
  final AuthController _authController;

  final RxBool twoFactorEnabled = false.obs;
  final RxBool profileVisible = true.obs;
  final RxBool locationSharing = false.obs;
  final RxBool dataExportInFlight = false.obs;
  final RxBool accountDeletionInFlight = false.obs;
  final RxBool isSaving = false.obs;

  final TextEditingController currentPasswordController =
      TextEditingController();
  final TextEditingController newPasswordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();

  Worker? _userWorker;

  @override
  void onInit() {
    super.onInit();
    _hydrate(_profileController.user.value);
    _userWorker = ever<UserModel?>(_profileController.user, _hydrate);
  }

  @override
  void onClose() {
    currentPasswordController.dispose();
    newPasswordController.dispose();
    confirmPasswordController.dispose();
    _userWorker?.dispose();
    super.onClose();
  }

  void _hydrate(UserModel? user) {
    if (user == null) return;
    final settings = user.privacySettings ?? {};
    twoFactorEnabled.value = _asBool(
      settings['twoFactorEnabled'],
      fallback: false,
    );
    profileVisible.value = _asBool(settings['profileVisible'], fallback: true);
    locationSharing.value = _asBool(
      settings['locationSharing'],
      fallback: false,
    );
  }

  bool _asBool(dynamic value, {required bool fallback}) {
    if (value is bool) return value;
    if (value is num) return value != 0;
    if (value is String) {
      final normalized = value.toLowerCase();
      return normalized == 'true' || normalized == '1' || normalized == 'yes';
    }
    return fallback;
  }

  void setTwoFactorEnabled(bool value) {
    twoFactorEnabled.value = value;
  }

  void setProfileVisible(bool value) {
    profileVisible.value = value;
  }

  void setLocationSharing(bool value) {
    locationSharing.value = value;
  }

  Future<void> savePrivacySettings() async {
    if (isSaving.value) return;
    try {
      isSaving.value = true;
      final payload = {
        'twoFactorEnabled': twoFactorEnabled.value,
        'profileVisible': profileVisible.value,
        'locationSharing': locationSharing.value,
      };
      final updated = await _profileRepository.updatePrivacySettings(payload);
      _profileController.updateUser(updated);
      _profileController.updatePrivacySettingsLocal(payload);
      Get.snackbar(
        'Privacy & Security',
        'Settings updated successfully',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e, stack) {
      AppLogger.error('Failed to update privacy settings', e, stack);
      Get.snackbar(
        'Update failed',
        'Unable to update privacy settings. Please try again.',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isSaving.value = false;
    }
  }

  Future<void> changePassword() async {
    final current = currentPasswordController.text.trim();
    final newPassword = newPasswordController.text.trim();
    final confirm = confirmPasswordController.text.trim();

    if (newPassword.length < 8) {
      Get.snackbar(
        'Password',
        'Password must be at least 8 characters long.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }
    if (newPassword != confirm) {
      Get.snackbar(
        'Password',
        'Passwords do not match.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    try {
      isSaving.value = true;
      await _authRepository.updatePassword(
        newPassword: newPassword,
        currentPassword: current.isEmpty ? null : current,
      );
      currentPasswordController.clear();
      newPasswordController.clear();
      confirmPasswordController.clear();
      Get.snackbar(
        'Password updated',
        'Your password has been changed successfully.',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e, stack) {
      AppLogger.error('Password update failed', e, stack);
      Get.snackbar(
        'Password update failed',
        'We were unable to change your password. Please verify and retry.',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isSaving.value = false;
    }
  }

  Future<void> requestDataExport() async {
    if (dataExportInFlight.value) return;
    try {
      dataExportInFlight.value = true;
      await _profileRepository.requestDataExport();
      Get.snackbar(
        'Data export requested',
        'We will email you when your data export is ready.',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e, stack) {
      AppLogger.error('Data export request failed', e, stack);
      Get.snackbar(
        'Request failed',
        'Unable to request data export. Please try again later.',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      dataExportInFlight.value = false;
    }
  }

  Future<void> deleteAccount() async {
    if (accountDeletionInFlight.value) return;
    final confirmDeletion =
        await Get.dialog<bool>(
          AlertDialog(
            title: const Text('Delete account'),
            content: const Text(
              'This action cannot be undone. Do you really want to delete your account?',
            ),
            actions: [
              TextButton(
                onPressed: () => Get.back(result: false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                onPressed: () => Get.back(result: true),
                child: const Text('Delete'),
              ),
            ],
          ),
        ) ??
        false;
    if (!confirmDeletion) return;

    try {
      accountDeletionInFlight.value = true;
      await _profileRepository.deleteAccount();
      await _authController.logout();
      Get.offAllNamed(Routes.login);
      Get.snackbar(
        'Account deleted',
        'Your account has been removed successfully.',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e, stack) {
      AppLogger.error('Account deletion failed', e, stack);
      Get.snackbar(
        'Deletion failed',
        'We could not delete your account. Please contact support.',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      accountDeletionInFlight.value = false;
    }
  }
}
