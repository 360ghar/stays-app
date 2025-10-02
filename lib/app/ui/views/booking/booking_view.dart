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

class BookingView extends StatefulWidget {
  const BookingView({super.key});

  @override
  State<BookingView> createState() => _BookingViewState();
}

class _BookingViewState extends State<BookingView> {
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
    if (args is Property) {
      property = args;
      final maxGuests = args.maxGuests;
      if (maxGuests != null && maxGuests > 0) {
        guests = maxGuests.clamp(1, 6).toInt();
      }
    }

    final now = DateTime.now();
    checkInDate = now.add(const Duration(days: 1));
    checkOutDate = now.add(const Duration(days: 3));

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

  Future<void> _submitBooking() async {
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
    var resolvedBooking = latestBooking;
    var isSuccessful =
        resolvedBooking != null && !status.toLowerCase().contains('failed');
    var isSimulated = false;

    if (!isSuccessful && tripsController != null) {
      final user = authController?.currentUser.value;
      final simulatedBooking = tripsController!.simulateAddBooking(
        propertyId: property!.id,
        propertyName: property!.name,
        imageUrl: property!.displayImage ?? '',
        address: property!.fullAddress,
        city: property!.city,
        country: property!.country,
        checkIn: checkInDate!,
        checkOut: checkOutDate!,
        guests: guests,
        rooms: property!.bedrooms ?? 1,
        totalAmount: localTotalAmount,
        nights: nights,
        userId: user != null ? int.tryParse(user.id) : null,
        notifyUser: false,
      );
      bookingController.latestBooking.value = simulatedBooking;
      bookingController.statusMessage.value = 'Booking created (simulated)';
      bookingController.errorMessage.value = '';
      resolvedBooking = simulatedBooking;
      isSuccessful = true;
      isSimulated = true;
    }

    if (isSuccessful && resolvedBooking != null) {
      if (tripsController != null && !isSimulated) {
        tripsController!.addOrUpdateBooking(resolvedBooking);
      }
      Get.snackbar(
        'Booking confirmed!',
        'Your stay at ${property!.name} is confirmed${isSimulated ? ' (simulated).' : '.'}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green[100],
        colorText: Colors.green[800],
      );
      Get.offAllNamed(Routes.home, arguments: 0);
    } else {
      final error =
          bookingController.errorMessage.value.isNotEmpty
              ? bookingController.errorMessage.value
              : 'Failed to create booking. Please try again.';
      final truncatedError =
          error.length > 100 ? '${error.substring(0, 97)}...' : error;
      Get.snackbar(
        'Booking failed',
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
    final buttonLabel =
        nights > 0
            ? 'Pay & Confirm ${CurrencyHelper.format(estimatedTotal)}'
            : 'Pay & Confirm';
    return Scaffold(
      appBar: AppBar(title: Text(prop?.name ?? 'Confirm booking')),
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
                          onPressed: isLoading ? null : _submitBooking,
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
    final rating = prop.rating;
    final reviews = prop.reviewsCount;
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (prop.displayImage?.isNotEmpty == true)
            AspectRatio(
              aspectRatio: 16 / 9,
              child: Image.network(prop.displayImage!, fit: BoxFit.cover),
            )
          else
            Container(
              height: 180,
              color: Colors.grey.shade200,
              alignment: Alignment.center,
              child: const Icon(Icons.image, size: 48, color: Colors.grey),
            ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  prop.name,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${prop.city}, ${prop.country}',
                  style: TextStyle(color: Colors.grey.shade600),
                ),
                if (rating != null || (reviews ?? 0) > 0) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(Icons.star_rate_rounded, size: 18),
                      const SizedBox(width: 4),
                      Text(rating != null ? rating.toStringAsFixed(1) : 'New'),
                      if (reviews != null && reviews > 0) ...[
                        const SizedBox(width: 6),
                        Text('($reviews)'),
                      ],
                    ],
                  ),
                ],
                const SizedBox(height: 12),
                Text(
                  '${CurrencyHelper.format(prop.pricePerNight)} per night',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
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
