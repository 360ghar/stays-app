import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../controllers/auth/auth_controller.dart';
import '../../../controllers/booking/booking_controller.dart';
import '../../../controllers/trips_controller.dart';
import '../../../controllers/filter_controller.dart';
import '../../../data/models/property_model.dart';
import '../../../data/models/user_model.dart';
import '../../../routes/app_routes.dart';
import '../../../utils/helpers/currency_helper.dart';
import '../../../data/providers/bookings_provider.dart';
import '../../../data/repositories/booking_repository.dart';

class EnquiryView extends StatefulWidget {
  const EnquiryView({super.key});

  @override
  State<EnquiryView> createState() => _EnquiryViewState();
}

class _EnquiryViewState extends State<EnquiryView> {
  late final BookingController bookingController;
  TripsController? tripsController;
  AuthController? authController;

  Property? property;
  DateTime? checkInDate;
  DateTime? checkOutDate;
  int guests = 1;

  late final TextEditingController nameController;
  late final TextEditingController emailController;
  late final TextEditingController phoneController;

  final DateFormat _dateFormat = DateFormat('EEE, MMM d, yyyy');
  void _ensureDependencies() {
    final bookingsProvider =
        Get.isRegistered<BookingsProvider>()
            ? Get.find<BookingsProvider>()
            : Get.put(BookingsProvider(), permanent: true);

    final bookingRepository =
        Get.isRegistered<BookingRepository>()
            ? Get.find<BookingRepository>()
            : Get.put(
              BookingRepository(provider: bookingsProvider),
              permanent: true,
            );

    if (!Get.isRegistered<FilterController>()) {
      Get.put<FilterController>(FilterController(), permanent: true);
    }

    if (!Get.isRegistered<TripsController>()) {
      Get.lazyPut<TripsController>(() => TripsController(), fenix: true);
    }
    if (Get.isRegistered<TripsController>()) {
      Get.find<TripsController>();
    }

    if (!Get.isRegistered<BookingController>()) {
      Get.put<BookingController>(
        BookingController(repository: bookingRepository),
      );
    } else {
      Get.find<BookingController>();
    }
  }

