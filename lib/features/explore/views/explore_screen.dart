import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:stays_app/app/data/models/property_model.dart';
import 'package:stays_app/core/router/app_router.dart';
import 'package:stays_app/core/theme/tokens.dart';
import 'package:stays_app/core/ui/async_state.dart';
import 'package:stays_app/core/ui/stay_card.dart';
import 'package:stays_app/core/ui/tour_hero.dart';
import 'package:stays_app/features/explore/providers/explore_providers.dart';

/// V2 Explore. Same sliver structure as legacy, logic in [exploreProvider].
class ExploreScreen extends ConsumerWidget {
  const ExploreScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(exploreProvider);
    final notifier = ref.read(exploreProvider.notifier);
    return Scaffold(
      backgroundColor: StayTokens.paper,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: notifier.refresh,
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics(),
            ),
            slivers: [
              _SearchBar(
                onTap: () => context.push(AppPaths.search),
                onLocation: notifier.useMyLocation,
              ),
              if (state.isLoading && state.popular.isEmpty)
                const SliverFillRemaining(
                  child: AsyncState.loading(message: 'Finding stays…'),
                )
              else if (state.error.isNotEmpty && state.popular.isEmpty)
                SliverFillRemaining(
                  child: AsyncState.error(
                    state.error,
                    onRetry: notifier.refresh,
                  ),
                )
              else ...[
                _Greeting(locationName: state.locationName),
                if (state.showingCached)
                  const SliverToBoxAdapter(child: _CachedBanner()),
                if (state.featured != null)
                  _Featured(property: state.featured!),
                _StayRow(
                  title: state.city.isNotEmpty
                      ? 'Popular stays in ${state.city}'
                      : 'Popular stays',
                  stays: state.popularExcludingFeatured,
                ),
                _StayRow(
                  title: 'Nearby stays',
                  stays: state.nearbyExcludingFeatured,
                ),
                if (state.popular.isEmpty && state.nearby.isEmpty)
                  const SliverToBoxAdapter(
                    child: AsyncState.empty(
                      message: 'No stays found here yet.',
                    ),
                  ),
                const SliverToBoxAdapter(child: SizedBox(height: 56)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _SearchBar extends StatelessWidget {
  const _SearchBar({required this.onTap, required this.onLocation});
  final VoidCallback onTap;
  final VoidCallback onLocation;

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      floating: true,
      snap: true,
      backgroundColor: StayTokens.paper,
      elevation: 0,
      toolbarHeight: 64,
      titleSpacing: 16,
      title: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: onTap,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: StayTokens.s12,
                  vertical: StayTokens.s12,
                ),
                decoration: BoxDecoration(
                  color: StayTokens.paperWarm,
                  borderRadius: BorderRadius.circular(StayTokens.radiusPill),
                  border: Border.all(color: StayTokens.line),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.search, size: 20),
                    SizedBox(width: StayTokens.s8),
                    Text('Search stays', style: StayTokens.bodySecondary),
                  ],
                ),
              ),
            ),
          ),
          IconButton(
            tooltip: 'Use my location',
            onPressed: onLocation,
            icon: const Icon(Icons.my_location, color: StayTokens.accentDark),
          ),
        ],
      ),
    );
  }
}

class _Greeting extends StatelessWidget {
  const _Greeting({required this.locationName});
  final String locationName;

  @override
  Widget build(BuildContext context) {
    final greeting = greetingFor(DateTime.now());
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(greeting, style: StayTokens.titleLarge),
            if (locationName.isNotEmpty)
              Text('Stays near $locationName', style: StayTokens.bodySecondary),
          ],
        ),
      ),
    );
  }
}

class _CachedBanner extends StatelessWidget {
  const _CachedBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.all(StayTokens.s12),
      decoration: BoxDecoration(
        color: StayTokens.paperWarm,
        borderRadius: BorderRadius.circular(StayTokens.radiusCard),
        border: Border.all(color: StayTokens.line),
      ),
      child: const Text(
        'Offline — showing saved stays.',
        style: StayTokens.label,
      ),
    );
  }
}

class _Featured extends ConsumerWidget {
  const _Featured({required this.property});
  final Property property;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(exploreProvider.notifier);
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(StayTokens.radiusHero),
              child: TourHero(
                imageUrl: property.displayImage,
                hasTour: property.hasVirtualTour,
                onTourTap: () => context.push(
                  AppPaths.tour('${property.id}'),
                  extra: {
                    'url': property.virtualTourUrl,
                    'title': property.name,
                  },
                ),
                onGalleryTap: () => context.push(
                  AppPaths.listing('${property.id}'),
                  extra: property,
                ),
              ),
            ),
            const SizedBox(height: StayTokens.s8),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        property.name,
                        style: StayTokens.body.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        '${property.displayPrice} / night',
                        style: StayTokens.price,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(
                    notifier.isFavorite(property.id)
                        ? Icons.favorite
                        : Icons.favorite_border,
                    color: notifier.isFavorite(property.id)
                        ? StayTokens.heart
                        : StayTokens.ink,
                  ),
                  onPressed: () => notifier.toggleFavorite(property),
                ),
              ],
            ),
            const SizedBox(height: StayTokens.s16),
          ],
        ),
      ),
    );
  }
}

class _StayRow extends ConsumerWidget {
  const _StayRow({required this.title, required this.stays});
  final String title;
  final List<Property> stays;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (stays.isEmpty) return const SliverToBoxAdapter(child: SizedBox());
    final notifier = ref.read(exploreProvider.notifier);
    return SliverToBoxAdapter(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: Text(title, style: StayTokens.title),
          ),
          SizedBox(
            height: 292,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: stays.length,
              separatorBuilder: (_, _) => const SizedBox(width: StayTokens.s12),
              itemBuilder: (context, i) {
                final stay = stays[i];
                return StayCard(
                  property: stay,
                  isFavorite: notifier.isFavorite(stay.id),
                  onFavoriteToggle: () => notifier.toggleFavorite(stay),
                  onTap: () =>
                      context.push(AppPaths.listing('${stay.id}'), extra: stay),
                );
              },
            ),
          ),
          const SizedBox(height: StayTokens.s16),
        ],
      ),
    );
  }
}
