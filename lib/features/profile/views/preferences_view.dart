import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:stays_app/features/profile/controllers/preferences_controller.dart';

class PreferencesView extends GetView<PreferencesController> {
  const PreferencesView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('App preferences'),
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
              onPressed: controller.isSaving.value ? null : controller.save,
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Obx(
          () => ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
            children: [
              _SectionHeader(
                title: 'Appearance',
                subtitle: 'Choose how the app looks on your device.',
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                children:
                    controller.supportedThemes
                        .map(
                          (mode) => ChoiceChip(
                            label: Text(mode.capitalizeFirst ?? mode),
                            selected: controller.themeMode.value == mode,
                            onSelected: (_) => controller.selectTheme(mode),
                          ),
                        )
                        .toList(),
              ),
              const SizedBox(height: 24),
              _SectionHeader(
                title: 'Language',
                subtitle: 'Switch the language used throughout the app.',
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                children:
                    controller.supportedLanguages
                        .map(
                          (entry) => ChoiceChip(
                            label: Text(entry['label'] ?? entry['code'] ?? ''),
                            selected:
                                controller.language.value == entry['code'],
                            onSelected:
                                (_) => controller.selectLanguage(
                                  entry['code'] ?? 'en',
                                ),
                          ),
                        )
                        .toList(),
              ),
              const SizedBox(height: 24),
              _SectionHeader(
                title: 'Location',
                subtitle:
                    'Enable automatic location to personalise stay suggestions.',
              ),
              const SizedBox(height: 12),
              SwitchListTile.adaptive(
                value: controller.autoLocation.value,
                onChanged: (value) => controller.autoLocation.value = value,
                title: const Text('Use current location'),
                subtitle: const Text(
                  'Allow 360ghar Stays to access your location for nearby deals.',
                ),
              ),
              const SizedBox(height: 24),
              _SectionHeader(
                title: 'Notifications',
                subtitle:
                    'Decide what kind of emails you would like to receive.',
              ),
              const SizedBox(height: 12),
              SwitchListTile.adaptive(
                value: controller.marketingEmails.value,
                onChanged: (value) => controller.marketingEmails.value = value,
                title: const Text('Deals & inspiration'),
                subtitle: const Text(
                  'Get curated stays, offers, and local guides.',
                ),
              ),
              SwitchListTile.adaptive(
                value: controller.travelAlerts.value,
                onChanged: (value) => controller.travelAlerts.value = value,
                title: const Text('Travel alerts'),
                subtitle: const Text(
                  'Receive alerts for price changes, weather updates, and safety notices.',
                ),
              ),
              const SizedBox(height: 24),
              _SectionHeader(
                title: 'Currency',
                subtitle: 'Select your preferred currency for bookings.',
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: controller.currency.value,
                decoration: const InputDecoration(labelText: 'Currency'),
                items:
                    controller.supportedCurrencies
                        .map(
                          (code) => DropdownMenuItem<String>(
                            value: code,
                            child: Text(code),
                          ),
                        )
                        .toList(),
                onChanged: (value) {
                  if (value != null) controller.selectCurrency(value);
                },
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: controller.isSaving.value ? null : controller.save,
                icon:
                    controller.isSaving.value
                        ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                        : const Icon(Icons.save_alt_outlined),
                label: Text(
                  controller.isSaving.value
                      ? 'Saving preferences...'
                      : 'Save preferences',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
