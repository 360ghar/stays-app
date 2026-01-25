import 'dart:ui';
import 'package:flutter/material.dart';
import 'app_animations.dart';

// ===============================================
// PREMIUM PAGE TRANSITIONS
// ===============================================

/// Premium fade-in slide-up transition with parallax.
/// Use for bottom sheets, dialogs, and modal presentations.
class FadeInUpTransition extends PageRouteBuilder<void> {
  FadeInUpTransition({
    required this.page,
    this.duration = AppAnimations.pageTransitionDuration,
    this.curve = AppAnimations.pageTransitionCurve,
  }) : super(
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionDuration: duration,
          reverseTransitionDuration: const Duration(milliseconds: 250),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            const begin = Offset(0.0, 0.08);
            const end = Offset.zero;
            final tween = Tween(begin: begin, end: end);
            final offsetAnimation = animation.drive(tween.chain(CurveTween(curve: curve)));

            // Parallax effect on background
            final parallaxAnimation = Tween<double>(
              begin: 0,
              end: 0.03,
            ).animate(CurvedAnimation(parent: secondaryAnimation, curve: curve));

            return FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position: offsetAnimation,
                child: Transform.translate(
                  offset: Offset(0, -100 * parallaxAnimation.value),
                  child: child,
                ),
              ),
            );
          },
        );

  final Widget page;
  final Duration duration;
  final Curve curve;
}

/// Slide-in from right transition (iOS style).
/// Use for navigation between related screens.
class SlideInRightTransition extends PageRouteBuilder<void> {
  SlideInRightTransition({
    required this.page,
    this.duration = AppAnimations.pageTransitionDuration,
    this.curve = AppAnimations.easeOutCubic,
  }) : super(
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionDuration: duration,
          reverseTransitionDuration: const Duration(milliseconds: 250),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            const begin = Offset(1.0, 0.0);
            const end = Offset.zero;
            final tween = Tween(begin: begin, end: end);
            final offsetAnimation = animation.drive(tween.chain(CurveTween(curve: curve)));

            // Add slight fade for smoother entrance
            final fadeAnimation = Tween<double>(begin: 0.85, end: 1.0).animate(
              CurvedAnimation(parent: animation, curve: Curves.easeOut),
            );

            // Parallax on outgoing page
            final outgoingAnimation = Tween<Offset>(
              begin: Offset.zero,
              end: const Offset(-0.1, 0.0),
            ).animate(CurvedAnimation(parent: secondaryAnimation, curve: curve));

            return SlideTransition(
              position: outgoingAnimation,
              child: Opacity(
                opacity: fadeAnimation.value,
                child: SlideTransition(
                  position: offsetAnimation,
                  child: child,
                ),
              ),
            );
          },
        );

  final Widget page;
  final Duration duration;
  final Curve curve;
}

/// Scale and fade transition with bounce effect.
/// Use for focused content, image views, and hero-like transitions.
class ScaleFadeTransition extends PageRouteBuilder<void> {
  ScaleFadeTransition({
    required this.page,
    this.duration = AppAnimations.pageTransitionDuration,
    this.curve = AppAnimations.fastOutSlowIn,
    this.alignment = Alignment.center,
  }) : super(
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionDuration: duration,
          reverseTransitionDuration: const Duration(milliseconds: 200),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            // Use scale from 0.95 to 1.0 for subtle effect
            final scaleAnimation = Tween<double>(begin: 0.92, end: 1.0).animate(
              CurvedAnimation(parent: animation, curve: curve),
            );

            return FadeTransition(
              opacity: animation,
              child: ScaleTransition(
                scale: scaleAnimation,
                alignment: alignment,
                child: child,
              ),
            );
          },
        );

  final Widget page;
  final Duration duration;
  final Curve curve;
  final Alignment alignment;
}

