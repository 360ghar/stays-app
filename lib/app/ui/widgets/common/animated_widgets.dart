import 'package:flutter/material.dart';
import '../../theme/app_animations.dart';

// ===============================================
// STAGGERED LIST ITEM WIDGET
// ===============================================

/// A list item that animates in with a staggered delay.
/// Use this for any list that should animate items sequentially.
class StaggeredListItem extends StatelessWidget {
  const StaggeredListItem({
    super.key,
    required this.index,
    required this.child,
    this.duration = AppAnimations.listItemDuration,
    this.curve = AppAnimations.listItemCurve,
    this.staggerDelay = AppAnimations.staggerDelay,
    this.offset = const Offset(0, 30),
  });

  final int index;
  final Widget child;
  final Duration duration;
  final Curve curve;
  final Duration staggerDelay;
  final Offset offset;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: duration,
      curve: curve,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(offset.dx, offset.dy * (1 - value)),
          child: Opacity(
            opacity: value,
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}

// ===============================================
// ANIMATED SCALE WRAPPER
// ===============================================

/// Wraps a widget with press-scale animation.
/// Use this for buttons, cards, and interactive elements.
class AnimatedScaleWrapper extends StatefulWidget {
  const AnimatedScaleWrapper({
    super.key,
    required this.child,
    this.onTap,
    this.onLongPress,
    this.scaleFactor = 0.95,
    this.duration = AppAnimations.cardPressDuration,
    this.curve = AppAnimations.cardPressCurve,
    this.enabled = true,
  });

  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final double scaleFactor;
  final Duration duration;
  final Curve curve;
  final bool enabled;

  @override
  State<AnimatedScaleWrapper> createState() => _AnimatedScaleWrapperState();
}

class _AnimatedScaleWrapperState extends State<AnimatedScaleWrapper>
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
      end: widget.scaleFactor,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: widget.curve,
      reverseCurve: widget.curve.flipped,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    if (!widget.enabled) return;
    setState(() => _isPressed = true);
    _controller.forward();
  }

  void _handleTapUp(TapUpDetails details) {
    if (_isPressed) {
      setState(() => _isPressed = false);
      _controller.reverse();
    }
  }

  void _handleTapCancel() {
    if (_isPressed) {
      setState(() => _isPressed = false);
      _controller.reverse();
    }
  }

  void _handleTap() {
    widget.onTap?.call();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      onTap: widget.onTap != null ? _handleTap : null,
      onLongPress: widget.onLongPress,
      behavior: HitTestBehavior.opaque,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: widget.child,
      ),
    );
  }
}

// ===============================================
// ANIMATED FADE IN WIDGET
// ===============================================

/// A widget that fades in when first displayed.
/// Use this for page content, dialogs, and overlays.
class AnimatedFadeIn extends StatelessWidget {
  const AnimatedFadeIn({
    super.key,
    required this.child,
    this.duration = AppAnimations.normal,
    this.curve = AppAnimations.easeOut,
    this.delay = Duration.zero,
    this.slideOffset,
  });

  final Widget child;
  final Duration duration;
  final Curve curve;
  final Duration delay;
  final Offset? slideOffset;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: delay + duration,
      curve: curve,
      builder: (context, value, child) {
        final animatedChild = Opacity(
          opacity: value,
          child: child,
        );

        if (slideOffset != null) {
          return Transform.translate(
            offset: Offset(
              slideOffset!.dx * (1 - value),
              slideOffset!.dy * (1 - value),
            ),
            child: animatedChild,
          );
        }

        return animatedChild;
      },
      child: child,
    );
  }
}

// ===============================================
// ANIMATED SIZE WIDGET
// ===============================================

/// A widget that animates size changes smoothly.
/// Use this for expandable sections, accordions, etc.
class AnimatedSizeWrapper extends StatelessWidget {
  const AnimatedSizeWrapper({
    super.key,
    required this.child,
    required this.isExpanded,
    this.duration = AppAnimations.medium,
    this.curve = AppAnimations.easeOutCubic,
    this.alignment = Alignment.topCenter,
  });

  final Widget child;
  final bool isExpanded;
  final Duration duration;
  final Curve curve;
  final Alignment alignment;

