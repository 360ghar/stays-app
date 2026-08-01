import 'package:flutter/material.dart';

class LoadingWidget extends StatelessWidget {
  const LoadingWidget({super.key, this.message, this.size, this.color});
  final String? message;
  final double? size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final loadingColor = color ?? theme.colorScheme.primary;
    final loadingSize = size ?? 48.0;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: loadingSize,
            height: loadingSize,
            child: CircularProgressIndicator(
              color: loadingColor,
              strokeWidth: loadingSize > 40 ? 3 : 2,
            ),
          ),
          if (message != null) ...[
            const SizedBox(height: 16),
            Text(
              message!,
              style: TextStyle(
                fontSize: 14,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class SmallLoadingWidget extends StatelessWidget {
  const SmallLoadingWidget({super.key, this.color, this.size = 20});
  final Color? color;
  final double size;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      width: size,
      height: size,
      child: CircularProgressIndicator(
        strokeWidth: 2,
        color: color ?? theme.colorScheme.primary,
      ),
    );
  }
}

class LinearLoadingIndicator extends StatelessWidget {
  const LinearLoadingIndicator({super.key, this.height = 4, this.color});
  final double height;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      height: height,
      child: LinearProgressIndicator(
        minHeight: height,
        color: color ?? theme.colorScheme.primary,
        backgroundColor: theme.colorScheme.surfaceContainerHighest,
      ),
    );
  }
}
