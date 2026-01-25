import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:stays_app/app/controllers/base/base_controller.dart';
import 'package:stays_app/features/auth/controllers/auth_controller.dart';
import 'package:stays_app/app/data/models/user_model.dart';
import 'package:stays_app/app/data/repositories/auth_repository.dart';
import 'package:stays_app/app/data/repositories/profile_repository.dart';
import 'package:stays_app/app/routes/app_routes.dart';
import 'package:stays_app/app/utils/extensions/dynamic_extensions.dart';
import 'package:stays_app/app/utils/helpers/app_snackbar.dart';
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

  /// Alias for isLoading from BaseController for backwards compatibility
  RxBool get isSaving => isLoading;

  final TextEditingController currentPasswordController =
      TextEditingController();
  final TextEditingController newPasswordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();

  @override
  void onInit() {
    super.onInit();
    _hydrate(_profileController.user.value);
    trackWorker(ever<UserModel?>(_profileController.user, _hydrate));
  }

  @override
  void onClose() {
    currentPasswordController.dispose();
    newPasswordController.dispose();
    confirmPasswordController.dispose();
    // Worker is automatically disposed by BaseController via trackWorker
    super.onClose();
  }

  void _hydrate(UserModel? user) {
    if (user == null) return;
    final settings = user.privacySettings ?? {};
    twoFactorEnabled.value = parseBool(settings['twoFactorEnabled'], fallback: false);
    profileVisible.value = parseBool(settings['profileVisible'], fallback: true);
    locationSharing.value = parseBool(settings['locationSharing'], fallback: false);
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
    if (isLoading.value) return;
    final payload = {
      'twoFactorEnabled': twoFactorEnabled.value,
      'profileVisible': profileVisible.value,
      'locationSharing': locationSharing.value,
    };
    final result = await executeWithErrorHandling(() async {
      final updated = await _profileRepository.updatePrivacySettings(payload);
      _profileController.updateUser(updated);
      _profileController.updatePrivacySettingsLocal(payload);
      return updated;
    });
    if (result != null) {
      AppSnackbar.success(
        title: 'Privacy & Security',
        message: 'Settings updated successfully',
      );
    } else {
      AppSnackbar.error(
        title: 'Update failed',
        message: 'Unable to update privacy settings. Please try again.',
      );
    }
  }

  Future<void> changePassword() async {
    final current = currentPasswordController.text.trim();
    final newPassword = newPasswordController.text.trim();
    final confirm = confirmPasswordController.text.trim();

    if (newPassword.length < 8) {
      AppSnackbar.warning(
        title: 'Password',
        message: 'Password must be at least 8 characters long.',
      );
      return;
    }
    if (newPassword != confirm) {
      AppSnackbar.warning(
        title: 'Password',
        message: 'Passwords do not match.',
      );
      return;
    }

    final result = await executeWithErrorHandling(() async {
      await _authRepository.updatePassword(
        newPassword: newPassword,
        currentPassword: current.isEmpty ? null : current,
      );
      currentPasswordController.clear();
      newPasswordController.clear();
      confirmPasswordController.clear();
      return true;
    });
    if (result == true) {
      AppSnackbar.success(
        title: 'Password updated',
        message: 'Your password has been changed successfully.',
      );
    } else {
      AppSnackbar.error(
        title: 'Password update failed',
        message: 'We were unable to change your password. Please verify and retry.',
      );
    }
  }

  Future<void> requestDataExport() async {
    if (dataExportInFlight.value) return;
    dataExportInFlight.value = true;
    final result = await executeWithErrorHandling(() async {
      await _profileRepository.requestDataExport();
      return true;
    }, showLoading: false);
    dataExportInFlight.value = false;
    if (result == true) {
      AppSnackbar.success(
        title: 'Data export requested',
        message: 'We will email you when your data export is ready.',
      );
    } else {
      AppSnackbar.error(
        title: 'Request failed',
        message: 'Unable to request data export. Please try again later.',
      );
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

    accountDeletionInFlight.value = true;
    final result = await executeWithErrorHandling(() async {
      await _profileRepository.deleteAccount();
      await _authController.logout();
      return true;
    }, showLoading: false);
    accountDeletionInFlight.value = false;
    if (result == true) {
      Get.offAllNamed(Routes.login);
      AppSnackbar.success(
        title: 'Account deleted',
        message: 'Your account has been removed successfully.',
      );
    } else {
      AppSnackbar.error(
        title: 'Deletion failed',
        message: 'We could not delete your account. Please contact support.',
      );
    }
  }
}
