import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:stays_app/features/profile/controllers/edit_profile_controller.dart';

class EditProfileView extends GetView<EditProfileController> {
  const EditProfileView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit profile'),
        actions: [
          Obx(
            () => IconButton(
              icon: const Icon(Icons.save_outlined),
              onPressed: controller.isSaving.value ? null : controller.save,
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Form(
          key: controller.formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
            children: [
              Center(child: _AvatarPreview(controller: controller)),
              const SizedBox(height: 24),
              const _SectionTitle('Personal information'),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: controller.firstNameController,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'First name',
                        hintText: 'Enter your first name',
                      ),
                      validator: controller.validateName,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: controller.lastNameController,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'Last name',
                        hintText: 'Enter your last name',
                      ),
                      validator: controller.validateName,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: controller.emailController,
                readOnly: true,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  helperText: 'Email changes are handled by support',
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: controller.phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Phone number',
                  hintText: '+91 98765 43210',
                ),
                validator: controller.validatePhone,
              ),
              const SizedBox(height: 16),
              GestureDetector(
                onTap: () => controller.selectDate(context),
                child: AbsorbPointer(
                  child: TextFormField(
                    controller: controller.dobController,
                    decoration: const InputDecoration(
                      labelText: 'Date of birth',
                      hintText: 'DD/MM/YYYY',
                      suffixIcon: Icon(Icons.calendar_today_outlined),
                    ),
                    validator: controller.validateDob,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: controller.bioController,
                minLines: 3,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Bio',
                  hintText: 'Share a short introduction for hosts',
                ),
              ),
              const SizedBox(height: 24),
              const _SectionTitle('Profile photo'),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => controller.pickImage(ImageSource.camera),
                      icon: const Icon(Icons.photo_camera_outlined),
                      label: const Text('Camera'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () =>
                          controller.pickImage(ImageSource.gallery),
                      icon: const Icon(Icons.photo_library_outlined),
                      label: const Text('Gallery'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              Obx(
                () => ElevatedButton.icon(
                  onPressed: controller.isSaving.value ? null : controller.save,
                  icon: controller.isSaving.value
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.check_circle_outline),
                  label: Text(
                    controller.isSaving.value
                        ? 'Saving changes...'
                        : 'Save changes',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AvatarPreview extends StatelessWidget {
  const _AvatarPreview({required this.controller});

  final EditProfileController controller;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Obx(() {
      Widget avatarChild;
      final File? file = controller.selectedImage.value;
      if (file != null) {
        avatarChild = ClipOval(
          child: Image.file(file, width: 120, height: 120, fit: BoxFit.cover),
        );
      } else if (controller.avatarUrl.value.isNotEmpty) {
        avatarChild = ClipOval(
          child: Image.network(
            controller.avatarUrl.value,
            width: 120,
            height: 120,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => _initialsFallback(context),
          ),
        );
      } else {
        avatarChild = _initialsFallback(context);
      }

      return Stack(
        alignment: Alignment.bottomRight,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: colorScheme.primary.withValues(alpha: 0.12),
            ),
            child: avatarChild,
          ),
          Positioned(
            bottom: 6,
            right: 6,
            child: Material(
              color: colorScheme.primary,
              shape: const CircleBorder(),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: () => controller.pickImage(ImageSource.gallery),
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Icon(
                    Icons.camera_alt_outlined,
                    size: 20,
                    color: colorScheme.onPrimary,
                  ),
                ),
              ),
            ),
          ),
        ],
      );
    });
  }

  Widget _initialsFallback(BuildContext context) {
    final initials = controller.activeUser?.initials ?? 'GU';
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: Text(
        initials,
        style: Theme.of(context).textTheme.headlineLarge?.copyWith(
          color: colorScheme.primary,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: Theme.of(
        context,
      ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
    );
  }
}
