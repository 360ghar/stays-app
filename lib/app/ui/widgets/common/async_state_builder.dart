import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// A reusable widget for handling async loading/error/data states.
///
/// This widget provides a consistent pattern for displaying loading indicators,
/// error states with retry functionality, and data content throughout the app.
///
/// Example usage:
/// ```dart
/// AsyncStateBuilder<List<Property>>(
///   isLoading: controller.isLoading,
///   error: controller.errorMessage,
///   data: controller.properties,
///   onRetry: controller.refresh,
///   builder: (context, properties) => PropertyList(properties: properties),
/// )
/// ```
class AsyncStateBuilder<T> extends StatelessWidget {
  const AsyncStateBuilder({
    super.key,
    required this.isLoading,
    required this.error,
    required this.data,
    required this.builder,
    this.onRetry,
    this.loadingWidget,
    this.errorBuilder,
    this.emptyWidget,
    this.isEmpty,
  });

  /// Observable boolean indicating loading state
  final Rx<bool> isLoading;

  /// Observable string for error message (empty string = no error)
  final Rx<String> error;

  /// Observable data value
  final Rx<T?> data;

  /// Builder function called when data is available
  final Widget Function(BuildContext context, T data) builder;

  /// Optional retry callback for error state
  final VoidCallback? onRetry;

  /// Optional custom loading widget
  final Widget? loadingWidget;

  /// Optional custom error widget builder
  final Widget Function(BuildContext context, String error)? errorBuilder;

  /// Optional widget to show when data is empty
  final Widget? emptyWidget;

  /// Optional function to determine if data is empty
  final bool Function(T data)? isEmpty;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      // Show loading state
      if (isLoading.value && data.value == null) {
        return loadingWidget ?? const _DefaultLoadingWidget();
      }

      // Show error state
      if (error.value.isNotEmpty && data.value == null) {
        if (errorBuilder != null) {
          return errorBuilder!(context, error.value);
        }
        return _DefaultErrorWidget(
          error: error.value,
          onRetry: onRetry,
        );
      }

      // No data available
      final currentData = data.value;
      if (currentData == null) {
        return emptyWidget ?? const _DefaultEmptyWidget();
      }

      // Check if data is empty
      if (isEmpty != null && isEmpty!(currentData)) {
        return emptyWidget ?? const _DefaultEmptyWidget();
      }

      // Build content with data
      return builder(context, currentData);
    });
  }
}

/// Variant for list data with built-in empty checking
class AsyncListBuilder<T> extends StatelessWidget {
  const AsyncListBuilder({
    super.key,
    required this.isLoading,
    required this.error,
    required this.items,
    required this.builder,
    this.onRetry,
    this.loadingWidget,
    this.errorBuilder,
    this.emptyWidget,
    this.emptyTitle,
    this.emptySubtitle,
    this.emptyIcon,
  });

  /// Observable boolean indicating loading state
  final Rx<bool> isLoading;

  /// Observable string for error message
  final Rx<String> error;

  /// Observable list of items
  final RxList<T> items;

  /// Builder function called when items are available
  final Widget Function(BuildContext context, List<T> items) builder;

  /// Optional retry callback for error state
  final VoidCallback? onRetry;

  /// Optional custom loading widget
  final Widget? loadingWidget;

  /// Optional custom error widget builder
  final Widget Function(BuildContext context, String error)? errorBuilder;

  /// Optional widget to show when list is empty
  final Widget? emptyWidget;

  /// Optional title for default empty state
  final String? emptyTitle;

  /// Optional subtitle for default empty state
  final String? emptySubtitle;

  /// Optional icon for default empty state
  final IconData? emptyIcon;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      // Show loading state
      if (isLoading.value && items.isEmpty) {
        return loadingWidget ?? const _DefaultLoadingWidget();
      }

      // Show error state
      if (error.value.isNotEmpty && items.isEmpty) {
        if (errorBuilder != null) {
          return errorBuilder!(context, error.value);
        }
        return _DefaultErrorWidget(
          error: error.value,
          onRetry: onRetry,
        );
      }

      // Show empty state
      if (items.isEmpty) {
        return emptyWidget ??
            _DefaultEmptyWidget(
              title: emptyTitle,
              subtitle: emptySubtitle,
              icon: emptyIcon,
            );
      }

      // Build content with items
      return builder(context, items.toList());
    });
  }
}

class _DefaultLoadingWidget extends StatelessWidget {
  const _DefaultLoadingWidget();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: CircularProgressIndicator(),
    );
  }
}

class _DefaultErrorWidget extends StatelessWidget {
  const _DefaultErrorWidget({
    required this.error,
    this.onRetry,
  });

  final String error;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 48,
              color: colors.error,
            ),
            const SizedBox(height: 16),
            Text(
              'Something went wrong',
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              error,
              style: textTheme.bodyMedium?.copyWith(
                color: colors.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('Try again'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _DefaultEmptyWidget extends StatelessWidget {
  const _DefaultEmptyWidget({
    this.title,
    this.subtitle,
    this.icon,
  });

  final String? title;
  final String? subtitle;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon ?? Icons.inbox_outlined,
              size: 48,
              color: colors.onSurfaceVariant.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              title ?? 'No data available',
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 8),
              Text(
                subtitle!,
                style: textTheme.bodyMedium?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
