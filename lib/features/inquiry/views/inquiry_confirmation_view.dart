import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import 'package:stays_app/features/inquiry/controllers/inquiry_confirmation_controller.dart';
import 'package:stays_app/app/data/models/booking_model.dart';
import 'package:stays_app/app/data/models/property_model.dart';
import 'package:stays_app/app/routes/app_routes.dart';
import 'package:stays_app/app/utils/helpers/app_snackbar.dart';
import 'package:stays_app/app/utils/helpers/currency_helper.dart';

class InquiryConfirmationView extends GetView<InquiryConfirmationController> {
  const InquiryConfirmationView({super.key});

  static final DateFormat _dateFormat = DateFormat('EEE, MMM d');

  @override
  Widget build(BuildContext context) {
    // Post-submission success mode (F18/R18): when the route is opened with
    // the created Booking (or a map containing one) render the confirmation
    // summary instead of the pre-submission Property editor.
    final args = Get.arguments;
    if (args is Booking) {
      return _buildBookingConfirmation(context, args);
    }
    if (args is Map<String, dynamic> && args['booking'] is Booking) {
      return _buildBookingConfirmation(context, args['booking'] as Booking);
    }

    final colors = Theme.of(context).colorScheme;
    final textStyles = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Send Your Inquiry')),
      body: Obx(() {
        final property = controller.property.value;
        if (property == null) {
          return const Center(
            child: Text('We could not load the selected property.'),
          );
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildPropertySummary(property, colors, textStyles),
              const SizedBox(height: 24),
              _buildStayEditor(context, colors, textStyles),
              const SizedBox(height: 24),
              _buildPriceBreakdown(colors, textStyles),
            ],
          ),
        );
      }),
      bottomNavigationBar: Obx(() {
        final property = controller.property.value;
        return SafeArea(
          minimum: const EdgeInsets.all(24),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: property == null
                  ? null
                  : () => controller.submitInquiry(),
              child: const Text('Send Inquiry'),
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
    final location = property.fullAddress.isNotEmpty
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
                errorBuilder: (_, _, _) => Container(
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

  Widget _buildStayEditor(
    BuildContext context,
    ColorScheme colors,
    TextTheme textStyles,
  ) {
    return Obx(() {
      final checkIn = controller.checkInDate.value;
      final checkOut = controller.checkOutDate.value;
      final nightCount = controller.nights.value;
      final guestCount = controller.guests.value;
      final minStay = controller.minimumStay;
      final maxGuests = controller.maxGuests;
      final nightsHelper = minStay > 1
          ? 'Minimum stay: $minStay night${minStay == 1 ? '' : 's'}'
          : null;
      final guestsHelper = 'Up to $maxGuests guest${maxGuests == 1 ? '' : 's'}';

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
              _editableDateTile(
                context: context,
                icon: Icons.calendar_today,
                label: 'Check-in',
                value: _dateFormat.format(checkIn),
                onTap: () => _pickCheckInDate(context),
                colors: colors,
                textStyles: textStyles,
              ),
              const SizedBox(height: 12),
              _editableDateTile(
                context: context,
                icon: Icons.calendar_month,
                label: 'Check-out',
                value: _dateFormat.format(checkOut),
                onTap: () => _pickCheckOutDate(context),
                colors: colors,
                textStyles: textStyles,
              ),
              const SizedBox(height: 12),
              _counterRow(
                icon: Icons.nights_stay_outlined,
                label: 'Nights',
                value: '$nightCount',
                helperText: nightsHelper,
                canDecrement: controller.canDecrementNights,
                canIncrement: controller.canIncrementNights,
                onDecrement: controller.decrementNights,
                onIncrement: controller.incrementNights,
                colors: colors,
                textStyles: textStyles,
              ),
              const SizedBox(height: 12),
              _counterRow(
                icon: Icons.group_outlined,
                label: 'Guests',
                value: '$guestCount',
                helperText: guestsHelper,
                canDecrement: controller.canDecrementGuests,
                canIncrement: controller.canIncrementGuests,
                onDecrement: controller.decrementGuests,
                onIncrement: controller.incrementGuests,
                colors: colors,
                textStyles: textStyles,
              ),
            ],
          ),
        ),
      );
    });
  }

  Widget _editableDateTile({
    required BuildContext context,
    required IconData icon,
    required String label,
    required String value,
    required VoidCallback onTap,
    required ColorScheme colors,
    required TextTheme textStyles,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Container(
              height: 44,
              width: 44,
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
            const Icon(Icons.edit_outlined, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _counterRow({
    required IconData icon,
    required String label,
    required String value,
    required bool canDecrement,
    required bool canIncrement,
    required VoidCallback onDecrement,
    required VoidCallback onIncrement,
    required ColorScheme colors,
    required TextTheme textStyles,
    String? helperText,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              height: 44,
              width: 44,
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
                  if (helperText != null) ...[
                    const SizedBox(height: 6),
                    Text(
                      helperText,
                      style: textStyles.bodySmall?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.remove_circle_outline),
                  onPressed: canDecrement ? onDecrement : null,
                ),
                Text(
                  value,
                  style: textStyles.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: colors.onSurface,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add_circle_outline),
                  onPressed: canIncrement ? onIncrement : null,
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPriceBreakdown(ColorScheme colors, TextTheme textStyles) {
    return Obx(() {
      final nights = controller.nights.value;
      final nightlyRate = controller.nightlyRate;
      final base = controller.baseAmount;
      final fees = controller.serviceFee;
      final taxes = controller.taxes;
      final total = controller.totalAmount;

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
                '${CurrencyHelper.format(nightlyRate)} x $nights night${nights == 1 ? '' : 's'}',
                CurrencyHelper.format(base),
                textStyles,
                colors,
              ),
              const SizedBox(height: 12),
              _buildPriceRow(
                'Service fee (10%)',
                CurrencyHelper.format(fees),
                textStyles,
                colors,
              ),
              const SizedBox(height: 12),
              _buildPriceRow(
                'Taxes (5%)',
                CurrencyHelper.format(taxes),
                textStyles,
                colors,
              ),
              const Divider(height: 32),
              _buildPriceRow(
                'Total',
                CurrencyHelper.format(total),
                textStyles,
                colors,
                emphasize: true,
              ),
            ],
          ),
        ),
      );
    });
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

  Future<void> _pickCheckInDate(BuildContext context) async {
    final firstDate = controller.minSelectableDate;
    final rawLastDate = controller.maxSelectableDate.subtract(
      Duration(days: controller.minimumStay),
    );
    final lastDate = rawLastDate.isBefore(firstDate) ? firstDate : rawLastDate;
    var initialDate = controller.checkInDate.value;
    if (initialDate.isBefore(firstDate)) {
      initialDate = firstDate;
    } else if (initialDate.isAfter(lastDate)) {
      initialDate = lastDate;
    }

    final picked = await showDatePicker(
      context: context,
      firstDate: firstDate,
      lastDate: lastDate,
      initialDate: initialDate,
      helpText: 'Select check-in date',
    );
    if (picked != null) {
      controller.setCheckInDate(picked);
    }
  }

  Future<void> _pickCheckOutDate(BuildContext context) async {
    final earliestCheckout = controller.checkInDate.value.add(
      Duration(days: controller.minimumStay),
    );
    final firstDate = earliestCheckout.isAfter(controller.maxSelectableDate)
        ? controller.maxSelectableDate
        : earliestCheckout;
    final lastDate = controller.maxSelectableDate;
    if (firstDate.isAfter(lastDate)) {
      AppSnackbar.warning(
        title: 'Unavailable',
        message: 'Please choose an earlier check-in date to extend your stay.',
      );
      return;
    }
    var initialDate = controller.checkOutDate.value;
    if (initialDate.isBefore(firstDate)) {
      initialDate = firstDate;
    } else if (initialDate.isAfter(lastDate)) {
      initialDate = lastDate;
    }

    final picked = await showDatePicker(
      context: context,
      firstDate: firstDate,
      lastDate: lastDate,
      initialDate: initialDate,
      helpText: 'Select check-out date',
    );
    if (picked != null) {
      controller.setCheckOutDate(picked);
    }
  }

  // --- Post-submission confirmation (F18/R18) ---

  Widget _buildBookingConfirmation(BuildContext context, Booking booking) {
    final colors = Theme.of(context).colorScheme;
    final textStyles = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Inquiry Sent')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSuccessHeader(booking, colors, textStyles),
            const SizedBox(height: 24),
            _buildBookingSummary(booking, colors, textStyles),
            const SizedBox(height: 24),
            _buildBookingTotal(booking, colors, textStyles),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.all(24),
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () => Get.offAllNamed(Routes.home, arguments: 0),
            child: const Text('Back to Home'),
          ),
        ),
      ),
    );
  }

  Widget _buildSuccessHeader(
    Booking booking,
    ColorScheme colors,
    TextTheme textStyles,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colors.primaryContainer.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Icon(Icons.check_circle_rounded, size: 52, color: colors.primary),
          const SizedBox(height: 12),
          Text(
            'Your inquiry has been sent!',
            style: textStyles.titleLarge?.copyWith(
              color: colors.onSurface,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Reference: ${booking.bookingReference}',
            style: textStyles.bodyMedium?.copyWith(
              color: colors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBookingSummary(
    Booking booking,
    ColorScheme colors,
    TextTheme textStyles,
  ) {
    final property = booking.property;
    final imageUrl = property?.displayImage ?? booking.propertyImageUrl ?? '';
    final location = booking.displayLocation.isNotEmpty
        ? booking.displayLocation
        : (property?.fullAddress ?? '');

    return Card(
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (imageUrl.isNotEmpty)
            AspectRatio(
              aspectRatio: 4 / 3,
              child: Image.network(
                imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => Container(
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
              height: 140,
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
                  booking.displayTitle,
                  style: textStyles.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: colors.onSurface,
                  ),
                ),
                if (location.isNotEmpty) ...[
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
                const SizedBox(height: 16),
                _buildDetailRow(
                  Icons.calendar_today_outlined,
                  'Check-in',
                  _dateFormat.format(booking.checkInDate),
                  colors,
                  textStyles,
                ),
                const SizedBox(height: 10),
                _buildDetailRow(
                  Icons.calendar_month_outlined,
                  'Check-out',
                  _dateFormat.format(booking.checkOutDate),
                  colors,
                  textStyles,
                ),
                const SizedBox(height: 10),
                _buildDetailRow(
                  Icons.nights_stay_outlined,
                  'Nights',
                  '${booking.nights}',
                  colors,
                  textStyles,
                ),
                const SizedBox(height: 10),
                _buildDetailRow(
                  Icons.people_outline,
                  'Guests',
                  '${booking.guests}',
                  colors,
                  textStyles,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(
    IconData icon,
    String label,
    String value,
    ColorScheme colors,
    TextTheme textStyles,
  ) {
    return Row(
      children: [
        Icon(icon, size: 18, color: colors.onSurfaceVariant),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            label,
            style: textStyles.bodyMedium?.copyWith(
              color: colors.onSurfaceVariant,
            ),
          ),
        ),
        Text(
          value,
          style: textStyles.bodyMedium?.copyWith(
            color: colors.onSurface,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildBookingTotal(
    Booking booking,
    ColorScheme colors,
    TextTheme textStyles,
  ) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _buildPriceRow(
              'Total amount',
              CurrencyHelper.format(booking.totalAmount),
              textStyles,
              colors,
              emphasize: true,
            ),
            const Divider(height: 24),
            _buildPriceRow(
              'Status',
              '${booking.bookingStatus} · ${booking.paymentStatus}',
              textStyles,
              colors,
            ),
          ],
        ),
      ),
    );
  }
}
