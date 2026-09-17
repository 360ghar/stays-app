import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import 'package:stays_app/app/data/models/booking_model.dart';
import 'package:stays_app/core/router/app_router.dart';
import 'package:stays_app/core/theme/tokens.dart';

/// V2 inquiry confirmation. Reference, dates, total, next steps.
class InquiryConfirmationScreen extends StatelessWidget {
  const InquiryConfirmationScreen({required this.booking, super.key});
  final Booking booking;

  @override
  Widget build(BuildContext context) {
    final dates =
        '${DateFormat.MMMd().format(booking.checkInDate)} – '
        '${DateFormat.MMMd().format(booking.checkOutDate)}';
    return Scaffold(
      backgroundColor: StayTokens.paper,
      appBar: AppBar(automaticallyImplyLeading: false),
      body: ListView(
        padding: const EdgeInsets.all(StayTokens.s24),
        children: [
          const Icon(
            Icons.check_circle,
            size: 72,
            color: StayTokens.accentDark,
          ),
          const SizedBox(height: StayTokens.s16),
          const Text(
            'Inquiry sent!',
            style: StayTokens.titleLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: StayTokens.s8),
          const Text(
            'The host will confirm shortly. Track status in Trips.',
            style: StayTokens.bodySecondary,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: StayTokens.s24),
          Container(
            padding: const EdgeInsets.all(StayTokens.s16),
            decoration: BoxDecoration(
              color: StayTokens.paperWarm,
              borderRadius: BorderRadius.circular(StayTokens.radiusCard),
              border: Border.all(color: StayTokens.line),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(booking.displayTitle, style: StayTokens.title),
                const SizedBox(height: StayTokens.s4),
                Text(dates, style: StayTokens.bodySecondary),
                Text(
                  '${booking.guests} guests · ${booking.nights} nights',
                  style: StayTokens.bodySecondary,
                ),
                const Divider(),
                Row(
                  children: [
                    const Text('Reference', style: StayTokens.label),
                    const Spacer(),
                    Text(
                      booking.bookingReference,
                      style: StayTokens.body.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: StayTokens.s4),
                Row(
                  children: [
                    const Text('Total', style: StayTokens.price),
                    const Spacer(),
                    Text(
                      '₹${booking.totalAmount.toStringAsFixed(0)}',
                      style: StayTokens.price,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: StayTokens.s24),
          FilledButton(
            onPressed: () => context.go(AppPaths.trips),
            child: const Text('View my trips'),
          ),
          const SizedBox(height: StayTokens.s12),
          OutlinedButton(
            onPressed: () => context.go(AppPaths.explore),
            child: const Text('Keep exploring'),
          ),
        ],
      ),
    );
  }
}
