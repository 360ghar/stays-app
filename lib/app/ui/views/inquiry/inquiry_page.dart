import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../utils/constants/app_constants.dart';

import '../../../controllers/filter_controller.dart';
import '../../../controllers/trips_controller.dart';
import '../../widgets/common/location_filter_app_bar.dart';

String _deriveStatusCategory(String? status) {
  final value = status?.toString().toLowerCase() ?? '';
  if (value.contains('cancel')) return 'cancelled';
  if (value.contains('complete') ||
      value.contains('past') ||
      value.contains('finish')) {
    return 'completed';
  }
  if (value.contains('today') ||
      value.contains('current') ||
      value.contains('ongoing') ||
      value.contains('checkin')) {
    return 'today';
  }
  return 'upcoming';
}

Color _statusBadgeColor(String category) {
  switch (category) {
    case 'completed':
      return const Color(0xFF1B9A5E);
    case 'today':
      return const Color(0xFF60A5FA);
    case 'cancelled':
      return const Color(0xFFDC2626);
    default:
      return const Color(0xFFF97316);
  }
}

String _statusBadgeLabel(String category) {
  switch (category) {
    case 'completed':
      return 'COMPLETED';
    case 'today':
      return 'TODAY';
    case 'cancelled':
      return 'CANCELLED';
    default:
      return 'UPCOMING';
  }
}

class InquiriesPage extends StatelessWidget {
  InquiriesPage({super.key})
    : _controller = Get.find<TripsController>(),
      _statusFilter = RxnString();

  final TripsController _controller;
  final RxnString _statusFilter;
  final NumberFormat _currencyFormat = NumberFormat.currency(
    locale: 'en_IN',
    symbol: AppConstants.defaultCurrencySymbol,
    decimalDigits: 0,
  );

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = GoogleFonts.poppinsTextTheme(theme.textTheme);

