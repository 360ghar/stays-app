import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../theme/app_animations.dart';

// ===============================================
// ANIMATED FAVORITE HEART BUTTON
// ===============================================

/// A heart-shaped favorite button with premium animation.
/// Features: scale burst, particle explosion, color transition, and bounce.
class AnimatedFavoriteButton extends StatefulWidget {
  const AnimatedFavoriteButton({
    super.key,
    required this.isFavorite,
    required this.onToggle,
    this.size = 24,
    this.normalColor = Colors.white,
    this.favoriteColor = Colors.red,
    this.hasBackground = true,
  });

  final bool isFavorite;
  final ValueChanged<bool> onToggle;
  final double size;
  final Color normalColor;
  final Color favoriteColor;
  final bool hasBackground;

  @override
  State<AnimatedFavoriteButton> createState() => _AnimatedFavoriteButtonState();
}

class _AnimatedFavoriteButtonState extends State<AnimatedFavoriteButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _particleAnimation;
  late Animation<double> _rotationAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: AppAnimations.favoriteDuration,
      vsync: this,
    );

    // Scale animation with bounce effect
    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 0.3),
        weight: 20,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.3, end: 1.4),
        weight: 40,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.4, end: 1.0),
        weight: 40,
      ),
    ]).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));

    // Particle explosion animation
    _particleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.3, 1.0, curve: Curves.easeOut),
      ),
    );

    // Subtle rotation for added flair
    _rotationAnimation = Tween<double>(begin: 0.0, end: 0.15).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  void didUpdateWidget(AnimatedFavoriteButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isFavorite != widget.isFavorite) {
      if (widget.isFavorite) {
        _controller.forward(from: 0);
      } else {
        _controller.reverse(from: 1);
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTap() {
    widget.onToggle(!widget.isFavorite);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _handleTap,
      child: SizedBox(
        width: widget.size + 16,
        height: widget.size + 16,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Particle effects when favoriting
            if (widget.isFavorite)
              AnimatedBuilder(
                animation: _particleAnimation,
                builder: (context, child) {
                  return _ParticleExplosion(
                    progress: _particleAnimation.value,
                    color: widget.favoriteColor,
                    size: widget.size,
                  );
                },
              ),

            // Background circle
            if (widget.hasBackground)
              AnimatedBuilder(
                animation: _scaleAnimation,
                builder: (context, child) {
                  return Container(
                    width: widget.size + 12,
                    height: widget.size + 12,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.black.withValues(alpha: 0.3),
                    ),
                  );
                },
              ),

            // Heart icon
            AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return Transform.scale(
                  scale: _scaleAnimation.value,
                  child: Transform.rotate(
                    angle: _rotationAnimation.value *
                        (widget.isFavorite ? 1 : -1),
                    child: Icon(
                      widget.isFavorite ? Icons.favorite : Icons.favorite_border,
                      color: widget.isFavorite
                          ? widget.favoriteColor
                          : widget.normalColor,
                      size: widget.size,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

// ===============================================
// PARTICLE EXPLOSION WIDGET
// ===============================================

class _ParticleExplosion extends StatelessWidget {
  const _ParticleExplosion({
    required this.progress,
    required this.color,
    required this.size,
  });

  final double progress;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    if (progress <= 0) return const SizedBox.shrink();

    return SizedBox(
      width: size * 3,
      height: size * 3,
      child: Stack(
        children: List.generate(8, (index) {
          final angle = index * 45.0 * math.pi / 180;
          return _Particle(
            angle: angle,
            progress: progress,
            color: color,
            size: size / 4,
          );
        }),
      ),
    );
  }
}

class _Particle extends StatelessWidget {
  const _Particle({
    required this.angle,
    required this.progress,
    required this.color,
    required this.size,
  });

  final double angle;
  final double progress;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    final distance = 30.0 * progress;
    final opacity = (1 - progress).clamp(0.0, 1.0);
    final scale = (1 - progress * 0.5).clamp(0.5, 1.0);

    return Transform.translate(
      offset: Offset(
        distance * math.cos(angle),
        distance * math.sin(angle),
      ),
      child: Opacity(
        opacity: opacity,
        child: Transform.scale(
          scale: scale,
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color,
            ),
          ),
        ),
      ),
    );
  }
}
