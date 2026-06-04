import 'package:flutter/material.dart';
import '../../theme/app_animations.dart';

// ===============================================
// ANIMATED SEARCH BAR
// ===============================================

/// A premium animated search bar that expands/collapses smoothly.
/// Features focus animation, clear button, and search suggestions.
class AnimatedSearchBar extends StatefulWidget {
  const AnimatedSearchBar({
    super.key,
    required this.onChanged,
    required this.onSubmitted,
    this.hintText = 'Search...',
    this.leadingIcon,
    this.trailingIcon,
    this.onTrailingPressed,
    this.isExpanded = false,
    this.expandedWidth,
    this.collapsedWidth = 56.0,
    this.duration = AppAnimations.medium,
    this.curve = AppAnimations.easeOutCubic,
    this.backgroundColor,
    this.textColor,
  });

  final ValueChanged<String> onChanged;
  final ValueChanged<String> onSubmitted;
  final String hintText;
  final IconData? leadingIcon;
  final IconData? trailingIcon;
  final VoidCallback? onTrailingPressed;
  final bool isExpanded;
  final double? expandedWidth;
  final double collapsedWidth;
  final Duration duration;
  final Curve curve;
  final Color? backgroundColor;
  final Color? textColor;

  @override
  State<AnimatedSearchBar> createState() => _AnimatedSearchBarState();
}

class _AnimatedSearchBarState extends State<AnimatedSearchBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _widthAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _iconSlideAnimation;

  final TextEditingController _textController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _isFocused = false;
  bool _hasText = false;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );

    _focusNode.addListener(() {
      setState(() {
        _isFocused = _focusNode.hasFocus;
      });
    });

    _textController.addListener(() {
      setState(() {
        _hasText = _textController.text.isNotEmpty;
      });
    });

    if (widget.isExpanded) {
      _controller.value = 1.0;
    }
  }

  @override
  void didUpdateWidget(AnimatedSearchBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isExpanded != oldWidget.isExpanded) {
      if (widget.isExpanded) {
        _controller.forward();
        // Auto-focus when expanded
        Future.delayed(const Duration(milliseconds: 100), () {
          _focusNode.requestFocus();
        });
      } else {
        _controller.reverse();
        _focusNode.unfocus();
        _textController.clear();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _textController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _handleClear() {
    _textController.clear();
    widget.onChanged('');
    _focusNode.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final backgroundColor = widget.backgroundColor ??
        (isDark
            ? colorScheme.surfaceContainerHigh
            : colorScheme.surfaceContainerHighest);

    final expandedWidth = widget.expandedWidth ??
        (MediaQuery.of(context).size.width - 32);

    _widthAnimation = Tween<double>(
      begin: widget.collapsedWidth,
      end: expandedWidth,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: widget.curve,
    ));

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.3, 1.0, curve: Curves.easeOut),
      ),
    );

    _iconSlideAnimation = Tween<double>(begin: 0.0, end: -8.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: widget.curve,
      ),
    );

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final currentWidth = _widthAnimation.value;
        final isFullyExpanded = _controller.value > 0.8;

        return Container(
          width: currentWidth,
          height: 56,
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(28),
            boxShadow: _isFocused
                ? [
                    BoxShadow(
                      color: colorScheme.primary.withValues(alpha: 0.2),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Row(
            children: [
              // Leading icon / Search icon
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Transform.translate(
                  offset: Offset(_iconSlideAnimation.value, 0),
                  child: Icon(
                    widget.leadingIcon ?? Icons.search_rounded,
                    color: _isFocused
                        ? colorScheme.primary
                        : colorScheme.onSurfaceVariant,
                    size: 24,
                  ),
                ),
              ),

              // Text field
              Expanded(
                child: Opacity(
                  opacity: _fadeAnimation.value,
                  child: TextField(
                    controller: _textController,
                    focusNode: _focusNode,
                    onChanged: widget.onChanged,
                    onSubmitted: widget.onSubmitted,
                    style: TextStyle(
                      color: widget.textColor ?? colorScheme.onSurface,
                      fontSize: 16,
                    ),
                    decoration: InputDecoration(
                      hintText: widget.hintText,
                      hintStyle: TextStyle(
                        color: colorScheme.onSurfaceVariant,
                        fontSize: 16,
                      ),
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 12,
                      ),
                      suffixIcon: _hasText && isFullyExpanded
                          ? _AnimatedClearButton(
                              onPressed: _handleClear,
                            )
                          : null,
                    ),
                  ),
                ),
              ),

              // Trailing icon
              if (widget.trailingIcon != null)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: IconButton(
                    icon: Icon(widget.trailingIcon),
                    onPressed: widget.onTrailingPressed,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

/// Animated clear button for search bar
class _AnimatedClearButton extends StatefulWidget {
  const _AnimatedClearButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  State<_AnimatedClearButton> createState() => _AnimatedClearButtonState();
}

class _AnimatedClearButtonState extends State<_AnimatedClearButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: AppAnimations.fast,
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: AppAnimations.easeOutBack,
      ),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: AppAnimations.easeOut,
      ),
    );

    _controller.forward();
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
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () {
            _controller.reverse().then((_) {
              widget.onPressed();
              _controller.forward();
            });
          },
          iconSize: 20,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(
            minWidth: 32,
            minHeight: 32,
          ),
        ),
      ),
    );
  }
}

// ===============================================
// EXPANDING SEARCH FIELD
// ===============================================

/// A search field that expands from a collapsed icon to a full search bar.
/// Use this in app bars or toolbars where space is limited.
class ExpandingSearchField extends StatefulWidget {
  const ExpandingSearchField({
    super.key,
    required this.onChanged,
    required this.onSubmitted,
    this.hintText = 'Search...',
    this.onTap,
    this.onClose,
  });

  final ValueChanged<String> onChanged;
  final ValueChanged<String> onSubmitted;
  final String hintText;
  final VoidCallback? onTap;
  final VoidCallback? onClose;

  @override
  State<ExpandingSearchField> createState() => _ExpandingSearchFieldState();
}

class _ExpandingSearchFieldState extends State<ExpandingSearchField>
    with SingleTickerProviderStateMixin {
  bool _isExpanded = false;
  late AnimationController _controller;
  late Animation<double> _expandAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: AppAnimations.medium,
      vsync: this,
    );

    _expandAnimation = CurvedAnimation(
      parent: _controller,
      curve: AppAnimations.easeOutCubic,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggleExpand() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _controller.forward();
      } else {
        _controller.reverse();
        widget.onClose?.call();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return AnimatedBuilder(
      animation: _expandAnimation,
      builder: (context, child) {
        return Container(
          width: _isExpanded
              ? MediaQuery.of(context).size.width - 32
              : 56 * _expandAnimation.value + 56 * (1 - _expandAnimation.value),
          height: 56,
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(28),
          ),
          child: _isExpanded
              ? Row(
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(left: 16),
                      child: Icon(Icons.search_rounded, size: 24),
                    ),
                    Expanded(
                      child: TextField(
                        autofocus: true,
                        onChanged: widget.onChanged,
                        onSubmitted: (value) {
                          widget.onSubmitted(value);
                          _toggleExpand();
                        },
                        decoration: InputDecoration(
                          hintText: widget.hintText,
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 12,
                          ),
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: _toggleExpand,
                    ),
                  ],
                )
              : IconButton(
                  icon: const Icon(Icons.search_rounded),
                  onPressed: _toggleExpand,
                ),
        );
      },
    );
  }
}
