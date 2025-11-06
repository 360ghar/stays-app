import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:stays_app/features/profile/controllers/about_controller.dart';

class AboutView extends GetView<AboutController> {
  const AboutView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('About 360ghar Stays')),
      body: SafeArea(
        child: Obx(
          () => ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
            children: [
              _InfoTile(
                icon: Icons.verified_outlined,
                title: 'App version',
                value: controller.version.value.isEmpty
                    ? 'Fetching...'
                    : controller.version.value,
              ),
              _InfoTile(
                icon: Icons.build_outlined,
                title: 'Build number',
                value: controller.buildNumber.value.isEmpty
                    ? '—'
                    : controller.buildNumber.value,
              ),
              _InfoTile(
                icon: Icons.cloud_outlined,
                title: 'Environment',
                value: controller.environment.value.toUpperCase(),
              ),
              const SizedBox(height: 24),
              Text(
                'Licenses & compliance',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 12),
              ...controller.complianceItems.map(
                (item) => ListTile(
                  leading: const Icon(Icons.article_outlined),
                  title: Text(item['title'] ?? ''),
                  trailing: const Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 16,
                  ),
                  onTap: () {
                    final route = item['route'];
                    if (route != null) {
                      Get.toNamed(route, arguments: item['slug']);
                    }
                  },
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Made by 360ghar',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 12),
              Text(
                '360ghar Stays helps travellers discover verified vacation rentals and homestays across India. We empower hosts with tools to manage listings, guests, and payments securely.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({
    required this.icon,
    required this.title,
    required this.value,
  });

  final IconData icon;
  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        leading: Icon(icon, color: colorScheme.primary),
        title: Text(title),
        subtitle: Text(value),
      ),
    );
  }
}
