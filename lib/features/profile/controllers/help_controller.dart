import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:stays_app/app/routes/app_routes.dart';
import 'package:stays_app/app/utils/helpers/app_snackbar.dart';
import 'package:stays_app/app/utils/logger/app_logger.dart';
import 'package:stays_app/features/profile/models/faq_item.dart';
import 'package:stays_app/features/profile/models/support_channel.dart';
import 'package:url_launcher/url_launcher.dart';

class HelpController extends GetxController {
  final RxBool isSubmittingFeedback = false.obs;
  final TextEditingController feedbackController = TextEditingController();

  final List<FaqItem> faqs = const [
    FaqItem(
      question: 'How do I update my inquiry?',
      answer:
          'Navigate to your inquiries, select the request, and choose "Modify" to adjust dates or guests. Contact support if you need extra help.',
    ),
    FaqItem(
      question: 'How can I reach customer support?',
      answer:
          'You can email support@stays360.com or call +91 8005 360 360. Live chat is also available from the Help Center.',
    ),
    FaqItem(
      question: 'Where can I review my past inquiries?',
      answer:
          'Open Inquiries via the profile dashboard and select a stay to review your submitted details.',
    ),
    FaqItem(
      question: 'How do I delete my account?',
      answer:
          'Open Privacy & Security from your profile and use the Delete Account option. You can request a data export prior to deletion.',
    ),
  ];

  final List<SupportChannel> channels = const [
    SupportChannel(
      type: SupportChannelType.email,
      label: 'Email',
      value: 'support@stays360.com',
      icon: Icons.email_outlined,
    ),
    SupportChannel(
      type: SupportChannelType.phone,
      label: 'Phone',
      value: '+91 8005 360 360',
      icon: Icons.phone_in_talk,
    ),
    SupportChannel(
      type: SupportChannelType.chat,
      label: 'Live Chat',
      value: 'Chat with support',
      icon: Icons.chat_bubble_outline,
    ),
  ];

  @override
  void onClose() {
    feedbackController.dispose();
    super.onClose();
  }

  Future<void> openChannel(SupportChannel channel) async {
    switch (channel.type) {
      case SupportChannelType.email:
        await _launchUri(Uri(scheme: 'mailto', path: channel.value));
        break;
      case SupportChannelType.phone:
        await _launchUri(Uri(scheme: 'tel', path: channel.value));
        break;
      case SupportChannelType.chat:
        Get.toNamed(Routes.inbox);
        break;
    }
  }

  Future<void> submitFeedback() async {
    final message = feedbackController.text.trim();
    if (message.isEmpty || isSubmittingFeedback.value) {
      return;
    }
    try {
      isSubmittingFeedback.value = true;
      // Placeholder for API integration.
      await Future<void>.delayed(const Duration(milliseconds: 600));
      feedbackController.clear();
      AppSnackbar.success(
        title: 'Feedback received',
        message: 'Thanks for sharing your experience. Our team will review it shortly.',
      );
    } catch (e, stack) {
      AppLogger.error('Feedback submission failed', e, stack);
      AppSnackbar.error(
        title: 'Feedback not sent',
        message: 'We could not send your feedback. Please try again later.',
      );
    } finally {
      isSubmittingFeedback.value = false;
    }
  }

  Future<void> _launchUri(Uri uri) async {
    if (!await canLaunchUrl(uri)) {
      AppSnackbar.warning(
        title: 'Unavailable',
        message: 'Unable to launch ${uri.scheme} contact method on this device.',
      );
      return;
    }
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}
