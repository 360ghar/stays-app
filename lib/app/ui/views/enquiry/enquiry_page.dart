import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../controllers/trips_controller.dart';

String _deriveStatusCategory(String? status) {
  final value = status?.toString().toLowerCase() ?? '';
  if (value.contains('cancel')) return 'cancelled';
  if (value.contains('complete') || value.contains('past') || value.contains('finish')) {
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
      return const Color(0xFF2563EB);
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

class EnquiriesPage extends StatelessWidget {
  EnquiriesPage({super.key})
      : _controller = Get.find<TripsController>(),
        _statusFilter = RxnString();

  final TripsController _controller;
  final RxnString _statusFilter;
  final NumberFormat _currencyFormat = NumberFormat.currency(
    locale: 'en_IN',
    symbol: '₹',
    decimalDigits: 0,
  );

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = GoogleFonts.poppinsTextTheme(theme.textTheme);

    return Theme(
      data: theme.copyWith(textTheme: textTheme),
      child: Scaffold(
        backgroundColor: const Color(0xFFFAFAFA),
        appBar: AppBar(
          backgroundColor: const Color(0xFFFAFAFA),
          elevation: 0,
          title: Text(
            'Enquiry',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w600,
              fontSize: 20,
              color: theme.colorScheme.onSurface,
            ),
          ),
          actions: [
            Obx(() {
              final hasFilter = _statusFilter.value != null;
              return IconButton(
                tooltip: 'Filter enquiries',
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
            if (_controller.isLoading.value && _controller.pastBookings.isEmpty) {
              return const Center(child: CircularProgressIndicator());
            }

            final filtered = _filteredBookings(_controller.pastBookings);
            final stats = _computeStats(filtered);

            if (filtered.isEmpty) {
              return RefreshIndicator(
                onRefresh: () => _controller.loadPastBookings(forceRefresh: true),
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
                  children: [
                    _TravelStatsCard(
                      totalSpent: stats.totalSpent,
                      totalStays: stats.totalStays,
                      topDestination: stats.topDestination,
                    ),
                    const SizedBox(height: 32),
                    _EmptyState(onReset: () => _statusFilter.value = null),
                  ],
                ),
              );
            }

            final items = _buildListItems(filtered, stats);

            return RefreshIndicator(
              onRefresh: () => _controller.loadPastBookings(forceRefresh: true),
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
                itemCount: items.length,
                itemBuilder: (context, index) {
                  final item = items[index];
                  switch (item.type) {
                    case _ListItemType.stats:
                      return _TravelStatsCard(
                        totalSpent: item.stats!.totalSpent,
                        totalStays: item.stats!.totalStays,
                        topDestination: item.stats!.topDestination,
                      );
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
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
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
    return bookings
        .where((booking) {
          final category = _deriveStatusCategory(booking['status']);
          if (filter == 'upcoming') {
            return category == 'upcoming' || category == 'cancelled';
          }
          return category == filter;
        })
        .toList();
  }

  _TravelStats _computeStats(List<Map<String, dynamic>> bookings) {
    final totalSpent = bookings.fold<num>(
      0,
      (sum, booking) => sum + (booking['totalAmount'] as num? ?? 0),
    );
    final totalStays = bookings.length;
    final destinationCounts = <String, int>{};
    for (final booking in bookings) {
      final location = (booking['location'] ?? '').toString();
      if (location.isEmpty) continue;
      destinationCounts.update(location, (value) => value + 1, ifAbsent: () => 1);
    }
    String topDestination = '–';
    if (destinationCounts.isNotEmpty) {
      destinationCounts.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      topDestination = destinationCounts.entries.first.key;
    }
    return _TravelStats(
      totalSpent: totalSpent.toDouble(),
      totalStays: totalStays,
      topDestination: topDestination,
    );
  }

  List<_ListItem> _buildListItems(
    List<Map<String, dynamic>> bookings,
    _TravelStats stats,
  ) {
    final items = <_ListItem>[
      _ListItem.stats(stats),
    ];
    final grouped = <int, List<Map<String, dynamic>>>{};
    final sorted = List<Map<String, dynamic>>.from(bookings)
      ..sort(
        (a, b) {
          final aDate = DateTime.tryParse(a['checkIn']?.toString() ?? '') ?? DateTime.now();
          final bDate = DateTime.tryParse(b['checkIn']?.toString() ?? '') ?? DateTime.now();
          return bDate.compareTo(aDate);
        },
      );
    for (final booking in sorted) {
      final checkIn =
          DateTime.tryParse(booking['checkIn']?.toString() ?? '') ?? DateTime.now();
      grouped.putIfAbsent(checkIn.year, () => []).add(booking);
    }
    final years = grouped.keys.toList()..sort((a, b) => b.compareTo(a));
    var animationIndex = 0;
    for (final year in years) {
      items.add(_ListItem.spacing(items.length == 1 ? 20 : 24));
      items.add(_ListItem.year(year));
      items.add(_ListItem.spacing(12));
      for (final booking in grouped[year]!) {
        items.add(
          _ListItem.booking(
            booking,
            animationIndex: animationIndex++,
          ),
        );
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
      _StatusOption(null, 'All enquiries'),
      _StatusOption('completed', 'Completed enquiries'),
      _StatusOption('upcoming', 'Upcoming enquiries'),
      _StatusOption('today', 'Today\'s enquiries'),
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
                style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),
              ...options.map(
                (option) {
                  final isActive = _statusFilter.value == option.value ||
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
                        ? Icon(Icons.check_circle_rounded, color: theme.colorScheme.primary)
                        : null,
                    onTap: () {
                      _statusFilter.value = option.value;
                      Get.back();
                    },
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TravelStats {
  const _TravelStats({
    required this.totalSpent,
    required this.totalStays,
    required this.topDestination,
  });

  final double totalSpent;
  final int totalStays;
  final String topDestination;
}

class _ListItem {
  const _ListItem._(
    this.type, {
    this.booking,
    this.year,
    this.spacing,
    this.animationIndex = 0,
    this.stats,
  });

  final _ListItemType type;
  final Map<String, dynamic>? booking;
  final int? year;
  final double? spacing;
  final int animationIndex;
  final _TravelStats? stats;

  factory _ListItem.stats(_TravelStats stats) =>
      _ListItem._(_ListItemType.stats, stats: stats);
  factory _ListItem.year(int year) => _ListItem._(_ListItemType.yearHeader, year: year);
  factory _ListItem.booking(Map<String, dynamic> booking, {int animationIndex = 0}) =>
      _ListItem._(_ListItemType.booking, booking: booking, animationIndex: animationIndex);
  factory _ListItem.spacing(double value) => _ListItem._(_ListItemType.spacing, spacing: value);
}

enum _ListItemType { stats, yearHeader, booking, spacing }

class _TravelStatsCard extends StatelessWidget {
  const _TravelStatsCard({
    required this.totalSpent,
    required this.totalStays,
    required this.topDestination,
  });

  final double totalSpent;
  final int totalStays;
  final String topDestination;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currencyFormat = NumberFormat.currency(
      locale: 'en_IN',
      symbol: '₹',
      decimalDigits: 0,
    );
    final items = [
      _StatItemData(
        icon: Icons.hotel_rounded,
        background: const Color(0xFFE4F0FF),
        iconColor: const Color(0xFF1D4ED8),
        value: '$totalStays',
        label: 'Total stays',
      ),
      _StatItemData(
        icon: Icons.currency_rupee_rounded,
        background: const Color(0xFFE9FBE7),
        iconColor: const Color(0xFF15803D),
        value: currencyFormat.format(totalSpent),
        label: 'Total spent',
      ),
      _StatItemData(
        icon: Icons.place_rounded,
        background: const Color(0xFFFFF4DB),
        iconColor: const Color(0xFFEA580C),
        value: topDestination.isEmpty ? '–' : topDestination,
        label: 'Top destination',
      ),
    ];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Your Travel Stats',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w600,
              fontSize: 18,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 18),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: items
                .map(
                  (item) => Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      child: _StatItem(data: item),
                    ),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }
}

class _StatItemData {
  const _StatItemData({
    required this.icon,
    required this.background,
    required this.iconColor,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final Color background;
  final Color iconColor;
  final String value;
  final String label;
}

class _StatItem extends StatelessWidget {
  const _StatItem({required this.data});

  final _StatItemData data;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: data.background,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(data.icon, color: data.iconColor, size: 22),
          ),
          const SizedBox(height: 10),
          Text(
            data.value,
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w600,
              fontSize: 16,
              color: theme.colorScheme.onSurface,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            data.label,
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w400,
              fontSize: 12,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

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

    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
            child: AspectRatio(
              aspectRatio: 3 / 2,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      color: colors.surfaceVariant,
                      alignment: Alignment.center,
                      child: Icon(
                        Icons.photo,
                        size: 36,
                        color: colors.onSurface.withValues(alpha: 0.5),
                      ),
                    ),
                  ),
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withValues(alpha: 0),
                            Colors.black.withValues(alpha: 0.25),
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
                        color: badgeColor,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        child: Text(
                          _statusBadgeLabel(statusCategory),
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
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
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  (booking['hotelName'] ?? 'Stay').toString(),
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    fontSize: 18,
                    color: colors.onSurface,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  (booking['location'] ?? '').toString(),
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w400,
                    fontSize: 14,
                    color: colors.onSurface.withValues(alpha: 0.7),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today_rounded,
                      size: 16,
                      color: colors.onSurface.withValues(alpha: 0.65),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        dateRange,
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w500,
                          fontSize: 14,
                          color: colors.onSurface,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Icon(
                      Icons.group_rounded,
                      size: 16,
                      color: colors.onSurface.withValues(alpha: 0.65),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      guestsLabel,
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w400,
                        fontSize: 13,
                        color: colors.onSurface.withValues(alpha: 0.75),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      priceLabel,
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w700,
                        fontSize: 18,
                        color: colors.onSurface,
                      ),
                    ),
                    if (onCancel != null)
                      TextButton(
                        onPressed: onCancel,
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.redAccent,
                        ),
                        child: const Text('Cancel'),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
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
            'No enquiries to show',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 16),
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
          TextButton(
            onPressed: onReset,
            child: const Text('Clear filters'),
          ),
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
