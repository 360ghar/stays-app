import 'package:flutter/material.dart';

// ===============================================
// ANIMATED REFRESH ICON
// ===============================================

/// Animated refresh icon with rotation and pulse
class AnimatedRefreshIcon extends StatefulWidget {
  const AnimatedRefreshIcon({super.key});

  @override
  State<AnimatedRefreshIcon> createState() => _AnimatedRefreshIconState();
}

class _AnimatedRefreshIconState extends State<AnimatedRefreshIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _rotationAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    );

    _rotationAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.linear),
    );

    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 1.15),
        weight: 50,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.15, end: 1.0),
        weight: 50,
      ),
    ]).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    _controller.repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Transform.rotate(
            angle: _rotationAnimation.value * 6.28318, // 2π
            child: Icon(
              Icons.refresh_rounded,
              color: colorScheme.primary,
              size: 28,
            ),
          ),
        );
      },
    );
  }
}

// ===============================================
// SMART REFRESH WIDGET
// ===============================================

/// A smart refresh wrapper that adds pull-to-refresh with animated feedback.
/// Use this to easily add refresh functionality to any scrollable content.
class SmartRefresh extends StatefulWidget {
  const SmartRefresh({
    super.key,
    required this.onRefresh,
    required this.child,
    this.enabled = true,
    this.color,
    this.backgroundColor,
  });

  final Future<void> Function() onRefresh;
  final Widget child;
  final bool enabled;
  final Color? color;
  final Color? backgroundColor;

  @override
  State<SmartRefresh> createState() => _SmartRefreshState();
}

class _SmartRefreshState extends State<SmartRefresh> {
  bool _isRefreshing = false;

  Future<void> _handleRefresh() async {
    if (_isRefreshing) return;

    setState(() => _isRefreshing = true);

    try {
      await widget.onRefresh();
    } finally {
      if (mounted) {
        setState(() => _isRefreshing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) {
      return widget.child;
    }

    return RefreshIndicator(
      onRefresh: _handleRefresh,
      color: widget.color ?? Theme.of(context).colorScheme.primary,
      backgroundColor: widget.backgroundColor ??
          Theme.of(context).colorScheme.surface,
      displacement: 60.0,
      strokeWidth: 3,
      child: widget.child,
    );
  }
}
