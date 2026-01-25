import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:stays_app/app/controllers/base/base_controller.dart';
import 'package:stays_app/features/auth/controllers/auth_controller.dart';
import 'package:stays_app/app/data/models/user_model.dart';
import 'package:stays_app/app/data/repositories/profile_repository.dart';
import 'package:stays_app/app/utils/helpers/app_snackbar.dart';
import 'package:stays_app/features/profile/controllers/profile_controller.dart';

class EditProfileController extends BaseController {
  EditProfileController({
    required ProfileRepository profileRepository,
    required ProfileController profileController,
    required AuthController authController,
    ImagePicker? imagePicker,
  }) : _profileRepository = profileRepository,
       _profileController = profileController,
       _authController = authController,
       _imagePicker = imagePicker ?? ImagePicker();

  final ProfileRepository _profileRepository;
  final ProfileController _profileController;
  final AuthController _authController;
  final ImagePicker _imagePicker;

  final formKey = GlobalKey<FormState>();

  // Listeners for profile changes
  late final Worker _profileChangeWorker;
  late final Worker _authChangeWorker;

  late final TextEditingController firstNameController;
  late final TextEditingController lastNameController;
  late final TextEditingController emailController;
  late final TextEditingController phoneController;
  late final TextEditingController bioController;
  late final TextEditingController dobController;

  final Rx<DateTime?> dateOfBirth = Rx<DateTime?>(null);
  final RxBool isUploadingImage = false.obs;
  final Rx<File?> selectedImage = Rx<File?>(null);
  final RxString avatarUrl = ''.obs;

  /// Alias for isLoading from BaseController for backwards compatibility
  RxBool get isSaving => isLoading;

  String? get _firstName => firstNameController.text.trim().isEmpty
      ? null
      : firstNameController.text.trim();
  String? get _lastName => lastNameController.text.trim().isEmpty
      ? null
      : lastNameController.text.trim();
  String? get _bio =>
      bioController.text.trim().isEmpty ? null : bioController.text.trim();

  @override
  void onInit() {
    super.onInit();
    _initializeFields();

    // Listen for profile changes and update form fields accordingly
    _profileChangeWorker = trackWorker(ever(_profileController.user, (UserModel? user) {
      if (user != null) {
        _updateFieldsFromUser(user);
      }
    }));

    _authChangeWorker = trackWorker(ever(_authController.currentUser, (UserModel? user) {
      if (user != null) {
        _updateFieldsFromUser(user);
      }
    }));
  }

  void _initializeFields() {
    final profile =
        _profileController.user.value ?? _authController.currentUser.value;
    firstNameController = TextEditingController(text: profile?.firstName ?? '');
    lastNameController = TextEditingController(text: profile?.lastName ?? '');
    emailController = TextEditingController(text: profile?.email ?? '');
    phoneController = TextEditingController(text: profile?.phone ?? '');
    bioController = TextEditingController(text: profile?.bio ?? '');
    final dob = profile?.dateOfBirth;
    dateOfBirth.value = dob;
    dobController = TextEditingController(text: _formatDob(dob));
    avatarUrl.value = profile?.effectiveAvatarUrl ?? '';
  }

  void _updateFieldsFromUser(UserModel user) {
    // Update text controllers with new values from user
    firstNameController.text = user.firstName ?? '';
    lastNameController.text = user.lastName ?? '';
    emailController.text = user.email ?? '';
    phoneController.text = user.phone ?? '';
    bioController.text = user.bio ?? '';
    final dob = user.dateOfBirth;
    dateOfBirth.value = dob;
    dobController.text = _formatDob(dob);
    avatarUrl.value = user.effectiveAvatarUrl ?? '';
  }

  @override
  void onClose() {
    // Workers are automatically disposed by BaseController via trackWorker
    firstNameController.dispose();
    lastNameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    bioController.dispose();
    dobController.dispose();
    super.onClose();
  }

  String _formatDob(DateTime? dob) {
    if (dob == null) return '';
    return '${dob.day.toString().padLeft(2, '0')}/${dob.month.toString().padLeft(2, '0')}/${dob.year}';
  }

  Future<void> selectDate(BuildContext context) async {
    final now = DateTime.now();
    final latest = DateTime(now.year - 13, now.month, now.day);
    final picked = await showDatePicker(
      context: context,
      initialDate: dateOfBirth.value ?? latest,
      firstDate: DateTime(1900),
      lastDate: latest,
    );
    if (picked != null) {
      dateOfBirth.value = picked;
      dobController.text = _formatDob(picked);
    }
  }

  Future<void> pickImage(ImageSource source) async {
    try {
      final picked = await _imagePicker.pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 1080,
      );
      if (picked == null) return;
      if (kIsWeb) {
        AppSnackbar.warning(
          title: 'Unsupported',
          message: 'Image uploads are not supported on web builds yet.',
        );
        return;
      }
      final file = File(picked.path);
      selectedImage.value = file;
    } catch (e) {
      handleError(e);
      AppSnackbar.error(
        title: 'Image picker',
        message: 'Failed to pick image. Please try again.',
      );
    }
  }

  String? validateName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Name is required';
    }
    if (value.trim().length < 2) {
      return 'Enter at least 2 characters';
    }
    return null;
  }

  String? validatePhone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null;
    }
    final numeric = value.replaceAll(RegExp(r'[^0-9+]'), '');
    if (numeric.length < 8) {
      return 'Enter a valid phone number';
    }
    return null;
  }

  String? validateDob(String? value) {
    final dob = dateOfBirth.value;
    if (dob == null) {
      return null;
    }
    final now = DateTime.now();
    final minDob = DateTime(now.year - 13, now.month, now.day);
    if (dob.isAfter(minDob)) {
      return 'You must be at least 13 years old';
    }
    return null;
  }

  Future<void> save() async {
    if (isLoading.value) return;
    if (!(formKey.currentState?.validate() ?? false)) {
      return;
    }

    final result = await executeWithErrorHandling(() async {
      String? uploadedUrl;

      if (selectedImage.value != null) {
        isUploadingImage.value = true;
        uploadedUrl = await _profileRepository.uploadAvatar(
          selectedImage.value!,
        );
        avatarUrl.value = uploadedUrl;
      }

      final updated = await _profileRepository.updateProfile(
        firstName: _firstName,
        lastName: _lastName,
        fullName: _composeFullName(),
        bio: _bio,
        phone: phoneController.text.trim().isEmpty
            ? null
            : phoneController.text.trim(),
        dateOfBirth: dateOfBirth.value,
        avatarUrl: uploadedUrl ?? avatarUrl.value,
      );

      _profileController.updateUser(updated);
      selectedImage.value = null;
      return updated;
    });
    isUploadingImage.value = false;

    if (result != null) {
      Get.back(result: true);
      AppSnackbar.success(
        title: 'Profile updated',
        message: 'Your profile changes have been saved.',
      );
    } else {
      AppSnackbar.error(
        title: 'Update failed',
        message: 'We could not save your changes. Please try again.',
      );
    }
  }

  String? _composeFullName() {
    final parts = <String>[_firstName ?? '', _lastName ?? '']
      ..removeWhere((element) => element.trim().isEmpty);
    if (parts.isEmpty) return null;
    return parts.join(' ');
  }

  void clearSelectedImage() {
    selectedImage.value = null;
  }

  UserModel? get activeUser =>
      _profileController.user.value ?? _authController.currentUser.value;
}
