import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:stays_app/core/router/app_router.dart';
import 'package:stays_app/core/theme/tokens.dart';
import 'package:stays_app/core/ui/async_state.dart';
import 'package:stays_app/core/ui/stay_card.dart';
import 'package:stays_app/features/explore/providers/explore_providers.dart';
import 'package:stays_app/features/listing/providers/search_providers.dart';

/// V2 search results. StayCards for stays near the chosen coordinates.
class SearchResultsScreen extends ConsumerWidget {
  const SearchResultsScreen({required this.lat, required this.lng, super.key});
  final double lat;
  final double lng;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(searchResultsProvider((lat: lat, lng: lng)));
    final exploreNotifier = ref.read(exploreProvider.notifier);
    return Scaffold(
      backgroundColor: StayTokens.paper,
      appBar: AppBar(title: const Text('Stays')),
      body: async.when(
        loading: () => const AsyncState.loading(message: 'Searching stays…'),
        error: (_, _) => AsyncState.error(
          'Search failed. Please try again.',
          onRetry: () =>
              ref.invalidate(searchResultsProvider((lat: lat, lng: lng))),
        ),
        data: (stays) {
          if (stays.isEmpty) {
            return const AsyncState.empty(
              message: 'No stays found here. Try a nearby area.',
            );
          }
          return RefreshIndicator(
            onRefresh: () async =>
                ref.invalidate(searchResultsProvider((lat: lat, lng: lng))),
            child: ListView.separated(
              padding: const EdgeInsets.all(StayTokens.s16),
              itemCount: stays.length,
              separatorBuilder: (_, _) =>
                  const SizedBox(height: StayTokens.s12),
              itemBuilder: (context, i) {
                final stay = stays[i];
                return StayCard(
                  property: stay,
                  width: double.infinity,
                  isFavorite: exploreNotifier.isFavorite(stay.id),
                  onFavoriteToggle: () => exploreNotifier.toggleFavorite(stay),
                  onTap: () =>
                      context.push(AppPaths.listing('${stay.id}'), extra: stay),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