/// Material-inspired shared axis transition.
/// Use for navigation that feels like moving along an axis.
class SharedAxisTransition extends PageRouteBuilder<void> {
  SharedAxisTransition({
    required this.page,
    required this.type,
    this.duration = AppAnimations.pageTransitionDuration,
    this.fillColor = Colors.black,
  }) : super(
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionDuration: duration,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            switch (type) {
              case SharedAxisTransitionType.horizontal:
                return _buildHorizontalTransition(animation, secondaryAnimation, child);
              case SharedAxisTransitionType.vertical:
                return _buildVerticalTransition(animation, secondaryAnimation, child);
              case SharedAxisTransitionType.scaled:
                return _buildScaledTransition(animation, secondaryAnimation, child);
            }
          },
        );

  final Widget page;
  final SharedAxisTransitionType type;
  final Duration duration;
  final Color fillColor;

  static Widget _buildHorizontalTransition(Animation<double> animation, Animation<double> secondaryAnimation, Widget child) {
    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(1.0, 0.0),
        end: Offset.zero,
      ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)),
      child: SlideTransition(
        position: Tween<Offset>(
          begin: Offset.zero,
          end: const Offset(-0.3, 0.0),
        ).animate(CurvedAnimation(parent: secondaryAnimation, curve: Curves.easeOutCubic)),
        child: child,
      ),
    );
  }

  static Widget _buildVerticalTransition(Animation<double> animation, Animation<double> secondaryAnimation, Widget child) {
    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(0.0, 1.0),
        end: Offset.zero,
      ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)),
      child: FadeTransition(
        opacity: Tween<double>(begin: 0.0, end: 1.0).animate(
          CurvedAnimation(parent: animation, curve: Curves.easeOut),
        ),
        child: child,
      ),
    );
  }

  static Widget _buildScaledTransition(Animation<double> animation, Animation<double> secondaryAnimation, Widget child) {
    return FadeTransition(
      opacity: Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: animation, curve: Curves.easeOut),
      ),
      child: ScaleTransition(
        scale: Tween<double>(begin: 0.9, end: 1.0).animate(
          CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
        ),
        child: child,
      ),
    );
  }
}

enum SharedAxisTransitionType { horizontal, vertical, scaled }

/// iOS-style parallax transition.
/// Simulates iOS navigation with parallax effect on the previous page.
class IOSParallaxTransition extends PageRouteBuilder<void> {
  IOSParallaxTransition({
    required this.page,
    this.duration = AppAnimations.pageTransitionDuration,
    this.curve = AppAnimations.easeOutCubic,
  }) : super(
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionDuration: duration,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            // Parallax effect on incoming page
            final slideIn = Tween<Offset>(
              begin: const Offset(1.0, 0.0),
              end: Offset.zero,
            ).animate(CurvedAnimation(parent: animation, curve: curve));

            return SlideTransition(
              position: slideIn,
              child: Opacity(
                opacity: Tween<double>(begin: 0.95, end: 1.0).animate(
                  CurvedAnimation(parent: animation, curve: curve),
                ).value,
                child: child,
              ),
            );
          },
        );

  final Widget page;
  final Duration duration;
  final Curve curve;
}

/// Rotation 3D flip transition.
/// Use for unique, memorable transitions between unrelated screens.
class Flip3DTransition extends PageRouteBuilder<void> {
  Flip3DTransition({
    required this.page,
    this.duration = AppAnimations.slower,
    this.curve = AppAnimations.easeOutCubic,
  }) : super(
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionDuration: duration,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return AnimatedBuilder(
              animation: animation,
              builder: (context, child) {
                final angle = animation.value * 3.14159;
                return Transform(
                  alignment: Alignment.center,
                  transform: Matrix4.identity()
                    ..setEntry(3, 2, 0.001)
                    ..rotateY(angle),
                  child: animation.value < 0.5
                      ? Opacity(
                          opacity: 1 - animation.value * 2,
                          child: child,
                        )
                      : Opacity(
                          opacity: (animation.value - 0.5) * 2,
                          child: child,
                        ),
                );
              },
              child: child,
            );
          },
        );

  final Widget page;
  final Duration duration;
  final Curve curve;
}

