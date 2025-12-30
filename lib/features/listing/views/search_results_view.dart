import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:stays_app/app/controllers/filter_controller.dart';
import 'package:stays_app/app/data/models/unified_filter_model.dart';
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
            onPressed: () {
              Get.snackbar('Sort', 'Sorting options coming soon');
            },
          ),
          IconButton(
            tooltip: 'Map',
            icon: Icon(Icons.map_outlined, color: colors.onSurface),
            onPressed: () {
              Get.snackbar('Map', 'Map view coming soon');
            },
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
    final total = controller.totalCount.value;
    final currentPage = controller.currentPage.value;
    final totalPages = controller.totalPages.value;
    final pageSize = controller.pageSize.value;
    final startIndex = total == 0 ? 0 : ((currentPage - 1) * pageSize) + 1;
    final endIndex = total == 0
        ? 0
        : math.min(startIndex + items.length - 1, total);
    final tags = filters.activeTags();

    slivers.add(
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                total > 0
                    ? 'Found $total stays • Page $currentPage of $totalPages • $pageSize per page'
                    : 'No stays found',
                style: textStyles.bodyMedium?.copyWith(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (total > 0)
                Text(
                  'Showing $startIndex–$endIndex of $total properties',
                  style: textStyles.bodySmall?.copyWith(
                    fontSize: 12,
                    color: colors.onSurface.withValues(alpha: 0.7),
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
          child: _PaginationBar(controller: controller),
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

class _PaginationBar extends StatelessWidget {
  const _PaginationBar({required this.controller});

  final ListingController controller;

  @override
  Widget build(BuildContext context) {
    final isBusy = controller.isLoading.value || controller.isRefreshing.value;
    final canGoPrev = controller.currentPage.value > 1 && !isBusy;
    final canGoNext =
        controller.currentPage.value < controller.totalPages.value && !isBusy;
    final pageSize = controller.pageSize.value;

    final summary = Text(
      'Page ${controller.currentPage.value} of ${controller.totalPages.value}',
      style: const TextStyle(fontWeight: FontWeight.w600),
      overflow: TextOverflow.ellipsis,
    );

    final controls = Wrap(
      spacing: 8,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        DropdownButton<int>(
          value: pageSize,
          onChanged: isBusy
              ? null
              : (value) {
                  if (value != null) {
                    controller.changePageSize(value);
                  }
                },
          items: const [10, 20, 30, 50]
              .map(
                (value) => DropdownMenuItem<int>(
                  value: value,
                  child: Text('Limit $value'),
                ),
              )
              .toList(),
        ),
        OutlinedButton.icon(
          onPressed: canGoPrev ? () => controller.previousPage() : null,
          icon: const Icon(Icons.chevron_left),
          label: const Text('Previous'),
        ),
        FilledButton.icon(
          onPressed: canGoNext ? () => controller.nextPage() : null,
          icon: const Icon(Icons.chevron_right),
          label: const Text('Next'),
        ),
      ],
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 420;
        if (isCompact) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [summary, const SizedBox(height: 8), controls],
          );
        }
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(child: summary),
            const SizedBox(width: 12),
            controls,
          ],
        );
      },
    );
  }
}
