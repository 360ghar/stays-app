import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../controllers/auth/profile_controller.dart';
import '../../widgets/profile/profile_header.dart';
import '../../widgets/profile/profile_tile.dart';
import '../../widgets/profile/section_card.dart';

class ProfileView extends GetView<ProfileController> {
  const ProfileView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: Obx(() {
        if (controller.isLoading.value && controller.profile.value == null) {
          return const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF2563EB)),
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
              _buildSliverAppBar(),
              _buildProfileContent(),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 260,
      floating: false,
      pinned: true,
      elevation: 0,
      backgroundColor: const Color(0xFFF8F9FA),
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFFF8F9FA),
                Color(0xFFE3F2FD),
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
                                colors: [
                                  Color(0xFF3B82F6),
                                  Color(0xFF1D4ED8),
                                ],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF3B82F6).withValues(alpha: 0.3),
                                  blurRadius: 20,
                                  spreadRadius: 0,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                            child: Center(
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
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1F2937),
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
                                    colors: controller.userType.value == 'Superhost'
                                        ? [Colors.amber, Colors.orange]
                                        : [const Color(0xFF3B82F6), const Color(0xFF1D4ED8)],
                                  ),
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: [
                                    BoxShadow(
                                      color: (controller.userType.value == 'Superhost'
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

  Widget _buildProfileContent() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Stats Section
            _buildStatsSection(),
            
            const SizedBox(height: 24),
            
            // Past Bookings Section
            _buildAnimatedSection(
              delay: 100,
              child: _buildGlassTile(
                icon: Icons.flight_takeoff_rounded,
                title: 'Past Bookings',
                subtitle: controller.pastTrips.isNotEmpty
                    ? '${controller.pastTrips.length} bookings completed'
                    : 'No bookings yet',
                onTap: controller.navigateToPastTrips,
                gradient: const [Color(0xFF6366F1), Color(0xFF8B5CF6)],
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Account Section
            _buildAnimatedSection(
              delay: 200,
              child: _buildMenuSection([
                _buildGlassTile(
                  icon: Icons.settings_rounded,
                  title: 'Account Settings',
                  subtitle: 'Manage your preferences',
                  onTap: controller.navigateToAccountSettings,
                  gradient: const [Color(0xFF10B981), Color(0xFF059669)],
                ),
                _buildGlassTile(
                  icon: Icons.help_center_rounded,
                  title: 'Get Help',
                  subtitle: 'Support and FAQs',
                  onTap: controller.navigateToHelp,
                  gradient: const [Color(0xFFF59E0B), Color(0xFFD97706)],
                ),
                _buildGlassTile(
                  icon: Icons.person_rounded,
                  title: 'View Profile',
                  subtitle: 'See your public profile',
                  onTap: controller.navigateToViewProfile,
                  gradient: const [Color(0xFF3B82F6), Color(0xFF1D4ED8)],
                ),
              ]),
            ),
            
            const SizedBox(height: 16),
            
            // Legal Section
            _buildAnimatedSection(
              delay: 300,
              child: _buildMenuSection([
                _buildGlassTile(
                  icon: Icons.shield_rounded,
                  title: 'Privacy',
                  subtitle: 'Data and privacy settings',
                  onTap: controller.navigateToPrivacy,
                  gradient: const [Color(0xFF8B5CF6), Color(0xFF7C3AED)],
                ),
                _buildGlassTile(
                  icon: Icons.description_rounded,
                  title: 'Legal',
                  subtitle: 'Terms and policies',
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
                title: 'Log Out',
                subtitle: 'Sign out of your account',
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
                    child: const Text(
                      'Version 1.0.0 • Made with ❤️',
                      style: TextStyle(
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

  Widget _buildStatsSection() {
    return _buildAnimatedSection(
      delay: 0,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white,
              Color(0xFFF8FAFC),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 20,
              spreadRadius: 0,
              offset: const Offset(0, 8),
            ),
          ],
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.8),
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
              color: const Color(0xFFE5E7EB),
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
              color: const Color(0xFFE5E7EB),
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

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: color,
            size: 20,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1F2937),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Color(0xFF6B7280),
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
          child: Opacity(
            opacity: value,
            child: child,
          ),
        );
      },
    );
  }

  Widget _buildMenuSection(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 20,
            spreadRadius: 0,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.8),
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
                color: const Color(0xFFF3F4F6),
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
                child: Icon(
                  icon,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1F2937),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF6B7280),
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
                    color: const Color(0xFFF8FAFC),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.arrow_forward_ios_rounded,
                    color: Color(0xFF9CA3AF),
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