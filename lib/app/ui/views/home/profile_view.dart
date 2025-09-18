import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../controllers/auth/profile_controller.dart';
import '../../theme/theme_extensions.dart';

class ProfileView extends GetView<ProfileController> {
  const ProfileView({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: colors.surface,
      body: Obx(() {
        if (controller.isLoading.value && controller.profile.value == null) {
          return Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(colors.primary),
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: controller.fetchUserData,
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics(),
            ),
            slivers: [
              _buildSliverAppBar(context),
              _buildProfileContent(context),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildSliverAppBar(BuildContext context) {
    final colors = context.colors;
    return SliverAppBar(
      expandedHeight: 260,
      floating: false,
      pinned: true,
      elevation: 0,
      backgroundColor: colors.surface,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                colors.surface,
                colors.surfaceContainerHighest.withValues(alpha: 0.6),
              ],
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 20),
                  Hero(
                    tag: 'profile-avatar',
                    child: TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0.0, end: 1.0),
                      duration: const Duration(milliseconds: 800),
                      curve: Curves.elasticOut,
                      builder: (context, value, child) {
                        return Transform.scale(
                          scale: value,
                          child: Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: const LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [Color(0xFF3B82F6), Color(0xFF1D4ED8)],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(
                                    0xFF3B82F6,
                                  ).withValues(alpha: 0.3),
                                  blurRadius: 20,
                                  spreadRadius: 0,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                            child: Builder(
                              builder: (_) {
                                final avatarUrl =
                                    controller.profile.value?.avatarUrl;
                                if (avatarUrl != null && avatarUrl.isNotEmpty) {
                                  return ClipOval(
                                    child: Image.network(
                                      avatarUrl,
                                      width: 100,
                                      height: 100,
                                      fit: BoxFit.cover,
                                      errorBuilder:
                                          (context, error, stackTrace) =>
                                              Center(
                                                child: Text(
                                                  controller.userInitials.value,
                                                  style: const TextStyle(
                                                    fontSize: 36,
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.white,
                                                  ),
                                                ),
                                              ),
                                    ),
                                  );
                                }
                                return Center(
                                  child: Text(
                                    controller.userInitials.value,
                                    style: const TextStyle(
                                      fontSize: 36,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0.0, end: 1.0),
                    duration: const Duration(milliseconds: 600),
                    curve: Curves.easeOut,
                    builder: (context, value, child) {
                      return Opacity(
                        opacity: value,
                        child: Transform.translate(
                          offset: Offset(0, 20 * (1 - value)),
                          child: Column(
                            children: [
                              Text(
                                controller.userName.value,
                                style: Theme.of(context).textTheme.titleLarge
                                    ?.copyWith(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: colors.onSurface,
                                    ),
                              ),
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors:
                                        controller.userType.value == 'Superhost'
                                        ? [Colors.amber, Colors.orange]
                                        : [
                                            const Color(0xFF3B82F6),
                                            const Color(0xFF1D4ED8),
                                          ],
                                  ),
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: [
                                    BoxShadow(
                                      color:
                                          (controller.userType.value ==
                                                      'Superhost'
                                                  ? Colors.amber
                                                  : const Color(0xFF3B82F6))
                                              .withValues(alpha: 0.3),
                                      blurRadius: 8,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Text(
                                  controller.userType.value,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Builder(
                                builder: (_) {
                                  final email =
                                      controller.profile.value?.email ?? '';
                                  final phone =
                                      controller.profile.value?.phone ??
                                      controller.userPhone.value;
                                  final contact = (email.isNotEmpty)
                                      ? email
                                      : (phone.isNotEmpty ? phone : '');
                                  if (contact.isEmpty) {
                                    return const SizedBox.shrink();
                                  }
                                  return Text(
                                    contact,
                                    style: Theme.of(context).textTheme.bodySmall
                                        ?.copyWith(
                                          fontSize: 13,
                                          color: colors.onSurface.withValues(
                                            alpha: 0.7,
                                          ),
                                          fontWeight: FontWeight.w500,
                                        ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileContent(BuildContext context) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Stats Section
            _buildStatsSection(context),

            const SizedBox(height: 24),

            // Past Bookings Section
            _buildAnimatedSection(
              delay: 100,
              child: _buildGlassTile(
                icon: Icons.flight_takeoff_rounded,
                title: 'profile.past_bookings'.tr,
                subtitle: controller.pastTrips.isNotEmpty
                    ? 'profile.bookings_completed'.trParams({
                        'count': controller.pastTrips.length.toString(),
                      })
                    : 'profile.no_bookings'.tr,
                onTap: controller.navigateToPastTrips,
                gradient: const [Color(0xFF6366F1), Color(0xFF8B5CF6)],
              ),
            ),

            const SizedBox(height: 16),

            // Account Section
            _buildAnimatedSection(
              delay: 200,
              child: _buildMenuSection(context, [
                _buildGlassTile(
                  icon: Icons.settings_rounded,
                  title: 'profile.account_settings'.tr,
                  subtitle: 'profile.manage_prefs'.tr,
                  onTap: controller.navigateToAccountSettings,
                  gradient: const [Color(0xFF10B981), Color(0xFF059669)],
                ),
                _buildGlassTile(
                  icon: Icons.help_center_rounded,
                  title: 'profile.get_help'.tr,
                  subtitle: 'profile.support_faqs'.tr,
                  onTap: controller.navigateToHelp,
                  gradient: const [Color(0xFFF59E0B), Color(0xFFD97706)],
                ),
                _buildGlassTile(
                  icon: Icons.person_rounded,
                  title: 'profile.view_profile'.tr,
                  subtitle: 'profile.see_public_profile'.tr,
                  onTap: controller.navigateToViewProfile,
                  gradient: const [Color(0xFF3B82F6), Color(0xFF1D4ED8)],
                ),
              ]),
            ),

            const SizedBox(height: 16),

            // Legal Section
            _buildAnimatedSection(
              delay: 300,
              child: _buildMenuSection(context, [
                _buildGlassTile(
                  icon: Icons.shield_rounded,
                  title: 'profile.privacy'.tr,
                  subtitle: 'profile.data_privacy_settings'.tr,
                  onTap: controller.navigateToPrivacy,
                  gradient: const [Color(0xFF8B5CF6), Color(0xFF7C3AED)],
                ),
                _buildGlassTile(
                  icon: Icons.description_rounded,
                  title: 'profile.legal'.tr,
                  subtitle: 'profile.terms_policies'.tr,
                  onTap: controller.navigateToLegal,
                  gradient: const [Color(0xFF6B7280), Color(0xFF4B5563)],
                ),
              ]),
            ),

            const SizedBox(height: 16),

            // Logout Section
            _buildAnimatedSection(
              delay: 400,
              child: _buildGlassTile(
                icon: Icons.logout_rounded,
                title: 'profile.logout'.tr,
                subtitle: 'profile.sign_out'.tr,
                onTap: controller.logout,
                gradient: const [Color(0xFFEF4444), Color(0xFFDC2626)],
                showArrow: false,
              ),
            ),

            const SizedBox(height: 40),

            // Version Info
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 1000),
              curve: Curves.easeOut,
              builder: (context, value, child) {
                return Opacity(
                  opacity: value,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.7),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.8),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      'profile.version_info'.tr,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF6B7280),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsSection(BuildContext context) {
    final colors = context.colors;
    return _buildAnimatedSection(
      delay: 0,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              colors.surface,
              colors.surfaceContainerHighest.withValues(alpha: 0.6),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: context.isDark
                  ? Colors.black.withValues(alpha: 0.4)
                  : Colors.black.withValues(alpha: 0.05),
              blurRadius: 20,
              spreadRadius: 0,
              offset: const Offset(0, 8),
            ),
          ],
          border: Border.all(
            color: colors.outlineVariant.withValues(alpha: 0.6),
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: _buildStatItem(
                'Trips',
                '${controller.pastTrips.length}',
                Icons.flight_takeoff_rounded,
                const Color(0xFF3B82F6),
              ),
            ),
            Container(
              width: 1,
              height: 40,
              color: colors.outlineVariant.withValues(alpha: 0.6),
            ),
            Expanded(
              child: _buildStatItem(
                'Wishlist',
                '12',
                Icons.favorite_rounded,
                const Color(0xFFEF4444),
              ),
            ),
            Container(
              width: 1,
              height: 40,
              color: colors.outlineVariant.withValues(alpha: 0.6),
            ),
            Expanded(
              child: _buildStatItem(
                'Reviews',
                '8',
                Icons.star_rounded,
                const Color(0xFFF59E0B),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    final colors = Get.context?.colors ?? Theme.of(Get.context!).colorScheme;
    final textStyles =
        Get.context?.textStyles ?? Theme.of(Get.context!).textTheme;
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: textStyles.titleMedium?.copyWith(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: colors.onSurface,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: textStyles.bodySmall?.copyWith(
            fontSize: 12,
            color: colors.onSurface.withValues(alpha: 0.7),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildAnimatedSection({required int delay, required Widget child}) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 600 + delay),
      curve: Curves.easeOutCubic,
      builder: (context, value, _) {
        return Transform.translate(
          offset: Offset(0, 30 * (1 - value)),
          child: Opacity(opacity: value, child: child),
        );
      },
    );
  }

  Widget _buildMenuSection(BuildContext context, List<Widget> children) {
    final colors = context.colors;
    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: context.isDark
                ? Colors.black.withValues(alpha: 0.4)
                : Colors.black.withValues(alpha: 0.05),
            blurRadius: 20,
            spreadRadius: 0,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(
          color: colors.outlineVariant.withValues(alpha: 0.6),
          width: 1.5,
        ),
      ),
      child: Column(
        children: children.asMap().entries.map((entry) {
          int index = entry.key;
          Widget child = entry.value;

          if (index == children.length - 1) {
            return child;
          }

          return Column(
            children: [
              child,
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                height: 1,
                color: colors.outlineVariant.withValues(alpha: 0.5),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildGlassTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    required List<Color> gradient,
    bool showArrow = true,
  }) {
    final colors =
        Get.context?.colors ??
        Theme.of(Get.context ?? Get.overlayContext!).colorScheme;
    final textStyles =
        Get.context?.textStyles ??
        Theme.of(Get.context ?? Get.overlayContext!).textTheme;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: gradient,
                  ),
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [
                    BoxShadow(
                      color: gradient[0].withValues(alpha: 0.3),
                      blurRadius: 15,
                      spreadRadius: 0,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Icon(icon, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: textStyles.titleSmall?.copyWith(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: colors.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: textStyles.bodySmall?.copyWith(
                        fontSize: 13,
                        color: colors.onSurface.withValues(alpha: 0.7),
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
              if (showArrow)
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: colors.surfaceContainerHighest.withValues(
                      alpha: 0.6,
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.arrow_forward_ios_rounded,
                    color: colors.onSurface.withValues(alpha: 0.6),
                    size: 14,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
