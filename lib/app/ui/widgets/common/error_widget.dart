import 'package:flutter/material.dart';

class ErrorDisplay extends StatelessWidget {
  final String message;
  final String? title;
  final VoidCallback? onRetry;
  final String? retryText;
  final Widget? icon;
  final bool showRetry;

  const ErrorDisplay({
    super.key,
    required this.message,
    this.title,
    this.onRetry,
    this.retryText,
    this.icon,
    this.showRetry = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final textStyles = theme.textTheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            icon ??
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: colors.errorContainer,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.error_outline,
                    size: 32,
                    color: colors.error,
                  ),
                ),
            const SizedBox(height: 24),
            Text(
              title ?? 'Something went wrong',
              style: textStyles.titleMedium?.copyWith(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: colors.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: textStyles.bodyMedium?.copyWith(
                fontSize: 14,
                color: colors.onSurface.withValues(alpha: 0.6),
              ),
              textAlign: TextAlign.center,
            ),
            if (showRetry && onRetry != null) ...[
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: onRetry,
                style: ElevatedButton.styleFrom(
                  backgroundColor: colors.primary,
                  foregroundColor: colors.onPrimary,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
                child: Text(
                  retryText ?? 'Try Again',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class NetworkErrorDisplay extends StatelessWidget {
  final VoidCallback? onRetry;

  const NetworkErrorDisplay({super.key, this.onRetry});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return ErrorDisplay(
      title: 'No Internet Connection',
      message: 'Please check your internet connection and try again.',
      icon: Container(
        width: 64,
        height: 64,
        decoration: BoxDecoration(
          color: colors.tertiaryContainer,
          shape: BoxShape.circle,
        ),
        child: Icon(Icons.wifi_off, size: 32, color: colors.tertiary),
      ),
      onRetry: onRetry,
    );
  }
}

class ServerErrorDisplay extends StatelessWidget {
  final String? errorCode;
  final VoidCallback? onRetry;

  const ServerErrorDisplay({super.key, this.errorCode, this.onRetry});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return ErrorDisplay(
      title: 'Server Error',
      message: errorCode != null
          ? 'We\'re having some trouble. Error code: $errorCode'
          : 'We\'re having some trouble. Please try again later.',
      icon: Container(
        width: 64,
        height: 64,
        decoration: BoxDecoration(
          color: colors.errorContainer,
          shape: BoxShape.circle,
        ),
        child: Icon(Icons.cloud_off, size: 32, color: colors.error),
      ),
      onRetry: onRetry,
    );
  }
}
