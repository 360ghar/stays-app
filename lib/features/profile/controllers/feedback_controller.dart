import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:stays_app/app/controllers/base/base_controller.dart';
import 'package:stays_app/app/data/models/feedback_model.dart';
import 'package:stays_app/app/data/repositories/feedback_repository.dart';
import 'package:stays_app/app/utils/helpers/app_snackbar.dart';

class FeedbackController extends BaseController {
  FeedbackController({required FeedbackRepository feedbackRepository})
    : _feedbackRepository = feedbackRepository;

  final FeedbackRepository _feedbackRepository;

  /// `'bug'` or `'feature'`. Defaults to `'bug'`.
  final RxString feedbackType = 'bug'.obs;

  final TextEditingController titleController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();

  bool get isFeatureRequest => feedbackType.value == 'feature';

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments;
    if (args is Map && args['type'] is String) {
      final type = args['type'] as String;
      feedbackType.value = type == 'feature' ? 'feature' : 'bug';
    }
  }

  void setFeedbackType(String type) {
    feedbackType.value = type == 'feature' ? 'feature' : 'bug';
  }

  Future<void> submitFeedback() async {
    if (isLoading.value) return;

    final title = titleController.text.trim();
    final description = descriptionController.text.trim();

    if (title.isEmpty || description.isEmpty) {
      AppSnackbar.warning(
        title: 'Missing details',
        message: 'Please add a title and a description before submitting.',
      );
      return;
    }

    // source defaults to 'mobile' and severity to 'medium' on the model.
    final request = BugReportRequest(
      bugType: isFeatureRequest ? 'feature_request' : 'functionality_bug',
      title: title,
      description: description,
      tags: const ['stays'],
    );

    final result = await executeWithErrorHandling(() async {
      await _feedbackRepository.submitBugReport(request);
      return true;
    });

    if (result == true) {
      titleController.clear();
      descriptionController.clear();
      AppSnackbar.success(
        title: isFeatureRequest ? 'Feature requested' : 'Bug reported',
        message: isFeatureRequest
            ? 'Thanks for the suggestion. Our team will review it shortly.'
            : 'Thanks for the report. Our team will look into it shortly.',
      );
      Get.back();
    } else {
      AppSnackbar.error(
        title: 'Submission failed',
        message: 'We could not send your feedback. Please try again.',
      );
    }
  }

  @override
  void onClose() {
    titleController.dispose();
    descriptionController.dispose();
    super.onClose();
  }
}
