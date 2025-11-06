import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../controllers/settings/settings_controller.dart';

class SettingsView extends GetView<SettingsController> {
  const SettingsView({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Scaffold(
      appBar: AppBar(title: Text('settings.title'.tr)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          children: [
            Text(
              'settings.description'.tr,
              style: textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurface.withValues(alpha: 0.72),
              ),
            ),
            const SizedBox(height: 24),
            _SettingsSection(
              title: 'settings.appearance'.tr,
              subtitle: 'settings.appearance_subtitle'.tr,
              child: Obx(() {
                final selectedMode = controller.selectedThemeMode;
                return Column(
                  children: controller.themeOptions
                      .map(
                        (option) => _ThemeOptionTile(
                          option: option,
                          isSelected: option.mode == selectedMode,
                          onTap: () => controller.selectTheme(option.mode),
                        ),
                      )
                      .toList(),
                );
              }),
            ),
            const SizedBox(height: 16),
            _SettingsSection(
              title: 'settings.quick_actions'.tr,
              subtitle: 'settings.quick_subtitle'.tr,
              child: Obx(() {
                final isDark = controller.selectedThemeMode == ThemeMode.dark;
                return _ThemeToggleTile(
                  value: isDark,
                  onChanged: controller.toggleDarkMode,
                );
              }),
            ),
            const SizedBox(height: 16),
            _SettingsSection(
              title: 'settings.language_title'.tr,
              subtitle: 'settings.language_subtitle'.tr,
              child: Obx(() {
                final selected = controller.selectedLocale.value;
                return Column(
                  children: controller.languageOptions
                      .map(
                        (option) => _LanguageOptionTile(
                          option: option,
                          isSelected: option.locale == selected,
                          onTap: () => controller.selectLanguage(option.locale),
                        ),
                      )
                      .toList(),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}

class _SettingsSection extends StatelessWidget {
  const _SettingsSection({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: theme.textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
        const SizedBox(height: 16),
        child,
      ],
    );
  }
}

class _ThemeOptionTile extends StatelessWidget {
  const _ThemeOptionTile({
    required this.option,
    required this.isSelected,
    required this.onTap,
  });

  final ThemeOption option;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final selectedColor = colorScheme.primary.withValues(alpha: 0.12);
    final baseBorderColor = colorScheme.outlineVariant.withValues(alpha: 0.6);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: isSelected ? selectedColor : colorScheme.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isSelected ? colorScheme.primary : baseBorderColor,
              width: 1.2,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: isSelected
                      ? colorScheme.primary
                      : colorScheme.surfaceContainerHighest.withValues(
                          alpha: 0.6,
                        ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  option.icon,
                  size: 24,
                  color: isSelected
                      ? colorScheme.onPrimary
                      : colorScheme.onSurface,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      option.title.tr,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      option.description.tr,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurface.withValues(alpha: 0.68),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                isSelected ? Icons.check_circle : Icons.radio_button_unchecked,
                color: isSelected
                    ? colorScheme.primary
                    : colorScheme.onSurface.withValues(alpha: 0.45),
                size: 22,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ThemeToggleTile extends StatelessWidget {
  const _ThemeToggleTile({required this.value, required this.onChanged});

  final bool value;
  final Future<void> Function(bool) onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.6),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.6),
              shape: BoxShape.circle,
            ),
            child: Icon(
              value ? Icons.bedtime : Icons.wb_sunny_outlined,
              color: colorScheme.onSurface,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'settings.toggle_title'.tr,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'settings.toggle_desc'.tr,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurface.withValues(alpha: 0.68),
                  ),
                ),
              ],
            ),
          ),
          Switch.adaptive(
            value: value,
            onChanged: (isEnabled) {
              onChanged(isEnabled);
            },
          ),
        ],
      ),
    );
  }
}

class _LanguageOptionTile extends StatelessWidget {
  const _LanguageOptionTile({
    required this.option,
    required this.isSelected,
    required this.onTap,
  });

  final LanguageOption option;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final borderColor = colorScheme.outlineVariant.withValues(alpha: 0.6);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isSelected ? colorScheme.primary : borderColor,
              width: 1.2,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest.withValues(
                    alpha: 0.6,
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  option.icon,
                  size: 24,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  option.labelKey.tr,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                ),
              ),
              Icon(
                isSelected ? Icons.check_circle : Icons.radio_button_unchecked,
                color: isSelected
                    ? colorScheme.primary
                    : colorScheme.onSurface.withValues(alpha: 0.45),
                size: 22,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
