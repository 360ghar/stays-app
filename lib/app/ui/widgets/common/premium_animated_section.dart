import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:stays_app/app/ui/theme/app_animations.dart';

/// A premium animated section wrapper that staggers entrance animations
/// for child widgets, creating a cascading reveal effect.
class PremiumAnimatedSection extends StatefulWidget {
  final Widget child;
  final int index;
  final Duration delay;
  final Duration duration;
  final Curve curve;
  final Offset slideOffset;
  final bool autoStart;

  const PremiumAnimatedSection({
    super.key,
    required this.child,
    this.index = 0,
    this.delay = Duration.zero,
    this.duration = AppAnimations.medium,
    this.curve = AppAnimations.easeOutCubic,
    this.slideOffset = const Offset(0, 0.05),
    this.autoStart = true,
  });

  @override
  State<PremiumAnimatedSection> createState() => _PremiumAnimatedSectionState();
}

class _PremiumAnimatedSectionState extends State<PremiumAnimatedSection>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacityAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;
  bool _hasStarted = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );

    // Opacity animation
    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Interval(0.0, 0.6, curve: widget.curve),
      ),
    );

    // Slide animation
    _slideAnimation = Tween<Offset>(
      begin: widget.slideOffset,
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Interval(0.0, 1.0, curve: widget.curve),
      ),
    );

    // Subtle scale animation
    _scaleAnimation = Tween<double>(begin: 0.96, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Interval(0.0, 0.8, curve: widget.curve),
      ),
    );

    if (widget.autoStart) {
      _startAnimation();
    }
  }

  void _startAnimation() {
    if (!_hasStarted) {
      _hasStarted = true;
      Future.delayed(widget.delay, () {
        if (mounted) {
          _controller.forward();
        }
      });
    }
  }

  @override
  void didUpdateWidget(PremiumAnimatedSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.autoStart && !_hasStarted) {
      _startAnimation();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Opacity(
          opacity: _opacityAnimation.value,
          child: Transform.translate(
            offset: Offset(
              _slideAnimation.value.dx * MediaQuery.of(context).size.width,
              _slideAnimation.value.dy * MediaQuery.of(context).size.height,
            ),
            child: Transform.scale(
              scale: _scaleAnimation.value,
              child: child,
            ),
          ),
        );
      },
      child: widget.child,
    );
  }
}

/// A list builder with staggered entrance animations.
class StaggeredAnimatedList extends StatelessWidget {
  final int itemCount;
  final Widget Function(BuildContext, int) itemBuilder;
  final Duration delay;
  final Duration duration;
  final Curve curve;
  final Offset slideOffset;

  const StaggeredAnimatedList({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
    this.delay = Duration.zero,
    this.duration = AppAnimations.medium,
    this.curve = AppAnimations.easeOutCubic,
    this.slideOffset = const Offset(0, 0.05),
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (int i = 0; i < itemCount; i++)
          PremiumAnimatedSection(
            key: ValueKey('item_$i'),
            index: i,
            delay: delay,
            duration: duration,
            curve: curve,
            slideOffset: slideOffset,
            child: itemBuilder(context, i),
          ),
      ],
    );
  }
}

/// A container with premium entrance animation.
class PremiumAnimatedContainer extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final Duration duration;
  final Curve curve;
  final double scaleOnPress;
  final bool enableRipple;

  const PremiumAnimatedContainer({
    super.key,
    required this.child,
    this.onTap,
    this.duration = AppAnimations.fast,
    this.curve = AppAnimations.easeOutCubic,
    this.scaleOnPress = 0.96,
    this.enableRipple = true,
  });

  @override
  State<PremiumAnimatedContainer> createState() => _PremiumAnimatedContainerState();
}

class _PremiumAnimatedContainerState extends State<PremiumAnimatedContainer>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: widget.scaleOnPress,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: widget.curve,
      ),
    );

    // Start entrance animation
    _controller.forward();
  }

  void _handleTapDown(TapDownDetails details) {
    setState(() => _isPressed = true);
    _controller.reverse();
  }

  void _handleTapUp(TapUpDetails details) {
    setState(() => _isPressed = false);
    _controller.forward();
  }

  void _handleTapCancel() {
    setState(() => _isPressed = false);
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      onTapDown: widget.onTap != null ? _handleTapDown : null,
      onTapUp: widget.onTap != null ? _handleTapUp : null,
      onTapCancel: widget.onTap != null ? _handleTapCancel : null,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: widget.child,
      ),
    );
  }
}

/// A glassmorphism container with blur effect.
class GlassContainer extends StatelessWidget {
  final Widget child;
  final double blur;
  final double opacity;
  final double borderRadius;
  final Border? border;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;
  final LinearGradient? gradient;
  final BoxShadow? shadow;

  const GlassContainer({
    super.key,
    required this.child,
    this.blur = 10,
    this.opacity = 0.1,
    this.borderRadius = 20,
    this.border,
    this.padding = const EdgeInsets.all(16),
    this.margin = EdgeInsets.zero,
    this.gradient,
    this.shadow,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: margin,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: shadow != null
            ? [shadow!]
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: BackdropFilter(
          filter: blur == 0
              ? ImageFilter.blur(sigmaX: 0, sigmaY: 0)
              : ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              gradient: gradient ??
                  LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: isDark
                        ? [
                            const Color(0xFFFFFFFF).withValues(alpha: opacity * 0.3),
                            const Color(0xFFFFFFFF).withValues(alpha: opacity * 0.1),
                          ]
                        : [
                            const Color(0xFFFFFFFF).withValues(alpha: opacity * 0.7),
                            const Color(0xFFFFFFFF).withValues(alpha: opacity * 0.3),
                          ],
                  ),
              borderRadius: BorderRadius.circular(borderRadius),
              border: border ??
                  Border.all(
                    color: isDark
                        ? const Color(0xFFFFFFFF).withValues(alpha: 0.1)
                        : const Color(0xFFFFFFFF).withValues(alpha: 0.3),
                    width: 1,
                  ),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}
