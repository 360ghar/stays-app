import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:stays_app/app/controllers/base/base_controller.dart';
import 'package:stays_app/app/data/repositories/review_repository.dart';
import 'package:stays_app/app/utils/helpers/app_snackbar.dart';
import 'package:stays_app/app/utils/logger/app_logger.dart';

/// Controller backing the review dialog. Submits via [ReviewRepository].
class ReviewController extends BaseController {
  ReviewController({required ReviewRepository repository})
    : _repository = repository;

  final ReviewRepository _repository;

  final RxInt rating = 0.obs;
  final TextEditingController commentController = TextEditingController();
  final RxBool isSubmitting = false.obs;

  void setRating(int value) => rating.value = value;

  /// Submit the review. Returns true on success.
  Future<bool> submit(int bookingId) async {
    if (rating.value < 1 || rating.value > 5) {
      AppSnackbar.warning(
        title: 'Rating',
        message: 'Please select a star rating.',
      );
      return false;
    }
    if (isSubmitting.value) return false;
    isSubmitting.value = true;
    try {
      final ok = await _repository.submitReview(
        bookingId: bookingId,
        rating: rating.value,
        comment: commentController.text.trim().isEmpty
            ? null
            : commentController.text.trim(),
      );
      if (ok) {
        AppSnackbar.success(
          title: 'Thank You!',
          message: 'Your ${rating.value}-star review has been submitted.',
        );
        return true;
      }
      AppSnackbar.error(
        title: 'Review Failed',
        message: 'Could not submit your review. Please try again.',
      );
      return false;
    } catch (e, s) {
      AppLogger.error('Review submission failed', e, s);
      AppSnackbar.error(
        title: 'Review Failed',
        message: 'Could not submit your review. Please try again.',
      );
      return false;
    } finally {
      isSubmitting.value = false;
    }
  }

  @override
  void onClose() {
    commentController.dispose();
    super.onClose();
  }
}
