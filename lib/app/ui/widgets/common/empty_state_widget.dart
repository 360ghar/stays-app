import 'package:flutter/material.dart';

enum EmptyStateType {
  general,
  wishlist,
  bookings,
  search,
  messages,
  notifications,
}

class EmptyStateWidget extends StatelessWidget {
  final String title;
  final String? message;
  final Widget? icon;
  final VoidCallback? action;
  final String? actionText;
  final EmptyStateType type;

  const EmptyStateWidget({
    super.key,
    required this.title,
    this.message,
    this.icon,
    this.action,
    this.actionText,
    this.type = EmptyStateType.general,
  });

  Widget _defaultIcon(ColorScheme colors) {
    switch (type) {
      case EmptyStateType.wishlist:
        return Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: colors.surfaceContainerHighest,
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.favorite_border, size: 40, color: colors.outline),
        );
      case EmptyStateType.bookings:
        return Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: colors.surfaceContainerHighest,
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.calendar_today_outlined,
            size: 40,
            color: colors.outline,
          ),
        );
      case EmptyStateType.search:
        return Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: colors.surfaceContainerHighest,
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.search_off, size: 40, color: colors.outline),
        );
      case EmptyStateType.messages:
        return Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: colors.surfaceContainerHighest,
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.chat_bubble_outline,
            size: 40,
            color: colors.outline,
          ),
        );
      case EmptyStateType.notifications:
        return Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: colors.surfaceContainerHighest,
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.notifications_none,
            size: 40,
            color: colors.outline,
          ),
        );
      case EmptyStateType.general:
        return Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: colors.surfaceContainerHighest,
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.inbox_outlined, size: 40, color: colors.outline),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final textStyles = theme.textTheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            icon ?? _defaultIcon(colors),
            const SizedBox(height: 24),
            Text(
              title,
              style: textStyles.titleLarge?.copyWith(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: colors.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
            if (message != null) ...[
              const SizedBox(height: 8),
              Text(
                message!,
                style: textStyles.bodyMedium?.copyWith(
                  fontSize: 14,
                  color: colors.onSurface.withValues(alpha: 0.6),
                ),
                textAlign: TextAlign.center,
              ),
            ],
            if (action != null && actionText != null) ...[
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: action,
                style: ElevatedButton.styleFrom(
                  backgroundColor: colors.primary,
                  foregroundColor: colors.onPrimary,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
                child: Text(
                  actionText!,
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

class EmptyWishlistWidget extends StatelessWidget {
  final VoidCallback? onExplore;

  const EmptyWishlistWidget({super.key, this.onExplore});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return EmptyStateWidget(
      title: 'Your wishlist is empty',
      message: 'Save your favorite properties to see them here',
      type: EmptyStateType.wishlist,
      action: onExplore,
      actionText: 'Explore Properties',
      icon: Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          color: colors.primaryContainer,
          shape: BoxShape.circle,
        ),
        child: Icon(Icons.favorite_border, size: 40, color: colors.primary),
      ),
    );
  }
}

class EmptyBookingsWidget extends StatelessWidget {
  final VoidCallback? onBrowse;

  const EmptyBookingsWidget({super.key, this.onBrowse});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return EmptyStateWidget(
      title: 'No bookings yet',
      message: 'Start planning your next trip',
      type: EmptyStateType.bookings,
      action: onBrowse,
      actionText: 'Browse Properties',
      icon: Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          color: colors.secondaryContainer,
          shape: BoxShape.circle,
        ),
        child: Icon(
          Icons.calendar_today_outlined,
          size: 40,
          color: colors.secondary,
        ),
      ),
    );
  }
}

class EmptySearchResultsWidget extends StatelessWidget {
  final VoidCallback? onClearFilters;

  const EmptySearchResultsWidget({super.key, this.onClearFilters});

  @override
  Widget build(BuildContext context) {
    return EmptyStateWidget(
      title: 'No properties found',
      message: 'Try adjusting your filters or search in a different area',
      type: EmptyStateType.search,
      action: onClearFilters,
      actionText: 'Clear Filters',
    );
  }
}
