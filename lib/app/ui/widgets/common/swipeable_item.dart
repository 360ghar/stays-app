import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../theme/app_animations.dart';

// ===============================================
// ANIMATED SWIPE TO DISMISS
// ===============================================

/// A swipeable list item with smooth animations.
/// Features swipe-to-delete with confirmation, custom actions, and haptic feedback.
class SwipeableItem extends StatefulWidget {
  const SwipeableItem({
    super.key,
    required this.child,
    this.onDelete,
    this.onEdit,
    this.onArchive,
    this.confirmBeforeDelete = true,
    this.deleteConfirmDuration = const Duration(seconds: 3),
    this.backgroundColor,
  });

  final Widget child;
  final VoidCallback? onDelete;
  final VoidCallback? onEdit;
  final VoidCallback? onArchive;
  final bool confirmBeforeDelete;
  final Duration deleteConfirmDuration;
  final Color? backgroundColor;

  @override
  State<SwipeableItem> createState() => _SwipeableItemState();
}

class _SwipeableItemState extends State<SwipeableItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  bool _isDeleting = false;
  bool _isConfirmingDelete = false;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: AppAnimations.medium,
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: AppAnimations.easeOutCubic,
      ),
    );

    _fadeAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: AppAnimations.easeOut,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _handleDelete() async {
    if (widget.confirmBeforeDelete && !_isConfirmingDelete) {
      setState(() => _isConfirmingDelete = true);

      // Auto-cancel after duration
      Future.delayed(widget.deleteConfirmDuration, () {
        if (mounted && _isConfirmingDelete) {
          setState(() => _isConfirmingDelete = false);
        }
      });

      // Haptic feedback
      HapticFeedback.mediumImpact();
      return;
    }

    if (_isDeleting) return;
    _isDeleting = true;

    // Haptic feedback
    HapticFeedback.heavyImpact();

    await _controller.forward();

    widget.onDelete?.call();

    if (mounted) {
      setState(() => _isDeleting = false);
      _controller.reset();
    }
  }

  void _cancelDelete() {
    if (_isConfirmingDelete) {
      setState(() => _isConfirmingDelete = false);
      HapticFeedback.lightImpact();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isDeleting) {
      return SizeTransition(
        axis: Axis.vertical,
        sizeFactor: _scaleAnimation,
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: widget.child,
        ),
      );
    }

    return ClipRect(
      child: Dismissible(
        key: widget.key ?? UniqueKey(),
        direction: DismissDirection.endToStart,
        dismissThresholds: const {
          DismissDirection.endToStart: 0.7,
        },
        onDismissed: (_) {
          widget.onDelete?.call();
        },
        confirmDismiss: (direction) async {
          if (widget.confirmBeforeDelete && !_isConfirmingDelete) {
            setState(() => _isConfirmingDelete = true);

            HapticFeedback.mediumImpact();

            // Wait for confirmation
            await Future.delayed(widget.deleteConfirmDuration);

            if (mounted && _isConfirmingDelete) {
              setState(() => _isConfirmingDelete = false);
            }

            return false;
          }

          HapticFeedback.heavyImpact();
          return true;
        },
        background: _buildBackground(context),
        child: GestureDetector(
          onTap: _isConfirmingDelete ? _cancelDelete : null,
          child: Stack(
            children: [
              widget.child,
              if (_isConfirmingDelete)
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: _DeleteConfirmation(
                        onCancel: _cancelDelete,
                        onConfirm: () {
                          _controller.forward().then((_) {
                            widget.onDelete?.call();
                          });
                        },
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBackground(BuildContext context) {
    return Container(
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: _isConfirmingDelete ? Colors.red : Colors.red.shade400,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(
        _isConfirmingDelete ? Icons.warning : Icons.delete_rounded,
        color: Colors.white,
        size: 28,
      ),
    );
  }
}

/// Delete confirmation button group
class _DeleteConfirmation extends StatelessWidget {
  const _DeleteConfirmation({
    required this.onCancel,
    required this.onConfirm,
  });

  final VoidCallback onCancel;
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.delete_rounded,
          color: Colors.white,
          size: 24,
        ),
        const SizedBox(width: 8),
        const Text(
          'Delete?',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(width: 16),
        // Cancel button
        GestureDetector(
          onTap: onCancel,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text(
              'No',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        // Confirm button
        GestureDetector(
          onTap: onConfirm,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text(
              'Yes',
              style: TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ===============================================
// SIMPLE SWIPE TO DISMISS
// ===============================================

/// A simpler swipe-to-dismiss without confirmation.
class SimpleSwipeable extends StatelessWidget {
  const SimpleSwipeable({
    super.key,
    required this.child,
    required this.onDismissed,
    this.direction = DismissDirection.endToStart,
    this.backgroundIcon = Icons.delete_rounded,
    this.backgroundColor,
  });

  final Widget child;
  final DismissDirectionCallback onDismissed;
  final DismissDirection direction;
  final IconData backgroundIcon;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ClipRect(
      child: Dismissible(
        key: key ?? UniqueKey(),
        direction: direction,
        onDismissed: onDismissed,
        background: Container(
          alignment: direction == DismissDirection.endToStart
              ? Alignment.centerRight
              : Alignment.centerLeft,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          decoration: BoxDecoration(
            color: backgroundColor ?? theme.colorScheme.error,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            backgroundIcon,
            color: Colors.white,
            size: 28,
          ),
        ),
        child: child,
      ),
    );
  }
}