    final scaffoldColor = theme.colorScheme.surface;
    return Theme(
      data: theme.copyWith(textTheme: textTheme),
      child: Scaffold(
        backgroundColor: scaffoldColor,
        appBar: LocationFilterAppBar(
          scope: FilterScope.booking,
          trailingActions: [
            Obx(() {
              final hasFilter = _statusFilter.value != null;
              return IconButton(
                tooltip: 'Filter inquiries',
                icon: Icon(
                  Icons.filter_alt_rounded,
                  color: hasFilter
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurface,
                ),
                onPressed: () => _showFilterSheet(context),
              );
            }),
            const SizedBox(width: 4),
          ],
        ),
        body: SafeArea(
          child: Obx(() {
            if (_controller.isLoading.value &&
                _controller.pastBookings.isEmpty) {
              return const Center(child: CircularProgressIndicator());
            }

            final filtered = _filteredBookings(_controller.pastBookings);

            if (filtered.isEmpty) {
              return RefreshIndicator(
                onRefresh: () =>
                    _controller.loadPastBookings(forceRefresh: true),
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
                  children: [
                    _EmptyState(onReset: () => _statusFilter.value = null),
                  ],
                ),
              );
            }

            final items = _buildListItems(filtered);

            return RefreshIndicator(
              onRefresh: () => _controller.loadPastBookings(forceRefresh: true),
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                itemCount: items.length,
                itemBuilder: (context, index) {
                  final item = items[index];
                  switch (item.type) {
                    case _ListItemType.spacing:
                      return SizedBox(height: item.spacing ?? 16);
                    case _ListItemType.yearHeader:
                      return Padding(
                        padding: const EdgeInsets.only(top: 8, bottom: 4),
                        child: Text(
                          '${item.year}',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                            color: theme.colorScheme.onSurface.withValues(
                              alpha: 0.7,
                            ),
                          ),
                        ),
                      );
                    case _ListItemType.booking:
                      final booking = item.booking!;
                      final priceLabel = _currencyFormat.format(
                        (booking['totalAmount'] as num?)?.toDouble() ?? 0,
                      );
                      final category = _deriveStatusCategory(booking['status']);
                      final animationDuration = Duration(
                        milliseconds: 450 + (item.animationIndex * 120),
                      );
                      return TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0, end: 1),
                        duration: animationDuration,
                        curve: Curves.easeOut,
                        builder: (context, value, child) {
                          return Opacity(
                            opacity: value,
                            child: Transform.translate(
                              offset: Offset(0, 24 * (1 - value)),
                              child: child,
                            ),
                          );
                        },
                        child: _BookingCard(
                          booking: booking,
                          priceLabel: priceLabel,
                          onCancel: (category == 'upcoming')
                              ? () => _controller.cancelBooking(
                                  booking['id'].toString(),
                                )
                              : null,
                        ),
                      );
                  }
                },
              ),
            );
          }),
        ),
      ),
    );
  }

  List<Map<String, dynamic>> _filteredBookings(
    List<Map<String, dynamic>> bookings,
  ) {
    final filter = _statusFilter.value;
    if (filter == null) {
      return List<Map<String, dynamic>>.from(bookings);
    }
    return bookings.where((booking) {
      final category = _deriveStatusCategory(booking['status']);
      if (filter == 'upcoming') {
        return category == 'upcoming' || category == 'cancelled';
      }
      return category == filter;
    }).toList();
  }

  List<_ListItem> _buildListItems(
    List<Map<String, dynamic>> bookings,
  ) {
    final items = <_ListItem>[];
    final grouped = <int, List<Map<String, dynamic>>>{};
    final sorted = List<Map<String, dynamic>>.from(bookings)
      ..sort((a, b) {
        final aDate =
            DateTime.tryParse(a['checkIn']?.toString() ?? '') ?? DateTime.now();
        final bDate =
            DateTime.tryParse(b['checkIn']?.toString() ?? '') ?? DateTime.now();
        return bDate.compareTo(aDate);
      });
    for (final booking in sorted) {
      final checkIn =
          DateTime.tryParse(booking['checkIn']?.toString() ?? '') ??
          DateTime.now();
      grouped.putIfAbsent(checkIn.year, () => []).add(booking);
    }
    final years = grouped.keys.toList()..sort((a, b) => b.compareTo(a));
    var animationIndex = 0;
    for (final year in years) {
      if (items.isNotEmpty) {
        items.add(_ListItem.spacing(24));
      }
      items.add(_ListItem.year(year));
      items.add(_ListItem.spacing(12));
      for (final booking in grouped[year]!) {
        items.add(_ListItem.booking(booking, animationIndex: animationIndex++));
        items.add(_ListItem.spacing(16));
      }
      if (items.isNotEmpty && items.last.type == _ListItemType.spacing) {
        items.removeLast();
      }
    }
    return items;
  }

  void _showFilterSheet(BuildContext context) {
    final theme = Theme.of(context);
    final options = const [
      _StatusOption(null, 'All inquiries'),
      _StatusOption('completed', 'Completed inquiries'),
      _StatusOption('upcoming', 'Upcoming inquiries'),
      _StatusOption('today', 'Today\'s inquiries'),
    ];
    Get.bottomSheet(
      SafeArea(
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Filter by status',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              ...options.map((option) {
                final isActive =
                    _statusFilter.value == option.value ||
                    (option.value == null && _statusFilter.value == null);
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    option.label,
                    style: GoogleFonts.poppins(
                      fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                    ),
                  ),
                  trailing: isActive
                      ? Icon(
                          Icons.check_circle_rounded,
                          color: theme.colorScheme.primary,
                        )
                      : null,
                  onTap: () {
                    _statusFilter.value = option.value;
                    Get.back();
                  },
                );
              }),
            ],
          ),
        ),
      ),
    );
  }
}

class _ListItem {
  const _ListItem._(
    this.type, {
    this.booking,
    this.year,
    this.spacing,
    this.animationIndex = 0,
  });

  final _ListItemType type;
  final Map<String, dynamic>? booking;
  final int? year;
  final double? spacing;
  final int animationIndex;
  factory _ListItem.year(int year) =>
      _ListItem._(_ListItemType.yearHeader, year: year);
  factory _ListItem.booking(
    Map<String, dynamic> booking, {
    int animationIndex = 0,
  }) => _ListItem._(
    _ListItemType.booking,
    booking: booking,
    animationIndex: animationIndex,
  );
  factory _ListItem.spacing(double value) =>
      _ListItem._(_ListItemType.spacing, spacing: value);
}

