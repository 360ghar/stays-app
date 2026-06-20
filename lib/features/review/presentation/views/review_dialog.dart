import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:stays_app/app/data/repositories/review_repository.dart';
import 'package:stays_app/features/review/presentation/controllers/review_controller.dart';

/// Shows a review dialog that actually collects a rating + optional comment
/// and submits via [ReviewController]. Returns true if the review was
/// submitted successfully.
Future<bool> showReviewDialog({
  required int bookingId,
  required String hotelName,
}) async {
  final controller = Get.put(
    ReviewController(repository: Get.find<ReviewRepository>()),
    tag: 'review_$bookingId',
  );
  controller.rating.value = 0;
  controller.commentController.clear();

  final result = await Get.dialog<bool>(
    AlertDialog(
      title: Text('Review $hotelName'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('How was your stay?'),
          const SizedBox(height: 12),
          Obx(
            () => Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (index) {
                final starValue = index + 1;
                return IconButton(
                  onPressed: controller.isSubmitting.value
                      ? null
                      : () => controller.setRating(starValue),
                  icon: Icon(
                    starValue <= controller.rating.value
                        ? Icons.star
                        : Icons.star_border,
                    color: Colors.amber,
                    size: 36,
                  ),
                );
              }),
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: controller.commentController,
            maxLines: 3,
            enabled: !controller.isSubmitting.value,
            decoration: const InputDecoration(
              hintText: 'Share your experience (optional)',
              border: OutlineInputBorder(),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: controller.isSubmitting.value
              ? null
              : () => Get.back(result: false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: controller.isSubmitting.value
              ? null
              : () async {
                  final ok = await controller.submit(bookingId);
                  if (ok) {
                    Get.back(result: true);
                  }
                },
          child: Obx(
            () => controller.isSubmitting.value
                ? const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Submit'),
          ),
        ),
      ],
    ),
    barrierDismissible: false,
  );

  Get.delete<ReviewController>(tag: 'review_$bookingId');
  return result ?? false;
}
