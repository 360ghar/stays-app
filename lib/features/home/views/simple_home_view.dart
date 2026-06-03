import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:stays_app/app/ui/theme/app_animations.dart';
import 'package:stays_app/features/messaging/controllers/hotels_map_controller.dart';
import 'package:stays_app/features/home/controllers/navigation_controller.dart';
import 'package:stays_app/features/messaging/views/locate_view.dart';
import 'package:stays_app/features/inquiry/views/inquiry_page.dart';
import 'package:stays_app/features/wishlist/views/wishlist_view.dart';
import 'package:stays_app/features/explore/views/explore_view.dart';
import 'package:stays_app/features/profile/views/profile_view.dart';

class SimpleHomeView extends StatefulWidget {
  const SimpleHomeView({super.key});

  @override
  State<SimpleHomeView> createState() => _SimpleHomeViewState();
}

class _SimpleHomeViewState extends State<SimpleHomeView> {
  late final NavigationController controller;

  @override
  void initState() {
    super.initState();
    controller = Get.find<NavigationController>();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      extendBody: true,
      body: PageView.builder(
        controller: controller.pageController,
        itemCount: 5,
        onPageChanged: (index) {
          controller.currentIndex.value = index;
          if (index == 3 && Get.isRegistered<HotelsMapController>()) {
            Get.find<HotelsMapController>().getCurrentLocation();
          }
        },
        itemBuilder: (context, index) {
          return switch (index) {
            0 => const ExploreView(),
            1 => const WishlistView(),
            2 => InquiriesPage(),
            3 => const LocateView(),
            4 => const ProfileView(),
            _ => const SizedBox.shrink(),
          };
        },
      ),
      bottomNavigationBar: _PremiumBottomNav(
        controller: controller,
        isDark: isDark,
      ),
    );
  }
}

/// Premium bottom navigation bar with glassmorphism and fluid animations.
class _PremiumBottomNav extends StatelessWidget {
  final NavigationController controller;
  final bool isDark;

  const _PremiumBottomNav({
    required this.controller,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      height: 72,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            colorScheme.surface.withValues(alpha: 0.0),
            if (isDark)
              colorScheme.surface.withValues(alpha: 0.9)
            else
              colorScheme.surface.withValues(alpha: 0.95),
            colorScheme.surface,
          ],
          stops: const [0.0, 0.3, 1.0],
        ),
      ),
      child: SafeArea(
        top: false,
        child: Container(
          height: 56,
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(
            color: colorScheme.surface.withValues(alpha: isDark ? 0.92 : 0.96),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: colorScheme.outlineVariant.withValues(alpha: isDark ? 0.35 : 0.5),
              width: 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.08),
                blurRadius: 20,
                offset: const Offset(0, 10),
                spreadRadius: -5,
              ),
              if (!isDark)
                BoxShadow(
                  color: colorScheme.primary.withValues(alpha: 0.05),
                  blurRadius: 20,
                  offset: const Offset(0, -5),
                ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Obx(
                () => Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: controller.tabs.asMap().entries.map((entry) {
                    final index = entry.key;
                    final tab = entry.value;
                    final isActive = controller.currentIndex.value == index;
                    return Expanded(
                      child: _PremiumNavItem(
                        icon: tab.icon,
                        labelKey: tab.labelKey,
                        isActive: isActive,
                        onTap: () => controller.changeTab(index),
                        isFirst: index == 0,
                        isLast: index == controller.tabs.length - 1,
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PremiumNavItem extends StatefulWidget {
  const _PremiumNavItem({
    required this.icon,
    required this.labelKey,
    required this.isActive,
    required this.onTap,
    this.isFirst = false,
    this.isLast = false,
  });

  final IconData icon;
  final String labelKey;
  final bool isActive;
  final VoidCallback onTap;
  final bool isFirst;
  final bool isLast;

  @override
  State<_PremiumNavItem> createState() => _PremiumNavItemState();
}

class _PremiumNavItemState extends State<_PremiumNavItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _iconScaleAnimation;
  late Animation<double> _textFadeAnimation;
  late Animation<double> _indicatorAnimation;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: AppAnimations.normal,
      vsync: this,
    );

    // Premium icon bounce with overshoot
    _iconScaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 0.85),
        weight: 25,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.85, end: 1.08),
        weight: 35,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.08, end: 1.0),
        weight: 40,
      ),
    ]).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));

    // Text fade in with delay
    _textFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.3, 1.0, curve: Curves.easeOut),
      ),
    );

    // Active indicator expansion
    _indicatorAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOutCubic),
      ),
    );

    // Glow pulse for active state
    _glowAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.4, 1.0, curve: Curves.easeOut),
      ),
    );

    if (widget.isActive) {
      _controller.value = 1.0;
    }
  }

  @override
  void didUpdateWidget(_PremiumNavItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive != oldWidget.isActive) {
      if (widget.isActive) {
        _controller.forward(from: 0);
      } else {
        _controller.reverse();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final activeColor = colorScheme.primary;
    final inactiveColor = colorScheme.onSurface.withValues(alpha: 0.55);
    const indicatorWidth = 46.0;
    const indicatorHeight = 28.0;
    const labelSpacing = 4.0;
    const iconSize = 22.0;

    return GestureDetector(
      onTap: widget.onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        color: Colors.transparent,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              final iconColor = Color.lerp(
                    inactiveColor,
                    activeColor,
                    _controller.value,
                  ) ??
                  activeColor;
              final labelColor = Color.lerp(
                    inactiveColor,
                    activeColor,
                    _textFadeAnimation.value,
                  ) ??
                  activeColor;
              final labelOpacity =
                  lerpDouble(0.65, 1.0, _textFadeAnimation.value) ?? 1.0;

              return Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    height: indicatorHeight,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Active indicator background with glow
                        if (widget.isActive)
                          Transform.scale(
                            scale: _indicatorAnimation.value,
                            child: Container(
                              width: indicatorWidth,
                              height: indicatorHeight,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    activeColor
                                        .withValues(alpha: 0.15 * _glowAnimation.value),
                                    activeColor
                                        .withValues(alpha: 0.08 * _glowAnimation.value),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: activeColor
                                      .withValues(alpha: 0.1 * _glowAnimation.value),
                                  width: 1,
                                ),
                              ),
                            ),
                          ),

                        // Icon centered within the indicator
                        Transform.scale(
                          scale: _iconScaleAnimation.value,
                          child: Icon(
                            widget.icon,
                            color: iconColor,
                            size: iconSize,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: labelSpacing),
                  Opacity(
                    opacity: labelOpacity,
                    child: Transform.translate(
                      offset: Offset(0, 2 * (1 - _textFadeAnimation.value)),
                      child: Text(
                        widget.labelKey.tr,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight:
                              widget.isActive ? FontWeight.w600 : FontWeight.w500,
                          color: labelColor,
                          letterSpacing: 0.3,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
