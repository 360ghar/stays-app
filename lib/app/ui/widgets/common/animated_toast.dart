import 'package:flutter/material.dart';
import '../../theme/app_animations.dart';

// ===============================================
// ANIMATED TOAST NOTIFICATIONS
// ===============================================

/// Toast notification types
enum ToastType { success, error, warning, info }

/// A premium animated toast notification system.
/// Shows slide-in notifications with icons and smooth animations.
class AnimatedToast extends StatefulWidget {
  const AnimatedToast({
    super.key,
    required this.message,
    this.type = ToastType.info,
    this.duration = const Duration(seconds: 3),
    this.position = ToastPosition.top,
    this.onDismiss,
  });

  final String message;
  final ToastType type;
  final Duration duration;
  final ToastPosition position;
  final VoidCallback? onDismiss;

  /// Show a toast notification
  static void show(
    BuildContext context, {
    required String message,
    ToastType type = ToastType.info,
    Duration duration = const Duration(seconds: 3),
    ToastPosition position = ToastPosition.top,
  }) {
    final overlay = Overlay.of(context);
    late OverlayEntry overlayEntry;

    overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: position == ToastPosition.top ? 50 : null,
        bottom: position == ToastPosition.bottom ? 20 : null,
        left: 16,
        right: 16,
        child: AnimatedToast(
          message: message,
          type: type,
          duration: duration,
          position: position,
          onDismiss: () => overlayEntry.remove(),
        ),
      ),
    );

    overlay.insert(overlayEntry);
  }

  /// Convenience method for success toast
  static void success(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 3),
  }) {
    show(context, message: message, type: ToastType.success, duration: duration);
  }

  /// Convenience method for error toast
  static void error(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 4),
  }) {
    show(context, message: message, type: ToastType.error, duration: duration);
  }

  /// Convenience method for warning toast
  static void warning(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 3),
  }) {
    show(context, message: message, type: ToastType.warning, duration: duration);
  }

  /// Convenience method for info toast
  static void info(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 3),
  }) {
    show(context, message: message, type: ToastType.info, duration: duration);
  }

  @override
  State<AnimatedToast> createState() => _AnimatedToastState();
}

class _AnimatedToastState extends State<AnimatedToast>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: AppAnimations.medium,
      vsync: this,
    );

    final begin = widget.position == ToastPosition.top
        ? const Offset(0, -1)
        : const Offset(0, 1);

    _slideAnimation = Tween<Offset>(begin: begin, end: Offset.zero).animate(
      CurvedAnimation(
        parent: _controller,
        curve: AppAnimations.easeOutCubic,
      ),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.2, 1.0, curve: Curves.easeOut),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.9, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: AppAnimations.easeOutCubic,
      ),
    );

    _controller.forward();

    // Auto-dismiss after duration
    Future.delayed(widget.duration, () {
      if (mounted) {
        _dismiss();
      }
    });
  }

  void _dismiss() {
    _controller.reverse().then((_) {
      widget.onDismiss?.call();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Transform.translate(
            offset: Offset(
              _slideAnimation.value.dx * MediaQuery.of(context).size.width,
              _slideAnimation.value.dy * 100,
            ),
            child: Opacity(
              opacity: _fadeAnimation.value,
              child: Transform.scale(
                scale: _scaleAnimation.value,
                child: child,
              ),
            ),
          );
        },
        child: _ToastContent(
          message: widget.message,
          type: widget.type,
          onDismiss: _dismiss,
        ),
      ),
    );
  }
}

enum ToastPosition { top, bottom }

class _ToastContent extends StatelessWidget {
  const _ToastContent({
    required this.message,
    required this.type,
    required this.onDismiss,
  });

  final String message;
  final ToastType type;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final config = _getToastConfig(type);

    return SafeArea(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: config.backgroundColor,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.1),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            // Icon container
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: config.iconColor.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(
                config.icon,
                color: config.iconColor,
                size: 18,
              ),
            ),
            const SizedBox(width: 12),

            // Message
            Expanded(
              child: Text(
                message,
                style: TextStyle(
                  color: config.textColor,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),

            // Dismiss button
            GestureDetector(
              onTap: onDismiss,
              child: Container(
                padding: const EdgeInsets.all(4),
                child: Icon(
                  Icons.close,
                  color: config.textColor.withValues(alpha: 0.6),
                  size: 18,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  _ToastConfig _getToastConfig(ToastType type) {
    switch (type) {
      case ToastType.success:
        return _ToastConfig(
          icon: Icons.check_circle,
          iconColor: const Color(0xFF4CAF50),
          backgroundColor: const Color(0xFF1B5E20),
          textColor: Colors.white,
        );
      case ToastType.error:
        return _ToastConfig(
          icon: Icons.error,
          iconColor: const Color(0xFFEF5350),
          backgroundColor: const Color(0xFFB71C1C),
          textColor: Colors.white,
        );
      case ToastType.warning:
        return _ToastConfig(
          icon: Icons.warning,
          iconColor: const Color(0xFFFFA726),
          backgroundColor: const Color(0xFFE65100),
          textColor: Colors.white,
        );
      case ToastType.info:
        return _ToastConfig(
          icon: Icons.info,
          iconColor: const Color(0xFF42A5F5),
          backgroundColor: const Color(0xFF0D47A1),
          textColor: Colors.white,
        );
    }
  }
}

class _ToastConfig {
  const _ToastConfig({
    required this.icon,
    required this.iconColor,
    required this.backgroundColor,
    required this.textColor,
  });

  final IconData icon;
  final Color iconColor;
  final Color backgroundColor;
  final Color textColor;
}
