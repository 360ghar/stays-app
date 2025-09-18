import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../controllers/filter_controller.dart';
import '../../../controllers/trips_controller.dart';
import '../../widgets/common/filter_button.dart';
import '../../../utils/helpers/currency_helper.dart';
import '../../theme/theme_extensions.dart';

class TripsView extends GetView<TripsController> {
  const TripsView({super.key});

  @override
  Widget build(BuildContext context) {
    final filterController = Get.find<FilterController>();
    final filtersRx = filterController.rxFor(FilterScope.booking);

    final colors = context.colors;
    final textStyles = context.textStyles;
    return Scaffold(
      backgroundColor: colors.surface,
      appBar: AppBar(
        backgroundColor: colors.surface,
        elevation: 0,
        title: Text(
          'trips.title'.tr,
          style: textStyles.titleLarge?.copyWith(
            color: colors.onSurface,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          Obx(() {
            final isActive = filtersRx.value.isNotEmpty;
            return Padding(
              padding: const EdgeInsets.only(right: 12),
              child: SizedBox(
                height: 36,
                child: FilterButton(
                  isActive: isActive,
                  onPressed: () => filterController.openFilterSheet(
                    context,
                    FilterScope.booking,
                  ),
                ),
              ),
            );
          }),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value && controller.pastBookings.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        final hasFilters = filtersRx.value.isNotEmpty;
        if (controller.pastBookings.isEmpty) {
          if (hasFilters && controller.totalHistoryCount > 0) {
            return _buildFilteredEmptyState(context, filterController);
          }
          return _buildEmptyState(context);
        }

        final tags = filtersRx.value.activeTags();
        final headerWidgets = <Widget>[];
        if (tags.isNotEmpty) {
          headerWidgets.add(
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: _buildFilterTags(context, tags, filterController),
            ),
          );
        }
        headerWidgets.add(_buildStatsSection(context));

        final bookings = controller.pastBookings;

        return RefreshIndicator(
          onRefresh: () async =>
              controller.loadPastBookings(forceRefresh: true),
          child: ListView.builder(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            itemCount: headerWidgets.length + bookings.length,
            itemBuilder: (context, index) {
              if (index < headerWidgets.length) {
                return headerWidgets[index];
              }
              final booking = bookings[index - headerWidgets.length];
              return _buildBookingCard(context, booking);
            },
          ),
        );
      }),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final colors = context.colors;
    final textStyles = context.textStyles;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.luggage_outlined,
              size: 80,
              color: colors.outline.withValues(alpha: 0.4),
            ),
            const SizedBox(height: 24),
            Text(
              'trips.empty_title'.tr,
              style: textStyles.titleMedium?.copyWith(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: colors.onSurface,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'trips.empty_body'.tr,
              textAlign: TextAlign.center,
              style: textStyles.bodyMedium?.copyWith(
                fontSize: 16,
                color: colors.onSurface.withValues(alpha: 0.7),
                height: 1.5,
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () => Get.back(),
              style: ElevatedButton.styleFrom(
                backgroundColor: colors.primary,
                foregroundColor: colors.onPrimary,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'trips.browse_stays'.tr,
                style: textStyles.labelLarge?.copyWith(fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilteredEmptyState(
    BuildContext context,
    FilterController filterController,
  ) {
    final colors = context.colors;
    final textStyles = context.textStyles;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.filter_alt_off,
              size: 80,
              color: colors.outline.withValues(alpha: 0.4),
            ),
            const SizedBox(height: 24),
            Text(
              'trips.no_match_title'.tr,
              style: textStyles.titleMedium?.copyWith(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: colors.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'trips.no_match_body'.tr,
              textAlign: TextAlign.center,
              style: textStyles.bodyMedium?.copyWith(
                fontSize: 16,
                color: colors.onSurface.withValues(alpha: 0.7),
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => filterController.openFilterSheet(
                context,
                FilterScope.booking,
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: colors.primary,
                foregroundColor: colors.onPrimary,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'trips.adjust_filters'.tr,
                style: textStyles.labelLarge?.copyWith(fontSize: 16),
              ),
            ),
            TextButton(
              onPressed: () => filterController.clear(FilterScope.booking),
              style: TextButton.styleFrom(foregroundColor: colors.primary),
              child: Text('trips.clear_filters'.tr),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterTags(
    BuildContext context,
    List<String> tags,
    FilterController filterController,
  ) {
    final colors = Theme.of(context).colorScheme;
    final textStyles = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
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
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton(
            onPressed: () => filterController.clear(FilterScope.booking),
            style: TextButton.styleFrom(foregroundColor: colors.primary),
            child: const Text('Clear filters'),
          ),
        ),
      ],
    );
  }

  Widget _buildStatsSection(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textStyles = Theme.of(context).textTheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: (Theme.of(context).brightness == Brightness.dark)
                ? Colors.black.withValues(alpha: 0.4)
                : Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Your Travel Stats',
            style: textStyles.titleMedium?.copyWith(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: colors.onSurface,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  context,
                  icon: Icons.hotel,
                  value: controller.totalBookings.toString(),
                  label: 'Total stays',
                  color: Colors.blue,
                ),
              ),
              Expanded(
                child: _buildStatItem(
                  context,
                  icon: Icons.attach_money,
                  value: CurrencyHelper.format(controller.totalSpent),
                  label: 'Total spent',
                  color: Colors.green,
                ),
              ),
              Expanded(
                child: _buildStatItem(
                  context,
                  icon: Icons.location_on,
                  value: controller.favoriteDestination,
                  label: 'Top destination',
                  color: Colors.orange,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(
    BuildContext context, {
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    final colors = Theme.of(context).colorScheme;
    final textStyles = Theme.of(context).textTheme;
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: textStyles.titleSmall?.copyWith(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: colors.onSurface,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: textStyles.bodySmall?.copyWith(
            fontSize: 12,
            color: colors.onSurface.withValues(alpha: 0.7),
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildBookingCard(BuildContext context, Map<String, dynamic> booking) {
    final status = (booking['status'] ?? 'pending').toString();
    final statusColor = status == 'completed' ? Colors.green : Colors.orange;
    final guests = booking['guests'];
    final rooms = booking['rooms'];
    final guestsLabel = "${guests ?? '-'} guests - ${rooms ?? '-'} room(s)";
    final totalAmount = (booking['totalAmount'] as num?)?.toDouble() ?? 0;
    final totalDisplay = CurrencyHelper.format(totalAmount);
    final dateRange =
        "${_formatDate(booking['checkIn'] ?? '')} - ${_formatDate(booking['checkOut'] ?? '')}";
    final title = (booking['hotelName'] ?? 'Stay').toString();
    final location = (booking['location'] ?? '').toString();
    final imageUrl = (booking['image'] ?? '').toString();
    final canReview = booking['canReview'] == true;

    final colors = Theme.of(context).colorScheme;
    final textStyles = Theme.of(context).textTheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: (Theme.of(context).brightness == Brightness.dark)
                ? Colors.black.withValues(alpha: 0.4)
                : Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: () => controller.viewBookingDetails(booking),
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(16),
                  ),
                  child: imageUrl.isNotEmpty
                      ? Image.network(
                          imageUrl,
                          height: 160,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        )
                      : Container(
                          height: 160,
                          width: double.infinity,
                          color: colors.surfaceContainerHighest,
                          child: Icon(
                            Icons.image,
                            size: 50,
                            color: colors.onSurface.withValues(alpha: 0.5),
                          ),
                        ),
                ),
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      status.toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: textStyles.titleMedium?.copyWith(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: colors.onSurface,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.location_on_outlined,
                        size: 16,
                        color: colors.onSurface.withValues(alpha: 0.7),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          location,
                          style: textStyles.bodySmall?.copyWith(
                            fontSize: 14,
                            color: colors.onSurface.withValues(alpha: 0.7),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: colors.surfaceContainerHighest.withValues(
                        alpha: 0.5,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.calendar_today,
                              size: 16,
                              color: colors.onSurface.withValues(alpha: 0.7),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              dateRange,
                              style: textStyles.bodyMedium?.copyWith(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: colors.onSurface,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(
                              Icons.group,
                              size: 16,
                              color: colors.onSurface.withValues(alpha: 0.7),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              guestsLabel,
                              style: textStyles.bodySmall?.copyWith(
                                fontSize: 14,
                                color: colors.onSurface.withValues(alpha: 0.7),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        totalDisplay,
                        style: textStyles.titleMedium?.copyWith(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: colors.onSurface,
                        ),
                      ),
                      Row(
                        children: [
                          if (canReview)
                            TextButton(
                              onPressed: () => controller.leaveReview(booking),
                              child: const Text(
                                'Review',
                                style: TextStyle(fontSize: 14),
                              ),
                            ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: () => controller.rebookHotel(booking),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: colors.primary,
                              foregroundColor: colors.onPrimary,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: const Text(
                              'Book Again',
                              style: TextStyle(fontSize: 14),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(String dateStr) {
    try {
      final clean = dateStr.isEmpty
          ? DateTime.now().toIso8601String()
          : dateStr;
      final date = DateTime.parse(clean);
      const months = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec',
      ];
      return '${date.day} ${months[date.month - 1]}, ${date.year}';
    } catch (_) {
      return dateStr;
    }
  }
}
