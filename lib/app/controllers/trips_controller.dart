import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../data/models/unified_filter_model.dart';
import '../data/models/booking_model.dart';
import '../data/models/property_model.dart';
import '../data/repositories/booking_repository.dart';
import 'filter_controller.dart';

class TripsController extends GetxController {
  final RxList<Map<String, dynamic>> pastBookings =
      <Map<String, dynamic>>[].obs;
  final RxBool isLoading = false.obs;

  late final BookingRepository _bookingRepository;
  FilterController? _filterController;

  final List<Map<String, dynamic>> _allBookings = [];
  UnifiedFilterModel _activeFilters = UnifiedFilterModel.empty;
  Worker? _filterWorker;

  @override
  void onInit() {
    super.onInit();
    _bookingRepository = Get.find<BookingRepository>();
    _initializeFilterSync();
    loadPastBookings();
  }

  void _initializeFilterSync() {
    if (!Get.isRegistered<FilterController>()) return;
    _filterController = Get.find<FilterController>();
    _activeFilters = _filterController!.filterFor(FilterScope.booking);
    _filterWorker = debounce<UnifiedFilterModel>(
      _filterController!.rxFor(FilterScope.booking),
      (filters) {
        if (_activeFilters == filters) return;
        _activeFilters = filters;
        _applyFilters();
      },
      time: const Duration(milliseconds: 120),
    );
  }

  @override
  void onClose() {
    _filterWorker?.dispose();
    super.onClose();
  }

  Future<void> loadPastBookings({bool forceRefresh = false}) async {
    if (!forceRefresh && _allBookings.isNotEmpty) {
      _applyFilters();
      return;
    }
    final hadBookings = _allBookings.isNotEmpty;
    if (isLoading.value && !forceRefresh) {
      return;
    }
    try {
      isLoading.value = true;
      final bookings = await _bookingRepository.fetchBookings();
      final mapped = bookings.map(_mapBooking).toList();
      _allBookings
        ..clear()
        ..addAll(mapped);
      _applyFilters();
    } catch (e) {
      _allBookings.clear();
      pastBookings.clear();
      if (forceRefresh || !hadBookings) {
        Get.snackbar(
          'Bookings unavailable',
          'We could not load your bookings right now. Please try again.',
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    } finally {
      isLoading.value = false;
    }
  }

  Map<String, dynamic> _mapBooking(Booking booking) {
    return {
      'id': booking.id.toString(),
      'hotelName': booking.displayTitle,
      'image': booking.displayImage,
      'location': booking.displayLocation,
      'checkIn': booking.checkInDate.toIso8601String(),
      'checkOut': booking.checkOutDate.toIso8601String(),
      'guests': booking.guests,
      'rooms': 1,
      'totalAmount': booking.totalAmount,
      'bookingDate': booking.createdAt.toIso8601String(),
      'status': booking.bookingStatus,
      'rating': 0.0,
      'canReview': false,
      'canRebook': true,
      'model': booking,
    };
  }

  void _applyFilters() {
    if (_allBookings.isEmpty) {
      pastBookings.clear();
      return;
    }
    if (_activeFilters.isEmpty) {
      pastBookings.assignAll(_allBookings);
      return;
    }
    final filtered =
        _allBookings
            .where((booking) => _activeFilters.matchesBooking(booking))
            .toList();
    pastBookings.assignAll(filtered);
  }

  void addOrUpdateBooking(Booking booking) {
    final mapped = _mapBooking(booking);
    final index = _allBookings.indexWhere(
      (existing) => existing['id'] == mapped['id'],
    );
    if (index >= 0) {
      _allBookings[index] = mapped;
    } else {
      _allBookings.insert(0, mapped);
    }
    _applyFilters();
  }

  void addBooking(Property property) {
    final now = DateTime.now();
    final checkInDate = now.add(const Duration(days: 7));
    final checkOutDate = checkInDate.add(const Duration(days: 3));
    final rawNights = checkOutDate.difference(checkInDate).inDays;
    final totalNights = rawNights <= 0 ? 1 : rawNights;

    final baseAmount = property.pricePerNight * totalNights;
    final serviceFees = baseAmount * 0.10;
    final taxes = baseAmount * 0.05;
    final totalAmount = (baseAmount + serviceFees + taxes).toDouble();

    simulateAddBooking(
      propertyId: property.id,
      propertyName: property.name,
      imageUrl: property.displayImage ?? '',
      address: property.address ?? property.fullAddress,
      city: property.city,
      country: property.country,
      checkIn: checkInDate,
      checkOut: checkOutDate,
      guests: property.maxGuests ?? 1,
      rooms: 1,
      totalAmount: totalAmount,
      nights: totalNights,
      status: 'upcoming',
      canReview: false,
      canRebook: false,
    );

    Get.snackbar(
      'Booking confirmed',
      '${property.name} added to your trips.',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.green[50],
      colorText: Colors.green[800],
    );
  }

  Future<void> cancelBooking(String bookingId) async {
    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('Cancel booking?'),
        content: const Text(
          'Are you sure you want to cancel this upcoming trip?',
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('Keep booking'),
          ),
          FilledButton(
            onPressed: () => Get.back(result: true),
            child: const Text('Cancel booking'),
          ),
        ],
      ),
    );

    if (confirmed != true) {
      return;
    }

