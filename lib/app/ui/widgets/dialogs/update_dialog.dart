import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Result of the update dialog
enum UpdateDialogResult {
  update,
  later,
}

/// Shows an update available dialog for optional updates.
///
/// Returns [UpdateDialogResult.update] if user taps "Update Now",
/// [UpdateDialogResult.later] if user taps "Remind Me Later".
Future<UpdateDialogResult?> showUpdateDialog(
  BuildContext context, {
  required String currentVersion,
  required String newVersion,
  String? releaseNotes,
  required VoidCallback onUpdate,
}) {
  return showDialog<UpdateDialogResult>(
    context: context,
    barrierDismissible: false,
    builder: (_) => AlertDialog(
      title: Text('update.title'.tr),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'update.new_version_available'.trParams({'version': newVersion}),
          ),
          const SizedBox(height: 8),
          Text(
            'update.current_version'.trParams({'version': currentVersion}),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          if (releaseNotes != null && releaseNotes.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              'update.whats_new'.tr,
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 4),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 150),
              child: SingleChildScrollView(
                child: Text(
                  releaseNotes,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, UpdateDialogResult.later),
          child: Text('update.remind_later'.tr),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.pop(context, UpdateDialogResult.update);
            onUpdate();
          },
          child: Text('update.update_now'.tr),
        ),
      ],
    ),
  );
}