enum _ListItemType { yearHeader, booking, spacing }

class _BookingCard extends StatelessWidget {
  const _BookingCard({
    required this.booking,
    required this.priceLabel,
    this.onCancel,
  });

  final Map<String, dynamic> booking;
  final String priceLabel;
  final VoidCallback? onCancel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final statusCategory = _deriveStatusCategory(booking['status']);
    final badgeColor = _statusBadgeColor(statusCategory);
    final imageUrl = (booking['image'] ?? '').toString();
    final dateRange = _formatDateRange(booking);
    final guestsLabel = _formatGuests(booking);
    Widget buildImagePlaceholder() => Container(
          color: colors.surfaceVariant,
          alignment: Alignment.center,
          child: Icon(
            Icons.photo,
            size: 28,
            color: colors.onSurface.withValues(alpha: 0.5),
          ),
        );
    Widget buildImage() {
      if (imageUrl.isEmpty) return buildImagePlaceholder();
      return CachedNetworkImage(
        imageUrl: imageUrl,
        fit: BoxFit.cover,
        placeholder: (context, url) => buildImagePlaceholder(),
        errorWidget: (context, url, error) => buildImagePlaceholder(),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: colors.outlineVariant.withValues(alpha: 0.4),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: SizedBox(
                width: 80,
                height: 80,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    buildImage(),
                    Positioned(
                      top: 6,
                      right: 6,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: badgeColor,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          child: Text(
                            _statusBadgeLabel(statusCategory),
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w600,
                              fontSize: 8.5,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              (booking['hotelName'] ?? 'Stay').toString(),
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w600,
                                fontSize: 14.5,
                                color: colors.onSurface,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              (booking['location'] ?? '').toString(),
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w400,
                                fontSize: 11.5,
                                color: colors.onSurface.withValues(alpha: 0.7),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      _DetailChip(
                        icon: Icons.calendar_today_rounded,
                        label: dateRange,
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _DetailChip(
                            icon: Icons.group_rounded,
                            label: guestsLabel,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            priceLabel,
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                              color: colors.primary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  if (onCancel != null) ...[
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: onCancel,
                        style: TextButton.styleFrom(
                          foregroundColor: colors.error,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          textStyle: const TextStyle(fontSize: 12),
                        ),
                        child: const Text('Cancel'),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDateRange(Map<String, dynamic> booking) {
    final checkIn = DateTime.tryParse(booking['checkIn']?.toString() ?? '');
    final checkOut = DateTime.tryParse(booking['checkOut']?.toString() ?? '');
    if (checkIn == null || checkOut == null) return '-';
    final formatter = DateFormat('dd MMM, yyyy');
    return '${formatter.format(checkIn)} – ${formatter.format(checkOut)}';
  }

  String _formatGuests(Map<String, dynamic> booking) {
    final guests = (booking['guests'] as num?)?.toInt() ?? 0;
    final rooms = (booking['rooms'] as num?)?.toInt() ?? 0;
    final guestLabel = guests == 1 ? 'guest' : 'guests';
    final roomLabel = rooms == 1 ? 'room' : 'rooms';
    return '$guests $guestLabel • $rooms $roomLabel';
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onReset});

  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.airline_seat_flat_angled_rounded,
            size: 48,
            color: theme.colorScheme.primary.withValues(alpha: 0.7),
          ),
          const SizedBox(height: 16),
          Text(
            'No inquiries to show',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w600,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try switching or clearing the filters to see all your stays.',
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          TextButton(onPressed: onReset, child: const Text('Clear filters')),
        ],
      ),
    );
  }
}

class _StatusOption {
  const _StatusOption(this.value, this.label);

  final String? value;
  final String label;
}

class _DetailChip extends StatelessWidget {
  const _DetailChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 12,
            color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 11,
              color: theme.colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}
