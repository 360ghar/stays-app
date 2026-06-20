import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:stays_app/app/controllers/filter_controller.dart';
import 'package:stays_app/app/data/models/unified_filter_model.dart';
import 'package:stays_app/app/routes/app_routes.dart';
import 'package:stays_app/features/listing/controllers/listing_controller.dart';
import 'package:stays_app/app/ui/widgets/cards/property_grid_card.dart';
import 'package:stays_app/app/ui/widgets/common/location_filter_app_bar.dart';
import 'package:stays_app/app/utils/helpers/responsive_helper.dart';
// import removed: unused theme extension import

class SearchResultsView extends GetView<ListingController> {
  const SearchResultsView({super.key});

  @override
  Widget build(BuildContext context) {
    final filterController = Get.find<FilterController>();
    final filtersRx = filterController.rxFor(FilterScope.locate);
    final colors = Theme.of(context).colorScheme;
    final textStyles = Theme.of(context).textTheme;
    return Scaffold(
      backgroundColor: colors.surface,
      appBar: LocationFilterAppBar(
        scope: FilterScope.locate,
        showBackButton: true,
        trailingActions: [
          IconButton(
            tooltip: 'Sort',
            icon: Icon(Icons.sort_rounded, color: colors.onSurface),
            onPressed: () => _showSortSheet(context, filterController),
          ),
          IconButton(
            tooltip: 'Map',
            icon: Icon(Icons.map_outlined, color: colors.onSurface),
            onPressed: () => Get.toNamed(Routes.inbox),
          ),
        ],
      ),
      body: Obx(() {
        final filters = filtersRx.value;
        final isInitialLoading =
            controller.isLoading.value && controller.listings.isEmpty;
        return RefreshIndicator(
          onRefresh: () => controller.refresh(),
          child: CustomScrollView(
            controller: controller.scrollController,
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            slivers: _buildSlivers(
              context,
              controller,
              filterController,
              filters,
              isInitialLoading,
            ),
          ),
        );
      }),
    );
  }

  void _showSortSheet(BuildContext context, FilterController filterController) {
    const options = <(String, String)>[
      ('distance', 'Distance: nearest first'),
      ('price_low', 'Price: low to high'),
      ('price_high', 'Price: high to low'),
      ('newest', 'Newest'),
      ('popular', 'Most popular'),
      ('relevance', 'Relevance'),
    ];
    final current = filterController.filterFor(FilterScope.locate).sortBy;
    Get.bottomSheet(
      SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Sort by',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            ...options.map((opt) {
              final (value, label) = opt;
              return RadioListTile<String>(
                value: value,
                groupValue: current,
                title: Text(label),
                onChanged: (selected) {
                  if (selected == null) return;
                  final base = filterController.filterFor(FilterScope.locate);
                  filterController.setFilters(
                    FilterScope.locate,
                    base.copyWith(sortBy: selected),
                  );
                  Get.back();
                },
              );
            }),
            ListTile(
              leading: const Icon(Icons.clear),
              title: const Text('Clear sort'),
              onTap: () {
                final base = filterController.filterFor(FilterScope.locate);
                filterController.setFilters(
                  FilterScope.locate,
                  base.copyWith(sortBy: null),
                );
                Get.back();
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
    );
  }

