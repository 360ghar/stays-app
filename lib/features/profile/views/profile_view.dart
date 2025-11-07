import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:stays_app/app/routes/app_routes.dart';
import 'package:stays_app/app/ui/widgets/profile/profile_header.dart';
import 'package:stays_app/app/utils/helpers/currency_helper.dart';
import 'package:stays_app/features/profile/controllers/profile_controller.dart';

class ProfileView extends GetView<ProfileController> {
  const ProfileView({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: Obx(() {
          if (controller.isLoading.value && controller.user.value == null) {
            return Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: controller.refreshProfile,
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(
                parent: AlwaysScrollableScrollPhysics(),
              ),
              slivers: [
                _buildHeader(context),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 12),
                        _buildCompletionCard(context),
                        const SizedBox(height: 12),
                        _buildStatsRow(context),
                        const SizedBox(height: 24),
                        _buildSection(
                          context,
                          title: 'Profile',
                          tiles: [
                            _MenuTile(
                              icon: Icons.edit_outlined,
                              title: 'Edit profile',
                              subtitle: 'Update your personal information',
                              onTap: controller.navigateToEditProfile,
                            ),
                            _MenuTile(
                              icon: Icons.event_available_outlined,
                              title: 'Inquiries',
                              subtitle: 'Review your submitted stay requests',
                              onTap: controller.navigateToInquiries,
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        _buildSection(
                          context,
                          title: 'Preferences',
                          tiles: [
                            _MenuTile(
                              icon: Icons.tune_outlined,
                              title: 'App preferences',
                              subtitle: 'Language, theme, and location',
                              onTap: controller.navigateToPreferences,
                            ),
                            _MenuTile(
                              icon: Icons.notifications_none,
                              title: 'Notifications',
                              subtitle: 'Push, email, and quiet hours',
                              onTap: controller.navigateToNotifications,
                            ),
                            _MenuTile(
                              icon: Icons.lock_outline,
                              title: 'Privacy & Security',
                              subtitle: 'Two-factor, visibility, data export',
                              onTap: controller.navigateToPrivacy,
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        _buildSection(
                          context,
                          title: 'Support',
                          tiles: [
                            _MenuTile(
                              icon: Icons.help_outline,
                              title: 'Help & Support',
                              subtitle: 'FAQs, contact, troubleshooting',
                              onTap: controller.navigateToHelp,
                            ),
                            _MenuTile(
                              icon: Icons.article_outlined,
                              title: 'Legal',
                              subtitle: 'Terms, privacy, refunds',
                              onTap: () => Get.toNamed(Routes.legal),
                            ),
                            _MenuTile(
                              icon: Icons.info_outline,
                              title: 'About 360ghar Stays',
                              subtitle: 'App version and company details',
                              onTap: controller.navigateToAbout,
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        _buildLogoutTile(context),
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }

  SliverToBoxAdapter _buildHeader(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return SliverToBoxAdapter(
      child: Obx(
        () => Container(
          decoration: BoxDecoration(
            color: colorScheme.surface,
            border: Border(
              bottom: BorderSide(
                color: colorScheme.outlineVariant.withValues(alpha: 0.4),
              ),
            ),
          ),
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
          child: ProfileHeader(
            initials: controller.initials.value,
            userName: controller.displayName.value,
            userType: controller.roleLabel.value,
            userEmail: controller.email.value,
            isLoading: controller.isLoading.value,
            avatarUrl: controller.avatarUrl.value,
            dense: false,
          ),
        ),
      ),
    );
  }

  Widget _buildCompletionCard(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Obx(
      () => Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: colorScheme.outlineVariant.withValues(alpha: 0.5),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.assignment_turned_in_outlined,
                  color: colorScheme.primary,
                  size: 22,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Profile completion',
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Text(
                  '${(controller.completion.value * 100).toInt()}%',
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: LinearProgressIndicator(
                value: controller.completion.value.clamp(0, 1),
                minHeight: 6,
                backgroundColor: colorScheme.primary.withValues(alpha: 0.12),
                valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              controller.completion.value >= 0.9
                  ? 'Great! Your profile is ready for the next stay.'
                  : 'Complete your profile for faster inquiries and better recommendations.',
              style: textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsRow(BuildContext context) {
    return Obx(() {
      final stats = [
        _StatData(
          label: 'Inquiries',
          value: controller.totalTrips.value.toString(),
        ),
        _StatData(
          label: 'Nights',
          value: controller.totalNights.value.toString(),
        ),
        _StatData(
          label: 'Spent',
          value: CurrencyHelper.format(controller.totalSpent.value),
        ),
      ];
      final colorScheme = Theme.of(context).colorScheme;
      final textTheme = Theme.of(context).textTheme;
      return Row(
        children: List.generate(stats.length, (index) {
          final stat = stats[index];
          final isLast = index == stats.length - 1;
          return Expanded(
            child: Container(
              margin: EdgeInsets.only(right: isLast ? 0 : 12),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: colorScheme.outlineVariant.withValues(alpha: 0.5),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    stat.value,
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    stat.label,
                    style: textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      );
    });
  }

  Widget _buildSection(
    BuildContext context, {
    required String title,
    required List<_MenuTile> tiles,
  }) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 12),
        Material(
          color: Theme.of(context).colorScheme.surface,
          shape: RoundedRectangleBorder(
            side: BorderSide(
              color: Theme.of(context)
                  .colorScheme
                  .outlineVariant
                  .withValues(alpha: 0.5),
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: tiles.asMap().entries.map((entry) {
              final isLast = entry.key == tiles.length - 1;
              return Column(
                children: [
                  entry.value,
                  if (!isLast)
                    Divider(
                      height: 1,
                      indent: 72,
                      color: Theme.of(
                        context,
                      ).colorScheme.outlineVariant.withValues(alpha: 0.2),
                    ),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildLogoutTile(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Obx(
      () => Material(
        color: colorScheme.errorContainer.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          onTap: controller.isActionInProgress.value
              ? null
              : controller.confirmLogout,
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: colorScheme.error.withValues(alpha: 0.18),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.logout, color: colorScheme.error),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Sign out',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: colorScheme.error,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Securely logout from this device',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colorScheme.error.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                ),
                if (controller.isActionInProgress.value)
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StatData {
  const _StatData({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;
}

class _MenuTile extends StatelessWidget {
  const _MenuTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: colorScheme.surfaceVariant.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: colorScheme.onSurface),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              size: 16,
              color: colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ],
        ),
      ),
    );
  }
}
