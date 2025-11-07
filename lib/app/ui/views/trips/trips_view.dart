import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../controllers/filter_controller.dart';
import '../../../controllers/trips_controller.dart';
import '../../../utils/helpers/currency_helper.dart';
import '../../theme/theme_extensions.dart';
import '../../widgets/common/location_filter_app_bar.dart';

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
      appBar: LocationFilterAppBar(
        title: 'enquiries.title'.tr,
        scope: FilterScope.booking,
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
              'enquiries.empty_title'.tr,
              style: textStyles.titleMedium?.copyWith(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: colors.onSurface,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'enquiries.empty_body'.tr,
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
                'enquiries.browse_stays'.tr,
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
              'enquiries.no_match_title'.tr,
              style: textStyles.titleMedium?.copyWith(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: colors.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'enquiries.no_match_body'.tr,
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
                'enquiries.adjust_filters'.tr,
                style: textStyles.labelLarge?.copyWith(fontSize: 16),
              ),
            ),
            TextButton(
              onPressed: () => filterController.clear(FilterScope.booking),
              style: TextButton.styleFrom(foregroundColor: colors.primary),
              child: Text('enquiries.clear_filters'.tr),
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
    final isUpcoming = status == 'upcoming';

    final colors = Theme.of(context).colorScheme;
    final textStyles = Theme.of(context).textTheme;
    final brightness = Theme.of(context).brightness;
    final width = MediaQuery.of(context).size.width;
    final widthFactor = width >= 720
        ? 0.45
        : width >= 520
        ? 0.5
        : width >= 400
        ? 0.55
        : 0.65;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Align(
        alignment: Alignment.center,
        child: FractionallySizedBox(
          widthFactor: widthFactor,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Material(
              color: Colors.transparent,
              elevation: brightness == Brightness.dark ? 2 : 6,
              shadowColor: Colors.black.withValues(
                alpha: brightness == Brightness.dark ? 0.45 : 0.12,
              ),
              borderRadius: BorderRadius.circular(18),
              clipBehavior: Clip.antiAlias,
              child: Ink(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      colors.surface.withValues(
                        alpha: brightness == Brightness.dark ? 0.97 : 0.995,
                      ),
                      Color.alphaBlend(
                        colors.primary.withValues(
                          alpha: brightness == Brightness.dark ? 0.08 : 0.04,
                        ),
                        colors.surface.withValues(
                          alpha: brightness == Brightness.dark ? 0.95 : 0.985,
                        ),
                      ),
                    ],
                  ),
                ),
                child: InkWell(
                  borderRadius: BorderRadius.circular(18),
                  onTap: () => controller.viewBookingDetails(booking),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _BookingImageHeader(
                        imageUrl: imageUrl,
                        status: status,
                        statusColor: statusColor,
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        title,
                                        style: textStyles.titleMedium?.copyWith(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 18,
                                          color: colors.onSurface,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.location_on_outlined,
                                            size: 16,
                                            color: colors.onSurface.withValues(
                                              alpha: 0.7,
                                            ),
                                          ),
                                          const SizedBox(width: 4),
                                          Expanded(
                                            child: Text(
                                              location,
                                              style: textStyles.bodySmall
                                                  ?.copyWith(
                                                    fontSize: 13,
                                                    color: colors.onSurface
                                                        .withValues(alpha: 0.7),
                                                  ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 12),
                                _BookingPricePill(totalDisplay: totalDisplay),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                _BookingDetailChip(
                                  icon: Icons.calendar_today,
                                  label: dateRange,
                                ),
                                _BookingDetailChip(
                                  icon: Icons.group,
                                  label: guestsLabel,
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                if (isUpcoming)
                                  TextButton(
                                    onPressed: () {
                                      final bookingId = (booking['id'] ?? '')
                                          .toString();
                                      if (bookingId.isEmpty) return;
                                      controller.cancelBooking(bookingId);
                                    },
                                    style: TextButton.styleFrom(
                                      foregroundColor: colors.error,
                                    ),
                                    child: const Text('Cancel'),
                                  )
                                else ...[
                                  if (canReview)
                                    TextButton(
                                      onPressed: () =>
                                          controller.leaveReview(booking),
                                      child: const Text('Review'),
                                    ),
                                  if (canReview) const SizedBox(width: 6),
                                  ElevatedButton(
                                    onPressed: () =>
                                        controller.rebookHotel(booking),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: colors.primary,
                                      foregroundColor: colors.onPrimary,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 18,
                                        vertical: 10,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                    child: const Text('Inquire Again'),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
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

class _BookingImageHeader extends StatelessWidget {
  const _BookingImageHeader({
    required this.imageUrl,
    required this.status,
    required this.statusColor,
  });

  final String imageUrl;
  final String status;
  final Color statusColor;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    Widget buildPlaceholder() => Container(
          color: colors.surfaceContainerHighest.withValues(alpha: 0.4),
          alignment: Alignment.center,
          child: Icon(
            Icons.hotel,
            size: 40,
            color: colors.onSurface.withValues(alpha: 0.5),
          ),
        );
    final imageWidget = imageUrl.isEmpty
        ? buildPlaceholder()
        : CachedNetworkImage(
            imageUrl: imageUrl,
            fit: BoxFit.cover,
            placeholder: (context, url) => buildPlaceholder(),
            errorWidget: (context, url, error) => buildPlaceholder(),
          );
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
      child: AspectRatio(
        aspectRatio: 3 / 2,
        child: Stack(
          fit: StackFit.expand,
          children: [
            imageWidget,
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0),
                      Colors.black.withValues(alpha: 0.3),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              top: 14,
              right: 14,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: statusColor,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  child: Text(
                    status.toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BookingPricePill extends StatelessWidget {
  const _BookingPricePill({required this.totalDisplay});

  final String totalDisplay;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Text(
          totalDisplay,
          style: theme.textTheme.labelLarge?.copyWith(
            color: colors.primary,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

class _BookingDetailChip extends StatelessWidget {
  const _BookingDetailChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textStyle = Theme.of(context).textTheme.bodySmall?.copyWith(
      color: colors.onSurface.withValues(alpha: 0.75),
      fontWeight: FontWeight.w500,
    );
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surfaceVariant.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14,
              color: colors.onSurfaceVariant.withValues(alpha: 0.8),
            ),
            const SizedBox(width: 6),
            Text(label, style: textStyle),
          ],
        ),
      ),
    );
  }
}