  @override
  Widget build(BuildContext context) {
    return AnimatedSize(
      duration: duration,
      curve: curve,
      alignment: alignment,
      child: isExpanded
          ? SizedBox(
              width: double.infinity,
              child: child,
            )
          : const SizedBox.shrink(),
    );
  }
}

// ===============================================
// ANIMATED OPACITY WIDGET
// ===============================================

/// A widget that animates opacity based on a boolean condition.
class AnimatedVisibility extends StatelessWidget {
  const AnimatedVisibility({
    super.key,
    required this.child,
    required this.visible,
    this.duration = AppAnimations.fast,
    this.curve = AppAnimations.easeOut,
    this.includeSemantics = true,
  });

  final Widget child;
  final bool visible;
  final Duration duration;
  final Curve curve;
  final bool includeSemantics;

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: visible ? 1.0 : 0.0,
      duration: duration,
      curve: curve,
      child: Visibility(
        visible: visible || includeSemantics,
        maintainState: true,
        maintainAnimation: true,
        maintainSize: true,
        child: child,
      ),
    );
  }
}

// ===============================================
// PULSE ANIMATION WIDGET
// ===============================================

/// A widget that pulses continuously.
/// Use for attention-grabbing elements like notification badges.
class AnimatedPulse extends StatefulWidget {
  const AnimatedPulse({
    super.key,
    required this.child,
    this.minScale = 1.0,
    this.maxScale = 1.1,
    this.duration = const Duration(milliseconds: 1000),
    this.curve = Curves.easeInOut,
  });

  final Widget child;
  final double minScale;
  final double maxScale;
  final Duration duration;
  final Curve curve;

  @override
  State<AnimatedPulse> createState() => _AnimatedPulseState();
}

class _AnimatedPulseState extends State<AnimatedPulse>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(
      begin: widget.minScale,
      end: widget.maxScale,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: widget.curve,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: widget.child,
    );
  }
}

// ===============================================
// SHIMMER LOADING WIDGET
// ===============================================

/// A shimmer effect for loading states.
/// Use this for skeleton loaders.
class ShimmerLoading extends StatefulWidget {
  const ShimmerLoading({
    super.key,
    required this.child,
    this.baseColor = const Color(0xFFE0E0E0),
    this.highlightColor = const Color(0xFFF5F5F5),
    this.direction = ShimmerDirection.ltr,
  });

  final Widget child;
  final Color baseColor;
  final Color highlightColor;
  final ShimmerDirection direction;

  @override
  State<ShimmerLoading> createState() => _ShimmerLoadingState();
}

enum ShimmerDirection { ltr, rtl, ttb, btt }

class _ShimmerLoadingState extends State<ShimmerLoading>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();

    _animation = Tween<double>(begin: -2, end: 2).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      blendMode: BlendMode.srcATop,
      shaderCallback: (bounds) {
        final begin = widget.direction == ShimmerDirection.ltr ||
                widget.direction == ShimmerDirection.rtl
            ? Alignment.centerLeft
            : Alignment.topCenter;

        final end = widget.direction == ShimmerDirection.ltr ||
                widget.direction == ShimmerDirection.rtl
            ? Alignment.centerRight
            : Alignment.bottomCenter;

        return LinearGradient(
          begin: begin,
          end: end,
          colors: [
            widget.baseColor,
            widget.highlightColor,
            widget.baseColor,
          ],
          stops: const [0.0, 0.5, 1.0],
          transform: _SlidingGradientTransform(
            slidePercent: _animation.value,
            direction: widget.direction,
          ),
        ).createShader(bounds);
      },
      child: widget.child,
    );
  }
}

class _SlidingGradientTransform extends GradientTransform {
  const _SlidingGradientTransform({
    required this.slidePercent,
    required this.direction,
  });

  final double slidePercent;
  final ShimmerDirection direction;

  @override
  Matrix4? transform(Rect bounds, {TextDirection? textDirection}) {
    switch (direction) {
      case ShimmerDirection.ltr:
        return Matrix4.translationValues(bounds.width * slidePercent, 0, 0);
      case ShimmerDirection.rtl:
        return Matrix4.translationValues(-bounds.width * slidePercent, 0, 0);
      case ShimmerDirection.ttb:
        return Matrix4.translationValues(0, bounds.height * slidePercent, 0);
      case ShimmerDirection.btt:
        return Matrix4.translationValues(0, -bounds.height * slidePercent, 0);
    }
  }
}