  @override
  void initState() {
    super.initState();
    _ensureDependencies();
    bookingController = Get.find<BookingController>();
    if (Get.isRegistered<TripsController>()) {
      tripsController = Get.find<TripsController>();
    }
    if (Get.isRegistered<AuthController>()) {
      authController = Get.find<AuthController>();
    }

    final args = Get.arguments;
    Property? incomingProperty;
    DateTime? incomingCheckIn;
    DateTime? incomingCheckOut;
    int? incomingGuests;

    if (args is Property) {
      incomingProperty = args;
    } else if (args is Map) {
      final dynamic propertyArg = args['property'];
      if (propertyArg is Property) {
        incomingProperty = propertyArg;
      }
      final dynamic checkInArg = args['checkIn'];
      if (checkInArg is DateTime) {
        incomingCheckIn = checkInArg;
      } else if (checkInArg is String) {
        incomingCheckIn = DateTime.tryParse(checkInArg);
      }
      final dynamic checkOutArg = args['checkOut'];
      if (checkOutArg is DateTime) {
        incomingCheckOut = checkOutArg;
      } else if (checkOutArg is String) {
        incomingCheckOut = DateTime.tryParse(checkOutArg);
      }
      final dynamic guestsArg = args['guests'];
      if (guestsArg is int) {
        incomingGuests = guestsArg;
      }
    }

    if (incomingProperty != null) {
      property = incomingProperty;
      final maxGuests = incomingProperty.maxGuests;
      if (incomingGuests == null && maxGuests != null && maxGuests > 0) {
        incomingGuests = maxGuests.clamp(1, 6).toInt();
      }
    }

    final now = DateTime.now();
    checkInDate = incomingCheckIn ?? now.add(const Duration(days: 1));
    checkOutDate = incomingCheckOut ?? now.add(const Duration(days: 3));
    if (incomingGuests != null && incomingGuests > 0) {
      final maxAllowed = property?.maxGuests;
      if (maxAllowed != null && maxAllowed > 0) {
        guests = incomingGuests.clamp(1, maxAllowed).toInt();
      } else {
        guests = incomingGuests;
      }
    }

    final user = authController?.currentUser.value;
    final resolvedName = _resolveUserName(user);
    nameController = TextEditingController(text: resolvedName);
    emailController = TextEditingController(text: user?.email ?? '');
    phoneController = TextEditingController(text: user?.phone ?? '');
  }

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    super.dispose();
  }

  String _resolveUserName(UserModel? user) {
    final parts = <String>[];
    final first = user?.firstName?.trim();
    final last = user?.lastName?.trim();
    if (first != null && first.isNotEmpty) {
      parts.add(first);
    }
    if (last != null && last.isNotEmpty) {
      parts.add(last);
    }
    if (parts.isNotEmpty) {
      return parts.join(' ');
    }
    final name = user?.name?.trim();
    if (name != null && name.isNotEmpty) {
      return name;
    }
    final email = user?.email;
    if (email != null && email.isNotEmpty) {
      final at = email.indexOf('@');
      return at > 0 ? email.substring(0, at) : email;
    }
    return '';
  }

  Future<void> _pickDates() async {
    final start = checkInDate ?? DateTime.now().add(const Duration(days: 1));
    final end = checkOutDate ?? start.add(const Duration(days: 2));
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDateRange: DateTimeRange(start: start, end: end),
    );
    if (picked != null) {
      setState(() {
        checkInDate = picked.start;
        checkOutDate = picked.end;
      });
    }
  }

  int get nights {
    if (checkInDate == null || checkOutDate == null) return 0;
    return checkOutDate!.difference(checkInDate!).inDays.clamp(1, 365);
  }

  double get nightlyRate {
    return property?.pricePerNight ?? 0;
  }

  double get baseAmount {
    return nightlyRate * nights;
  }

  double get serviceCharges {
    return baseAmount * 0.10; // 10% service charge
  }

  double get taxesAmount {
    return baseAmount * 0.05; // 5% tax
  }

  double get discountAmount {
    return 0.0; // No discount
  }

  double get estimatedTotal {
    return baseAmount + serviceCharges + taxesAmount - discountAmount;
  }

  Future<void> _submitEnquiry() async {
    if (bookingController.isSubmitting.value) return;
    if (property == null) {
      Get.snackbar('Missing property', 'Unable to identify this listing.');
      return;
    }
    if (checkInDate == null || checkOutDate == null || nights <= 0) {
      Get.snackbar(
        'Select dates',
        'Please choose valid check-in and check-out dates.',
      );
      return;
    }
    if (guests <= 0) {
      Get.snackbar('Guests', 'Please select at least one guest.');
      return;
    }
    if (nameController.text.trim().isEmpty) {
      Get.snackbar('Guest name', 'Please provide the primary guest name.');
      return;
    }

    final trimmedEmail = emailController.text.trim();
    final checkInIso = checkInDate!.toIso8601String();
    final checkOutIso = checkOutDate!.toIso8601String();

    final localBaseAmount = baseAmount;
    final localTaxesAmount = taxesAmount;
    final localServiceCharges = serviceCharges;
    final localDiscountAmount = discountAmount;
    final localTotalAmount = estimatedTotal;

    final fallbackPricing = <String, num>{
      'base_amount': localBaseAmount,
      'taxes_amount': localTaxesAmount,
      'service_charges': localServiceCharges,
      'discount_amount': localDiscountAmount,
      'total_amount': localTotalAmount,
    };

    await bookingController.createBookingWithoutPayment(
      propertyId: property!.id,
      checkInIso: checkInIso,
      checkOutIso: checkOutIso,
      guests: guests,
      primaryGuestName: nameController.text.trim(),
      primaryGuestPhone: phoneController.text.trim(),
      primaryGuestEmail: trimmedEmail.isEmpty ? null : trimmedEmail,
      nights: nights,
      fallbackPricing: fallbackPricing,
      additionalPayload: {
        'property_title': property!.name,
        'property_city': property!.city,
        'property_country': property!.country,
        'property_image_url': property!.displayImage ?? '',
      },
    );

    final latestBooking = bookingController.latestBooking.value;
    final status = bookingController.statusMessage.value;
    final isSuccessful =
        latestBooking != null && !status.toLowerCase().contains('failed');

    if (isSuccessful && latestBooking != null) {
      if (tripsController != null) {
        await tripsController!.loadPastBookings(forceRefresh: true);
      }
      Get.snackbar(
        'Enquiry Sent Successfully',
        'We have recorded your enquiry for ${property!.name}.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green[100],
        colorText: Colors.green[800],
      );
      Get.offAllNamed(Routes.home, arguments: 0);
    } else {
      final rawError = bookingController.errorMessage.value;
      final errorMessage =
          rawError.isNotEmpty ? rawError : 'Failed to send enquiry. Please try again.';
      final truncatedError =
          errorMessage.length > 100 ? '${errorMessage.substring(0, 97)}...' : errorMessage;
      Get.snackbar(
        'Enquiry failed',
        truncatedError,
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final prop = property;
    const buttonLabel = 'Send Enquiry';
    return Scaffold(
      appBar: AppBar(title: Text(prop?.name ?? 'Send enquiry')),
      body:
          prop == null
              ? const Center(child: Text('Property details unavailable'))
              : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _buildPropertyHeader(prop),
                  const SizedBox(height: 16),
                  _buildStayDetailsCard(prop),
                  const SizedBox(height: 16),
                  _buildContactCard(),
                  const SizedBox(height: 16),
                  _buildPriceSummaryCard(prop),
                  const SizedBox(height: 24),
                ],
              ),
      bottomNavigationBar:
          prop == null
              ? null
              : SafeArea(
                minimum: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                child: Obx(() {
                  final isLoading = bookingController.isSubmitting.value;
                  final message = bookingController.statusMessage.value;
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (isLoading && message.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Text(
                            message,
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: isLoading ? null : _submitEnquiry,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child:
                              isLoading
                                  ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                  : Text(buttonLabel),
                        ),
                      ),
                    ],
                  );
                }),
              ),
    );
  }

  Widget _buildPropertyHeader(Property prop) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final width = MediaQuery.of(context).size.width;
    final double horizontalPadding = width >= 480 ? 18 : 12;
    final double maxCardWidth = width >= 960 ? 320 : width >= 720 ? 300 : 260;
    final double cardWidth = math.max(
      200,
      math.min(maxCardWidth, width - (horizontalPadding * 2)),
    );
    final imageUrl = prop.displayImage;
    final locationLabel = [
      if (prop.city.trim().isNotEmpty) prop.city.trim(),
      if (prop.country.trim().isNotEmpty) prop.country.trim(),
    ].join(', ');
    final rating = prop.rating;
    final reviews = prop.reviewsCount;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        horizontalPadding,
        0,
        horizontalPadding,
        20,
      ),
      child: Center(
        child: Material(
          color: colors.surface,
          elevation: theme.brightness == Brightness.dark ? 1 : 2,
          shadowColor: Colors.black.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => Get.toNamed(
              Routes.listingDetail.replaceFirst(
                ':id',
                prop.id.toString(),
              ),
              arguments: prop,
            ),
            child: SizedBox(
              width: cardWidth,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: SizedBox(
                        width: 72,
                        height: 72,
                        child: imageUrl != null && imageUrl.isNotEmpty
                            ? Image.network(
                                imageUrl,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) =>
                                    _buildPropertyImageFallback(colors),
                              )
                            : _buildPropertyImageFallback(colors),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            prop.name,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: colors.onSurface,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.location_on_outlined,
                                size: 16,
                                color: colors.primary,
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  locationLabel,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: colors.onSurfaceVariant,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${CurrencyHelper.format(prop.pricePerNight)} / night',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: colors.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (rating != null) ...[
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                const Icon(
                                  Icons.star_rate_rounded,
                                  size: 14,
                                  color: Colors.amber,
                                ),
                                Text(
                                  rating.toStringAsFixed(1),
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: colors.onSurface,
                                  ),
                                ),
                                if (reviews != null && reviews > 0) ...[
                                  const SizedBox(width: 6),
                                  Text(
                                    '($reviews reviews)',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: colors.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 16,
                      color: colors.onSurfaceVariant,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPropertyImageFallback(ColorScheme colors) {
    return Container(
      color: colors.surfaceContainerHighest,
      alignment: Alignment.center,
      child: Icon(
        Icons.hotel,
        size: 24,
        color: colors.onSurfaceVariant.withValues(alpha: 0.65),
      ),
    );
  }

  Widget _buildStayDetailsCard(Property prop) {
    final maxGuests = prop.maxGuests ?? 6;
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Stay details',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildDateTile('Check-in', checkInDate),
                  const Divider(height: 1),
                  _buildDateTile('Check-out', checkOutDate),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Guests',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      'Up to $maxGuests guests',
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                  ],
                ),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.remove_circle_outline),
                      onPressed:
                          guests > 1 ? () => setState(() => guests--) : null,
                    ),
                    Text(
                      '$guests',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add_circle_outline),
                      onPressed:
                          guests < maxGuests
                              ? () => setState(() => guests++)
                              : null,
                    ),
                  ],
                ),
              ],
            ),
            if (nights > 0) ...[
              const SizedBox(height: 12),
              Text(
                '$nights night${nights == 1 ? '' : 's'} selected',
                style: TextStyle(color: Colors.grey.shade600),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDateTile(String label, DateTime? value) {
    return ListTile(
      onTap: _pickDates,
      title: Text(label),
      trailing: Text(
        value != null ? _dateFormat.format(value) : 'Select',
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget _buildContactCard() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Primary guest details',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Full name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: phoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Phone',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'Email (optional)',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPriceSummaryCard(Property prop) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Price summary',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            if (nights > 0) ...[
              _buildPriceRow(
                '${CurrencyHelper.format(nightlyRate)} x $nights night${nights == 1 ? '' : 's'}',
                CurrencyHelper.format(baseAmount),
              ),
              const SizedBox(height: 8),
              _buildPriceRow(
                'Service charges (10%)',
                CurrencyHelper.format(serviceCharges),
              ),
              const SizedBox(height: 8),
              _buildPriceRow('Taxes (5%)', CurrencyHelper.format(taxesAmount)),
              if (discountAmount > 0) ...[
                const SizedBox(height: 8),
                _buildPriceRow(
                  'Discount',
                  '-${CurrencyHelper.format(discountAmount)}',
                ),
              ],
              const SizedBox(height: 8),
              _buildPriceRow('Guests', '$guests'),
              const Divider(height: 24),
              _buildPriceRow(
                'Total due',
                CurrencyHelper.format(estimatedTotal),
                isTotal: true,
              ),
            ] else ...[
              _buildPriceRow(
                '${CurrencyHelper.format(nightlyRate)} per night',
                '--',
              ),
              const SizedBox(height: 8),
              _buildPriceRow('Guests', '$guests'),
              const Divider(height: 24),
              _buildPriceRow('Total due', '--', isTotal: true),
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'Select valid dates to see the total.',
                  style: TextStyle(color: Colors.grey.shade600),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPriceRow(String label, String value, {bool isTotal = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isTotal ? 16 : 14,
            fontWeight: isTotal ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: isTotal ? 16 : 14,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}
