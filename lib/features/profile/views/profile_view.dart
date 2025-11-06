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
                        const SizedBox(height: 20),
                        _buildCompletionCard(context),
                        const SizedBox(height: 20),
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
                            _MenuTile(
                              icon: Icons.credit_card,
                              title: 'Payment methods',
                              subtitle: 'Manage saved cards and UPI IDs',
                              onTap: () => Get.toNamed(Routes.paymentMethods),
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

  SliverAppBar _buildHeader(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return SliverAppBar(
      automaticallyImplyLeading: false,
      backgroundColor: colorScheme.surface,
      floating: false,
      pinned: true,
      expandedHeight: 220,
      flexibleSpace: FlexibleSpaceBar(
        background: Obx(
          () => Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  colorScheme.surface,
                  colorScheme.surfaceContainerHighest.withValues(alpha: 0.6),
                ],
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 56, 20, 24),
              child: ProfileHeader(
                initials: controller.initials.value,
                userName: controller.displayName.value,
                userType: controller.roleLabel.value,
                userEmail: controller.email.value,
                isLoading: controller.isLoading.value,
                avatarUrl: controller.avatarUrl.value,
              ),
            ),
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
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.75),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: colorScheme.outlineVariant.withValues(alpha: 0.4),
          ),
          boxShadow: [
            BoxShadow(
              color: colorScheme.shadow.withValues(alpha: 0.08),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.verified_user_outlined, color: colorScheme.primary),
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
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: LinearProgressIndicator(
                value: controller.completion.value.clamp(0, 1),
                minHeight: 10,
                backgroundColor: colorScheme.primary.withValues(alpha: 0.12),
                valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
              ),
            ),
            const SizedBox(height: 12),
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
    return Obx(
      () => Row(
        children: [
          Expanded(
            child: _StatCard(
              label: 'Inquiries',
              value: controller.totalTrips.value.toString(),
              icon: Icons.flight_takeoff_outlined,
              color: const Color(0xFF60A5FA),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _StatCard(
              label: 'Nights',
              value: controller.totalNights.value.toString(),
              icon: Icons.nightlight_round,
              color: const Color(0xFF10B981),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _StatCard(
              label: 'Spent',
              value: CurrencyHelper.format(controller.totalSpent.value),
              icon: Icons.payments_outlined,
              color: const Color(0xFFF59E0B),
            ),
          ),
        ],
      ),
    );
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
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(24),
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

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.4),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
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
                color: colorScheme.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: colorScheme.primary),
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
              color: colorScheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }
}
