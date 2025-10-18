import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../web/virtual_tour_embed.dart';

class InteractiveVirtualTour extends StatefulWidget {
  const InteractiveVirtualTour({
    super.key,
    required this.tourUrl,
    this.placeholderImageUrl,
    this.aspectRatio = 0.9,
    this.borderRadius = 16,
  });

  final String tourUrl;
  final String? placeholderImageUrl;
  final double aspectRatio;
  final double borderRadius;

  @override
  State<InteractiveVirtualTour> createState() => _InteractiveVirtualTourState();
}

class _InteractiveVirtualTourState extends State<InteractiveVirtualTour> {
  bool _isInteractive = false;
  ScrollHoldController? _scrollHoldController;

  void _holdParentScroll() {
    if (_scrollHoldController != null) return;
    final scrollable = Scrollable.of(context);
    if (scrollable == null) return;
    _scrollHoldController =
        scrollable.position.hold(_onParentScrollReleased);
  }

  void _onParentScrollReleased() {
    _scrollHoldController = null;
  }

  void _releaseParentScroll() {
    final controller = _scrollHoldController;
    if (controller == null) return;
    _scrollHoldController = null;
    controller.cancel();
  }

  void _activateTour() {
    if (_isInteractive) return;
    setState(() => _isInteractive = true);
  }

  void _handlePointerDown(PointerDownEvent event) {
    if (!_isInteractive) return;
    _holdParentScroll();
  }

  void _handlePointerUp(PointerEvent event) {
    if (!_isInteractive) return;
    _releaseParentScroll();
  }

  @override
  void dispose() {
    _releaseParentScroll();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tourContent = AspectRatio(
      aspectRatio: widget.aspectRatio,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(widget.borderRadius),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          child: _isInteractive
              ? RepaintBoundary(
                  key: const ValueKey('tour'),
                  child: VirtualTourEmbed(tourUrl: widget.tourUrl),
                )
              : _InteractivePlaceholder(
                  key: const ValueKey('placeholder'),
                  onTap: _activateTour,
                  imageUrl: widget.placeholderImageUrl,
                ),
        ),
      ),
    );

    return Listener(
      onPointerDown: _handlePointerDown,
      onPointerUp: _handlePointerUp,
      onPointerCancel: _handlePointerUp,
      behavior: HitTestBehavior.deferToChild,
      child: tourContent,
    );
  }
}

class _InteractivePlaceholder extends StatelessWidget {
  const _InteractivePlaceholder({
    super.key,
    required this.onTap,
    this.imageUrl,
  });

  final VoidCallback onTap;
  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    final hasImage = imageUrl != null && imageUrl!.isNotEmpty;
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (hasImage)
            CachedNetworkImage(
              imageUrl: imageUrl!,
              fit: BoxFit.cover,
              placeholder: (context, _) => Container(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
              ),
              errorWidget: (context, _, __) => _fallbackBackground(context),
            )
          else
            _fallbackBackground(context),
          Container(
            color: Colors.black.withValues(alpha: 0.35),
          ),
          Center(
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.55),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.35),
                  width: 1.2,
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(Icons.threesixty, color: Colors.white, size: 40),
                  SizedBox(height: 8),
                  Text(
                    'Tap to explore the tour',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _fallbackBackground(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      color: colors.surfaceContainerHighest,
      child: Icon(
        Icons.public,
        size: 48,
        color: colors.onSurface.withValues(alpha: 0.4),
      ),
    );
  }
}