    final before = _allBookings.length;
    _allBookings.removeWhere((booking) => booking['id'] == bookingId);
    pastBookings.removeWhere((booking) => booking['id'] == bookingId);
    if (before != _allBookings.length) {
      _applyFilters();
      Get.snackbar(
        'Booking cancelled',
        'Your trip has been cancelled.',
        snackPosition: SnackPosition.BOTTOM,
      );
    } else {
      pastBookings.refresh();
    }
  }

  Booking simulateAddBooking({
    required int propertyId,
    required String propertyName,
    required String imageUrl,
    String? address,
    required String city,
    required String country,
    required DateTime checkIn,
    required DateTime checkOut,
    required int guests,
    int rooms = 1,
    required double totalAmount,
    int? nights,
    int? userId,
    bool notifyUser = false,
    String status = 'confirmed',
    bool canReview = true,
    bool canRebook = true,
  }) {
    final now = DateTime.now();
    final bookingId = now.millisecondsSinceEpoch;
    final computedNights =
        nights ?? checkOut.difference(checkIn).inDays.clamp(1, 365);

    final booking = Booking.fromJson({
      'id': bookingId,
      'property_id': propertyId,
      'user_id': userId ?? 0,
      'booking_reference': 'SIM$bookingId',
      'check_in_date': checkIn.toIso8601String(),
      'check_out_date': checkOut.toIso8601String(),
      'guests': guests,
      'nights': computedNights,
      'total_amount': totalAmount,
      'booking_status': status,
      'payment_status': 'paid',
      'created_at': now.toIso8601String(),
      'property_title': propertyName,
      'property_city': city,
      'property_country': country,
      'property_image_url': imageUrl,
    });

    final mapped =
        _mapBooking(booking)
          ..['rooms'] = rooms
          ..['location'] =
              (address != null && address.trim().isNotEmpty)
                  ? address.trim()
                  : booking.displayLocation
          ..['canReview'] = canReview
          ..['canRebook'] = canRebook
          ..['isSimulated'] = true
          ..['status'] = status
          ..['totalAmount'] = totalAmount.toDouble()
          ..['bookingDate'] = now.toIso8601String();

    final existingIndex = _allBookings.indexWhere(
      (existing) => existing['id'] == mapped['id'],
    );
    if (existingIndex >= 0) {
      _allBookings[existingIndex] = mapped;
    } else {
      _allBookings.insert(0, mapped);
    }
    _applyFilters();

    if (notifyUser) {
      Get.snackbar(
        'Booking confirmed!',
        'Your stay at $propertyName is confirmed.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green[100],
        colorText: Colors.green[800],
      );
    }

    return booking;
  }

  bool get hasActiveFilters => _activeFilters.isNotEmpty;

  int get totalHistoryCount => _allBookings.length;

  void rebookHotel(Map<String, dynamic> booking) {
    Get.snackbar(
      'Rebooking',
      'Redirecting to ${booking['hotelName']} booking page',
      snackPosition: SnackPosition.TOP,
      backgroundColor: Colors.blue[50],
      colorText: Colors.blue[800],
      duration: const Duration(seconds: 2),
    );
    // In real app: Get.toNamed('/booking', arguments: booking);
  }

  void leaveReview(Map<String, dynamic> booking) {
    Get.dialog(
      AlertDialog(
        title: Text('Review ${booking['hotelName']}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('How was your stay?'),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (index) {
                return IconButton(
                  onPressed: () {
                    Get.back();
                    Get.snackbar(
                      'Thank You!',
                      'Your ${index + 1} star review has been submitted',
                      snackPosition: SnackPosition.TOP,
                      backgroundColor: Colors.green[50],
                      colorText: Colors.green[800],
                      duration: const Duration(seconds: 2),
                    );
                  },
                  icon: const Icon(
                    Icons.star_border,
                    color: Colors.amber,
                    size: 32,
                  ),
                );
              }),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
        ],
      ),
    );
  }

  void viewBookingDetails(Map<String, dynamic> booking) {
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Title
            const Text(
              'Booking Details',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            // Details
            _buildDetailRow('Booking ID', booking['id']),
            _buildDetailRow('Hotel', booking['hotelName']),
            _buildDetailRow('Location', booking['location']),
            _buildDetailRow('Check-in', _formatDate(booking['checkIn'])),
            _buildDetailRow('Check-out', _formatDate(booking['checkOut'])),
            _buildDetailRow('Guests', '${booking['guests']} guests'),
            _buildDetailRow('Rooms', '${booking['rooms']} room(s)'),
            _buildDetailRow(
              'Total Amount',
              '\$${booking['totalAmount'].toStringAsFixed(2)}',
            ),
            _buildDetailRow(
              'Status',
              booking['status'].toString().toUpperCase(),
            ),

            const SizedBox(height: 24),

            // Actions
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      Get.back();
                      rebookHotel(booking);
                    },
                    child: const Text('Book Again'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Get.back(),
                    child: const Text('Close'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      isScrollControlled: true,
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(color: Colors.grey[600], fontSize: 14),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
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
    } catch (e) {
      return dateStr;
    }
  }

  int get totalBookings => pastBookings.length;

  double get totalSpent =>
      pastBookings.fold(0, (sum, booking) => sum + booking['totalAmount']);

  String get favoriteDestination {
    if (pastBookings.isEmpty) return 'None';
    final locations = <String, int>{};
    for (final booking in pastBookings) {
      final location = booking['location'].toString().split(',').last.trim();
      locations[location] = (locations[location] ?? 0) + 1;
    }
    return locations.entries.reduce((a, b) => a.value > b.value ? a : b).key;
  }
}