/// Premium glassmorphism transition with blur effect.
/// Creates a frosted glass effect during the transition.
class GlassTransition extends PageRouteBuilder<void> {
  GlassTransition({
    required this.page,
    this.duration = AppAnimations.pageTransitionDuration,
    this.curve = AppAnimations.easeOutCubic,
  }) : super(
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionDuration: duration,
          reverseTransitionDuration: const Duration(milliseconds: 250),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            final opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
              CurvedAnimation(parent: animation, curve: curve),
            );

            final scaleAnimation = Tween<double>(begin: 0.95, end: 1.0).animate(
              CurvedAnimation(parent: animation, curve: curve),
            );

            final blurAnimation = Tween<double>(begin: 10.0, end: 0.0).animate(
              CurvedAnimation(parent: animation, curve: curve),
            );

            return ClipRect(
              child: FadeTransition(
                opacity: opacityAnimation,
                child: ScaleTransition(
                  scale: scaleAnimation,
                  child: BackdropFilter(
                    filter: ImageFilter.blur(
                      sigmaX: blurAnimation.value,
                      sigmaY: blurAnimation.value,
                    ),
                    child: child,
                  ),
                ),
              ),
            );
          },
        );

  final Widget page;
  final Duration duration;
  final Curve curve;
}

/// Rotate and scale transition with depth effect.
/// Creates a cinematic entrance with rotation.
class RotateScaleTransition extends PageRouteBuilder<void> {
  RotateScaleTransition({
    required this.page,
    this.duration = AppAnimations.slower,
    this.curve = AppAnimations.easeOutCubic,
  }) : super(
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionDuration: duration,
          reverseTransitionDuration: const Duration(milliseconds: 300),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            final curvedAnimation = CurvedAnimation(parent: animation, curve: curve);

            final opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
              CurvedAnimation(parent: animation, curve: const Interval(0.0, 0.6, curve: Curves.easeOut)),
            );

            final rotationAnimation = Tween<double>(begin: -0.1, end: 0.0).animate(curvedAnimation);
            final scaleAnimation = Tween<double>(begin: 0.85, end: 1.0).animate(curvedAnimation);

            return Opacity(
              opacity: opacityAnimation.value,
              child: Transform.rotate(
                angle: rotationAnimation.value,
                child: Transform.scale(
                  scale: scaleAnimation.value,
                  alignment: Alignment.center,
                  child: child,
                ),
              ),
            );
          },
        );

  final Widget page;
  final Duration duration;
  final Curve curve;
}

/// Expand from corner transition.
/// Creates a circular reveal effect from the bottom-right corner.
class ExpandFromCornerTransition extends PageRouteBuilder<void> {
  ExpandFromCornerTransition({
    required this.page,
    this.duration = AppAnimations.normal,
    this.curve = AppAnimations.easeOutCubic,
    this.alignment = Alignment.bottomRight,
  }) : super(
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionDuration: duration,
          reverseTransitionDuration: const Duration(milliseconds: 200),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            final curvedAnimation = CurvedAnimation(parent: animation, curve: curve);

            final scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(curvedAnimation);
            final opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
              CurvedAnimation(parent: animation, curve: const Interval(0.3, 1.0)),
            );

            return ClipRect(
              child: Align(
                alignment: alignment,
                child: FadeTransition(
                  opacity: opacityAnimation,
                  child: FractionalTranslation(
                    translation: Offset.zero,
                    child: Transform.scale(
                      scale: scaleAnimation.value,
                      alignment: alignment,
                      child: child,
                    ),
                  ),
                ),
              ),
            );
          },
        );

  final Widget page;
  final Duration duration;
  final Curve curve;
  final Alignment alignment;
}

