import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:stays_app/app/ui/widgets/forms/custom_text_field.dart';
import 'package:stays_app/features/profile/controllers/feedback_controller.dart';

class FeedbackView extends GetView<FeedbackController> {
  const FeedbackView({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(
        title: Obx(
          () => Text(
            controller.isFeatureRequest ? 'Request a Feature' : 'Report a Bug',
          ),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          children: [
            Text(
              'What would you like to share?',
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            Obx(
              () => SegmentedButton<String>(
                segments: const [
                  ButtonSegment<String>(
                    value: 'bug',
                    label: Text('Report a Bug'),
                    icon: Icon(Icons.bug_report_outlined),
                  ),
                  ButtonSegment<String>(
                    value: 'feature',
                    label: Text('Request a Feature'),
                    icon: Icon(Icons.lightbulb_outline),
                  ),
                ],
                selected: {controller.feedbackType.value},
                onSelectionChanged: (selection) {
                  if (selection.isNotEmpty) {
                    controller.setFeedbackType(selection.first);
                  }
                },
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Title',
              style: textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            CustomTextField(
              controller: controller.titleController,
              hintText: 'Give it a short, descriptive title',
              maxLength: 200,
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 16),
            Text(
              'Description',
              style: textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            CustomTextField(
              controller: controller.descriptionController,
              hintText: 'Tell us what happened or what you would like to see',
              maxLines: 6,
              keyboardType: TextInputType.multiline,
            ),
            const SizedBox(height: 24),
            Obx(
              () => ElevatedButton.icon(
                onPressed: controller.isLoading.value
                    ? null
                    : controller.submitFeedback,
                icon: controller.isLoading.value
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.send_outlined),
                label: Text(
                  controller.isLoading.value ? 'Submitting...' : 'Submit',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
