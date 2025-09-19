import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:stays_app/features/profile/controllers/help_controller.dart';
import 'package:stays_app/features/profile/models/support_channel.dart';

class HelpView extends GetView<HelpController> {
  const HelpView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Help & Support')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          children: [
            Text(
              'Quick answers',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            ...controller.faqs.map(
              (faq) => _FaqTile(question: faq.question, answer: faq.answer),
            ),
            const SizedBox(height: 24),
            Text(
              'Contact us',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            ...controller.channels.map(
              (channel) => _SupportTile(
                channel: channel,
                onTap: () => controller.openChannel(channel),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Send feedback',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller.feedbackController,
              minLines: 3,
              maxLines: 5,
              decoration: const InputDecoration(
                hintText: 'Tell us how we can improve your stay experience',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            Obx(
              () => ElevatedButton.icon(
                onPressed:
                    controller.isSubmittingFeedback.value
                        ? null
                        : controller.submitFeedback,
                icon:
                    controller.isSubmittingFeedback.value
                        ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                        : const Icon(Icons.send_outlined),
                label: Text(
                  controller.isSubmittingFeedback.value
                      ? 'Sending feedback...'
                      : 'Send feedback',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FaqTile extends StatelessWidget {
  const _FaqTile({required this.question, required this.answer});

  final String question;
  final String answer;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ExpansionTile(
        title: Text(question),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        children: [
          Text(
            answer,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _SupportTile extends StatelessWidget {
  const _SupportTile({required this.channel, required this.onTap});

  final SupportChannel channel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        onTap: onTap,
        leading: Icon(channel.icon),
        title: Text(channel.label),
        subtitle: Text(channel.value),
        trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
      ),
    );
  }
}
