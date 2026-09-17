import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:stays_app/core/router/app_router.dart';
import 'package:stays_app/core/theme/tokens.dart';
import 'package:stays_app/core/ui/async_state.dart';
import 'package:stays_app/core/ui/stay_card.dart';
import 'package:stays_app/features/wishlist/providers/wishlist_providers.dart';

/// V2 wishlist. One [StayCard] per row, cursor paging, confirm on clear-all.
class WishlistScreen extends ConsumerWidget {
  const WishlistScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(wishlistProvider);
    final notifier = ref.read(wishlistProvider.notifier);
    return Scaffold(
      backgroundColor: StayTokens.paper,
      appBar: AppBar(
        title: const Text('Wishlist'),
        actions: [
          if (state.items.isNotEmpty)
            TextButton(
              onPressed: () => _confirmClear(context, notifier.clearAll),
              child: const Text('Clear all'),
            ),
        ],
      ),
      body: Builder(
        builder: (context) {
          if (state.isLoading && state.items.isEmpty) {
            return const AsyncState.loading(message: 'Loading wishlist…');
          }
          if (state.error.isNotEmpty && state.items.isEmpty) {
            return AsyncState.error(state.error, onRetry: notifier.load);
          }
          if (state.items.isEmpty) {
            return const AsyncState.empty(
              message: 'No saved stays yet. Tap a heart to save one.',
            );
          }
          return RefreshIndicator(
            onRefresh: notifier.refresh,
            child: NotificationListener<ScrollNotification>(
              onNotification: (info) {
                if (info.metrics.pixels >= info.metrics.maxScrollExtent - 400) {
                  notifier.loadMore().ignore();
                }
                return false;
              },
              child: ListView.separated(
                padding: const EdgeInsets.all(StayTokens.s16),
                itemCount: state.items.length,
                separatorBuilder: (_, _) =>
                    const SizedBox(height: StayTokens.s12),
                itemBuilder: (context, i) {
                  final stay = state.items[i];
                  return StayCard(
                    property: stay,
                    width: double.infinity,
                    isFavorite: true,
                    onFavoriteToggle: () => notifier.remove(stay.id),
                    onTap: () => context.push(
                      AppPaths.listing('${stay.id}'),
                      extra: stay,
                    ),
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _confirmClear(
    BuildContext context,
    Future<void> Function() onConfirm,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear wishlist?'),
        content: const Text(
          'All saved stays will be removed. This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Clear all'),
          ),
        ],
      ),
    );
    if (confirmed == true) await onConfirm();
  }
}