/// Slide and fade transition with stagger effect.
/// Elements slide in with different timing for a cascading effect.
class StaggeredSlideTransition extends PageRouteBuilder<void> {
  StaggeredSlideTransition({
    required this.page,
    this.duration = AppAnimations.normal,
    this.curve = AppAnimations.easeOutCubic,
  }) : super(
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionDuration: duration,
          reverseTransitionDuration: const Duration(milliseconds: 200),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            final curvedAnimation = CurvedAnimation(parent: animation, curve: curve);

            final slideAnimation = Tween<Offset>(
              begin: const Offset(0.0, 0.15),
              end: Offset.zero,
            ).animate(curvedAnimation);

            final opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
              CurvedAnimation(parent: animation, curve: const Interval(0.2, 1.0)),
            );

            return SlideTransition(
              position: slideAnimation,
              child: FadeTransition(
                opacity: opacityAnimation,
                child: child,
              ),
            );
          },
        );

  final Widget page;
  final Duration duration;
  final Curve curve;
}

/// No transition - instant page change.
/// Use for tab switching or when transitions aren't desired.
class InstantTransition extends PageRouteBuilder<void> {
  InstantTransition({required Widget page})
    : super(
        pageBuilder: (context, animation, secondaryAnimation) => page,
        transitionDuration: Duration.zero,
        reverseTransitionDuration: Duration.zero,
        transitionsBuilder: (context, animation, secondaryAnimation, child) => child,
      );
}

// ===============================================
// NAVIGATION HELPERS
// ===============================================

/// Extension for easy navigation with custom transitions.
extension CustomNavigationExtension on BuildContext {
  /// Push with fade-in-up transition
  Future<T?> fadeInUp<T>({required Widget page}) {
    return Navigator.push<T>(
      this,
      FadeInUpTransition(page: page) as Route<T>,
    );
  }

  /// Push with slide-in-right transition
  Future<T?> slideInRight<T>({required Widget page}) {
    return Navigator.push<T>(
      this,
      SlideInRightTransition(page: page) as Route<T>,
    );
  }

  /// Push with scale-fade transition
  Future<T?> scaleFade<T>({required Widget page, Alignment alignment = Alignment.center}) {
    return Navigator.push<T>(
      this,
      ScaleFadeTransition(page: page, alignment: alignment) as Route<T>,
    );
  }

  /// Push with shared axis transition
  Future<T?> sharedAxis<T>({
    required Widget page,
    SharedAxisTransitionType type = SharedAxisTransitionType.horizontal,
  }) {
    return Navigator.push<T>(
      this,
      SharedAxisTransition(page: page, type: type) as Route<T>,
    );
  }

  /// Push with iOS parallax transition
  Future<T?> iosParallax<T>({required Widget page}) {
    return Navigator.push<T>(
      this,
      IOSParallaxTransition(page: page) as Route<T>,
    );
  }

  /// Push with 3D flip transition
  Future<T?> flip3D<T>({required Widget page}) {
    return Navigator.push<T>(
      this,
      Flip3DTransition(page: page) as Route<T>,
    );
  }

  /// Replace current route with custom transition
  Future<T?> replaceWithTransition<T>({required Widget page, required Widget newPage}) {
    return Navigator.pushReplacement<T, dynamic>(
      this,
      FadeInUpTransition(page: newPage) as Route<T>,
    );
  }

  /// Push with glassmorphism transition
  Future<T?> glass<T>({required Widget page}) {
    return Navigator.push<T>(
      this,
      GlassTransition(page: page) as Route<T>,
    );
  }

  /// Push with rotate and scale transition
  Future<T?> rotateScale<T>({required Widget page}) {
    return Navigator.push<T>(
      this,
      RotateScaleTransition(page: page) as Route<T>,
    );
  }

  /// Push with expand from corner transition
  Future<T?> expandFromCorner<T>({
    required Widget page,
    Alignment alignment = Alignment.bottomRight,
  }) {
    return Navigator.push<T>(
      this,
      ExpandFromCornerTransition(page: page, alignment: alignment) as Route<T>,
    );
  }

  /// Push with staggered slide transition
  Future<T?> staggeredSlide<T>({required Widget page}) {
    return Navigator.push<T>(
      this,
      StaggeredSlideTransition(page: page) as Route<T>,
    );
  }
}
