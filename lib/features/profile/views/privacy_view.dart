import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:stays_app/features/profile/controllers/privacy_controller.dart';

class PrivacyView extends GetView<PrivacyController> {
  const PrivacyView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Privacy & Security'),
        actions: [
          Obx(
            () => IconButton(
              icon:
                  controller.isSaving.value
                      ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                      : const Icon(Icons.save_outlined),
              onPressed:
                  controller.isSaving.value
                      ? null
                      : controller.savePrivacySettings,
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Obx(
                () => SwitchListTile.adaptive(
                  title: const Text('Two-factor authentication'),
                  subtitle: const Text(
                    'Add an extra verification step when signing in.',
                  ),
                  value: controller.twoFactorEnabled.value,
                  onChanged: controller.setTwoFactorEnabled,
                ),
              ),
              Obx(
                () => SwitchListTile.adaptive(
                  title: const Text('Profile visibility'),
                  subtitle: const Text(
                    'Allow hosts to view your public profile.',
                  ),
                  value: controller.profileVisible.value,
                  onChanged: controller.setProfileVisible,
                ),
              ),
              Obx(
                () => SwitchListTile.adaptive(
                  title: const Text('Location sharing'),
                  subtitle: const Text(
                    'Share your location to receive nearby stay suggestions.',
                  ),
                  value: controller.locationSharing.value,
                  onChanged: controller.setLocationSharing,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Change password',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: controller.currentPasswordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Current password',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: controller.newPasswordController,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'New password'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: controller.confirmPasswordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Confirm new password',
                ),
              ),
              const SizedBox(height: 12),
              Obx(
                () => ElevatedButton.icon(
                  onPressed:
                      controller.isSaving.value
                          ? null
                          : controller.changePassword,
                  icon: const Icon(Icons.key_outlined),
                  label: Text(
                    controller.isSaving.value
                        ? 'Updating password...'
                        : 'Update password',
                  ),
                ),
              ),
              const SizedBox(height: 32),
              Text(
                'Data control',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 12),
              Obx(
                () => OutlinedButton.icon(
                  onPressed:
                      controller.dataExportInFlight.value
                          ? null
                          : controller.requestDataExport,
                  icon:
                      controller.dataExportInFlight.value
                          ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                          : const Icon(Icons.file_download_outlined),
                  label: Text(
                    controller.dataExportInFlight.value
                        ? 'Requesting export...'
                        : 'Request data export',
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Obx(
                () => ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        Theme.of(context).colorScheme.errorContainer,
                    foregroundColor:
                        Theme.of(context).colorScheme.onErrorContainer,
                  ),
                  onPressed:
                      controller.accountDeletionInFlight.value
                          ? null
                          : controller.deleteAccount,
                  icon:
                      controller.accountDeletionInFlight.value
                          ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                          : const Icon(Icons.delete_forever_outlined),
                  label: Text(
                    controller.accountDeletionInFlight.value
                        ? 'Processing...'
                        : 'Delete account',
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
