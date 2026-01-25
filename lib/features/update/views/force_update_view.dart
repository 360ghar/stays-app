import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:stays_app/features/update/controllers/force_update_controller.dart';

/// Full-screen blocking view for critical/forced updates.
///
/// This screen is non-dismissible - the user must update to continue.
class ForceUpdateView extends GetView<ForceUpdateController> {
  const ForceUpdateView({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return PopScope(
      canPop: false, // Prevent back navigation
      child: Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                const Spacer(flex: 2),

                // App logo
                Image.asset(
                  'assets/images/360Stays_logo.png',
                  width: 150,
                  height: 150,
                ),

                const SizedBox(height: 32),

                // Update icon
                Icon(
                  Icons.system_update,
                  size: 64,
                  color: colorScheme.primary,
                ),

                const SizedBox(height: 24),

                // Title
                Text(
                  'update.required_title'.tr,
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 16),

                // Message
                Text(
                  'update.required_message'.tr,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 16),

                // Version info
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      _VersionRow(
                        label: 'update.current_label'.tr,
                        version: controller.currentVersion,
                      ),
                      const Divider(height: 16),
                      _VersionRow(
                        label: 'update.latest_label'.tr,
                        version: controller.storeVersion,
                        isHighlighted: true,
                      ),
                    ],
                  ),
                ),

                // Release notes (if available)
                if (controller.releaseNotes.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'update.whats_new'.tr,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 100),
                    child: SingleChildScrollView(
                      child: Text(
                        controller.releaseNotes,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ),
                ],

                const Spacer(flex: 3),

                // Update button
                Obx(
                  () => SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: controller.isLoading.value
                          ? null
                          : controller.openStore,
                      icon: controller.isLoading.value
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.download),
                      label: Text('update.update_now'.tr),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _VersionRow extends StatelessWidget {
  final String label;
  final String version;
  final bool isHighlighted;

  const _VersionRow({
    required this.label,
    required this.version,
    this.isHighlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        Text(
          version,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: isHighlighted ? colorScheme.primary : colorScheme.onSurface,
          ),
        ),
      ],
    );
  }
}
