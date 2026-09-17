import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import 'package:stays_app/app/data/models/booking_model.dart';
import 'package:stays_app/core/router/app_router.dart';
import 'package:stays_app/core/theme/tokens.dart';
import 'package:stays_app/core/ui/async_state.dart';
import 'package:stays_app/features/trips/providers/trips_providers.dart';

/// V2 trips (inquiries). Status pill, dates, total. Tap opens the stay.
class TripsScreen extends ConsumerWidget {
  const TripsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(tripsProvider);
    final notifier = ref.read(tripsProvider.notifier);
    return Scaffold(
      backgroundColor: StayTokens.paper,
      appBar: AppBar(title: const Text('Trips')),
      body: Builder(
        builder: (context) {
          if (state.isLoading && state.bookings.isEmpty) {
            return const AsyncState.loading(message: 'Loading trips…');
          }
          if (state.error.isNotEmpty && state.bookings.isEmpty) {
            return AsyncState.error(
              state.error,
              onRetry: () => notifier.refresh(),
            );
          }
          if (state.bookings.isEmpty) {
            return const AsyncState.empty(
              message: 'No trips yet. Request to book a stay to see it here.',
            );
          }
          return RefreshIndicator(
            onRefresh: notifier.refresh,
            child: ListView.separated(
              padding: const EdgeInsets.all(StayTokens.s16),
              itemCount: state.bookings.length,
              separatorBuilder: (_, _) =>
                  const SizedBox(height: StayTokens.s12),
              itemBuilder: (context, i) =>
                  _TripCard(booking: state.bookings[i]),
            ),
          );
        },
      ),
    );
  }
}

class _TripCard extends StatelessWidget {
  const _TripCard({required this.booking});
  final Booking booking;

  @override
  Widget build(BuildContext context) {
    final dates =
        '${DateFormat.MMMd().format(booking.checkInDate)} – '
        '${DateFormat.MMMd().format(booking.checkOutDate)}';
    return GestureDetector(
      onTap: () => context.push(AppPaths.listing('${booking.propertyId}')),
      child: Container(
        decoration: BoxDecoration(
          color: StayTokens.paper,
          borderRadius: BorderRadius.circular(StayTokens.radiusCard),
          border: Border.all(color: StayTokens.line),
        ),
        clipBehavior: Clip.antiAlias,
        child: Row(
          children: [
            SizedBox(
              width: 112,
              height: 112,
              child: booking.displayImage.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: booking.displayImage,
                      fit: BoxFit.cover,
                      memCacheWidth: 300,
                      placeholder: (_, _) =>
                          Container(color: StayTokens.paperWarm),
                      errorWidget: (_, _, _) =>
                          Container(color: StayTokens.paperWarm),
                    )
                  : Container(color: StayTokens.paperWarm),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(StayTokens.s12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            booking.displayTitle,
                            style: StayTokens.body.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        _StatusPill(status: booking.bookingStatus),
                      ],
                    ),
                    const SizedBox(height: StayTokens.s4),
                    Text(dates, style: StayTokens.label),
                    const SizedBox(height: StayTokens.s4),
                    Text(
                      '${booking.guests} guests · ${booking.nights} nights',
                      style: StayTokens.label,
                    ),
                    const SizedBox(height: StayTokens.s4),
                    Text(
                      '₹${booking.totalAmount.toStringAsFixed(0)} total',
                      style: StayTokens.price,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.status});
  final String status;

  @override
  Widget build(BuildContext context) {
    final lower = status.toLowerCase();
    final Color bg;
    final Color fg;
    if (lower.contains('confirm')) {
      bg = const Color(0xFFD1FAE5);
      fg = const Color(0xFF064E3B);
    } else if (lower.contains('cancel')) {
      bg = const Color(0xFFFEE2E2);
      fg = const Color(0xFF7F1D1D);
    } else {
      bg = const Color(0xFFFEF3C7);
      fg = const Color(0xFF78350F);
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(StayTokens.radiusPill),
      ),
      child: Text(
        status,
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: fg),
      ),
    );
  }
}
