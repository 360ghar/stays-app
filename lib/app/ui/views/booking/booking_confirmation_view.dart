import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../controllers/booking/booking_confirmation_controller.dart';
import '../../../data/models/property_model.dart';
import '../../../utils/helpers/currency_helper.dart';

class BookingConfirmationView extends GetView<BookingConfirmationController> {
  const BookingConfirmationView({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textStyles = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Confirm Your Booking')),
      body: Obx(() {
        final property = controller.property.value;
        if (property == null) {
          return const Center(
            child: Text('We could not load the selected property.'),
          );
        }

        final quote = _QuoteBreakdown.fromProperty(property);

        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildPropertySummary(property, colors, textStyles),
              const SizedBox(height: 24),
              _buildBookingDetails(property, quote, colors, textStyles),
              const SizedBox(height: 24),
              _buildPriceBreakdown(quote, colors, textStyles),
            ],
          ),
        );
      }),
      bottomNavigationBar: Obx(() {
        final property = controller.property.value;
        final quote =
            property != null ? _QuoteBreakdown.fromProperty(property) : null;
        return SafeArea(
          minimum: const EdgeInsets.all(24),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed:
                  property == null
                      ? null
                      : () => controller.confirmBookingAndPay(),
              child: Text(
                quote == null
                    ? 'Confirm & Pay'
                    : 'Confirm & Pay ${CurrencyHelper.format(quote.total)}',
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildPropertySummary(
    Property property,
    ColorScheme colors,
    TextTheme textStyles,
  ) {
    final imageUrl = property.displayImage;
    final location =
        property.fullAddress.isNotEmpty
            ? property.fullAddress
            : '${property.city}, ${property.country}';

    return Card(
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (imageUrl != null && imageUrl.isNotEmpty)
            AspectRatio(
              aspectRatio: 4 / 3,
              child: Image.network(
                imageUrl,
                fit: BoxFit.cover,
                errorBuilder:
                    (_, __, ___) => Container(
                      color: colors.surfaceContainerHighest,
                      alignment: Alignment.center,
                      child: Icon(
                        Icons.image_not_supported_outlined,
                        color: colors.onSurfaceVariant,
                      ),
                    ),
              ),
            )
          else
            Container(
              height: 200,
              width: double.infinity,
              color: colors.surfaceContainerHighest,
              alignment: Alignment.center,
              child: Icon(
                Icons.image_outlined,
                size: 48,
                color: colors.onSurfaceVariant,
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  property.name,
                  style: textStyles.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: colors.onSurface,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.location_on_outlined,
                      size: 18,
                      color: colors.primary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        location,
                        style: textStyles.bodyMedium?.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
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

  Widget _buildBookingDetails(
    Property property,
    _QuoteBreakdown quote,
    ColorScheme colors,
    TextTheme textStyles,
  ) {
    final formatter = DateFormat('EEE, MMM d');
    final checkInLabel = formatter.format(quote.checkIn);
    final checkOutLabel = formatter.format(quote.checkOut);
    final guests = property.maxGuests ?? 1;

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Your stay',
              style: textStyles.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: colors.onSurface,
              ),
            ),
            const SizedBox(height: 16),
            _buildDetailRow(
              icon: Icons.calendar_today,
              label: 'Check-in',
              value: checkInLabel,
              colors: colors,
              textStyles: textStyles,
            ),
            const SizedBox(height: 12),
            _buildDetailRow(
              icon: Icons.calendar_month,
              label: 'Check-out',
              value: checkOutLabel,
              colors: colors,
              textStyles: textStyles,
            ),
            const SizedBox(height: 12),
            _buildDetailRow(
              icon: Icons.nights_stay_outlined,
              label: 'Nights',
              value: '${quote.nights} night${quote.nights == 1 ? '' : 's'}',
              colors: colors,
              textStyles: textStyles,
            ),
            const SizedBox(height: 12),
            _buildDetailRow(
              icon: Icons.group_outlined,
              label: 'Guests',
              value: '$guests guest${guests == 1 ? '' : 's'}',
              colors: colors,
              textStyles: textStyles,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPriceBreakdown(
    _QuoteBreakdown quote,
    ColorScheme colors,
    TextTheme textStyles,
  ) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Price breakdown',
              style: textStyles.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: colors.onSurface,
              ),
            ),
            const SizedBox(height: 16),
            _buildPriceRow(
              '${CurrencyHelper.format(quote.nightlyRate)} x ${quote.nights} night${quote.nights == 1 ? '' : 's'}',
              CurrencyHelper.format(quote.base),
              textStyles,
              colors,
            ),
            const SizedBox(height: 12),
            _buildPriceRow(
              'Service fee (10%)',
              CurrencyHelper.format(quote.fees),
              textStyles,
              colors,
            ),
            const SizedBox(height: 12),
            _buildPriceRow(
              'Taxes (5%)',
              CurrencyHelper.format(quote.taxes),
              textStyles,
              colors,
            ),
            const Divider(height: 32),
            _buildPriceRow(
              'Total',
              CurrencyHelper.format(quote.total),
              textStyles,
              colors,
              emphasize: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
    required ColorScheme colors,
    required TextTheme textStyles,
  }) {
    return Row(
      children: [
        Container(
          height: 40,
          width: 40,
          decoration: BoxDecoration(
            color: colors.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: colors.primary),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: textStyles.bodySmall?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: textStyles.bodyLarge?.copyWith(
                  color: colors.onSurface,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPriceRow(
    String label,
    String value,
    TextTheme textStyles,
    ColorScheme colors, {
    bool emphasize = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: (emphasize ? textStyles.titleMedium : textStyles.bodyMedium)
              ?.copyWith(
                color: colors.onSurface,
                fontWeight: emphasize ? FontWeight.w600 : FontWeight.w400,
              ),
        ),
        Text(
          value,
          style: (emphasize ? textStyles.titleMedium : textStyles.bodyMedium)
              ?.copyWith(color: colors.onSurface, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}

class _QuoteBreakdown {
  _QuoteBreakdown({
    required this.checkIn,
    required this.checkOut,
    required this.nights,
    required this.nightlyRate,
    required this.base,
    required this.fees,
    required this.taxes,
    required this.total,
  });

  final DateTime checkIn;
  final DateTime checkOut;
  final int nights;
  final double nightlyRate;
  final double base;
  final double fees;
  final double taxes;
  final double total;

  factory _QuoteBreakdown.fromProperty(Property property) {
    final checkIn = DateTime.now().add(const Duration(days: 7));
    final checkOut = checkIn.add(const Duration(days: 3));
    var nights = checkOut.difference(checkIn).inDays;
    if (nights <= 0) {
      nights = 1;
    }
    final nightlyRate = property.pricePerNight;
    final base = nightlyRate * nights;
    final fees = base * 0.10;
    final taxes = base * 0.05;
    final total = base + fees + taxes;
    return _QuoteBreakdown(
      checkIn: checkIn,
      checkOut: checkOut,
      nights: nights,
      nightlyRate: nightlyRate,
      base: base,
      fees: fees,
      taxes: taxes,
      total: total,
    );
  }
}