  List<Widget> _buildSlivers(
    BuildContext context,
    ListingController controller,
    FilterController filterController,
    UnifiedFilterModel filters,
    bool isInitialLoading,
  ) {
    final colors = Theme.of(context).colorScheme;
    final textStyles = Theme.of(context).textTheme;
    if (isInitialLoading) {
      return [
        SliverFillRemaining(
          hasScrollBody: true,
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: const [
                CircularProgressIndicator(),
                SizedBox(height: 12),
                Text('Loading properties...'),
              ],
            ),
          ),
        ),
      ];
    }

    final slivers = <Widget>[];
    final items = controller.listings;
    final loadedCount = items.length;
    final tags = filters.activeTags();

    slivers.add(
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                loadedCount > 0
                    ? 'Showing $loadedCount ${loadedCount == 1 ? 'stay' : 'stays'}'
                    : 'No stays found',
                style: textStyles.bodyMedium?.copyWith(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (controller.errorMessage.value.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    controller.errorMessage.value,
                    style: TextStyle(color: colors.error),
                  ),
                ),
            ],
          ),
        ),
      ),
    );

    if (tags.isNotEmpty) {
      slivers.add(
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: tags
                        .map(
                          (tag) => Chip(
                            label: Text(
                              tag,
                              style: textStyles.labelMedium?.copyWith(
                                color: colors.onPrimaryContainer,
                              ),
                            ),
                            backgroundColor: colors.primaryContainer,
                          ),
                        )
                        .toList(),
                  ),
                ),
                TextButton(
                  onPressed: () => filterController.clear(FilterScope.locate),
                  style: TextButton.styleFrom(foregroundColor: colors.primary),
                  child: const Text('Clear'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (items.isEmpty) {
      slivers.add(
        SliverFillRemaining(
          hasScrollBody: false,
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.home_outlined,
                  size: 56,
                  color: colors.onSurface.withValues(alpha: 0.6),
                ),
                const SizedBox(height: 12),
                Text(
                  'No matching properties',
                  style: textStyles.bodyMedium?.copyWith(
                    color: colors.onSurface,
                  ),
                ),
                if (tags.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      'Try removing some filters and search again.',
                      style: textStyles.bodySmall?.copyWith(
                        color: colors.onSurface.withValues(alpha: 0.7),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      );
      return slivers;
    }

    final crossAxisCount = ResponsiveHelper.value<int>(
      context: context,
      mobile: 1,
      tablet: 2,
      desktop: 3,
    );

    if (controller.isLoading.value) {
      slivers.add(
        const SliverToBoxAdapter(child: LinearProgressIndicator(minHeight: 2)),
      );
    }

    slivers.add(
      SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        sliver: crossAxisCount == 1
            ? _buildListSliver(controller)
            : _buildGridSliver(controller, crossAxisCount),
      ),
    );

    slivers.add(
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          child: _LoadMoreBar(controller: controller),
        ),
      ),
    );

    return slivers;
  }

  Widget _buildListSliver(ListingController controller) {
    final items = controller.listings;
    return SliverList(
      delegate: SliverChildBuilderDelegate((context, index) {
        final property = items[index];
        return Padding(
          padding: EdgeInsets.only(bottom: index == items.length - 1 ? 0 : 12),
          child: PropertyGridCard(
            property: property,
            heroPrefix: 'search_$index',
            onTap: () => Get.toNamed('/listing/${property.id}'),
          ),
        );
      }, childCount: items.length),
    );
  }

  Widget _buildGridSliver(ListingController controller, int crossAxisCount) {
    final items = controller.listings;
    final ratio = crossAxisCount == 2 ? 0.68 : 0.66;
    return SliverGrid(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: ratio,
      ),
      delegate: SliverChildBuilderDelegate((context, index) {
        final property = items[index];
        return PropertyGridCard(
          property: property,
          heroPrefix: 'search_$index',
          onTap: () => Get.toNamed('/listing/${property.id}'),
        );
      }, childCount: items.length),
    );
  }
}

class _LoadMoreBar extends StatelessWidget {
  const _LoadMoreBar({required this.controller});

  final ListingController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final isBusy =
          controller.isLoading.value || controller.isRefreshing.value;
      final canLoadMore = controller.hasMore.value && !isBusy;
      if (!controller.hasMore.value && !isBusy) {
        // Terminal page reached: no button to show.
        return const SizedBox.shrink();
      }
      return Center(
        child: FilledButton.icon(
          onPressed: canLoadMore ? () => controller.loadMore() : null,
          icon: isBusy
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.expand_more),
          label: Text(isBusy ? 'Loading...' : 'Load more'),
        ),
      );
    });
  }
}
