import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../data/models/unified_filter_model.dart';
import '../data/models/booking_model.dart';
import '../data/repositories/booking_repository.dart';
import 'filter_controller.dart';
import '../utils/exceptions/app_exceptions.dart';
import '../utils/logger/app_logger.dart';

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
    if (isLoading.value && !forceRefresh) {
      return;
    }
    try {
      isLoading.value = true;
      final bookings = await _bookingRepository.fetchBookings();
      final mapped = bookings.map(_mapBooking).toList()
        ..sort(_bookingComparator);
      _allBookings
        ..clear()
        ..addAll(mapped);
      _applyFilters();
    } on ApiException catch (error, stackTrace) {
      AppLogger.error('Failed to load bookings', error, stackTrace);
      if (forceRefresh || _allBookings.isEmpty) {
        pastBookings.clear();
        Get.snackbar(
          'Enquiries unavailable',
          error.message,
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    } catch (error, stackTrace) {
      AppLogger.error('Unexpected error while loading bookings', error, stackTrace);
      if (forceRefresh || _allBookings.isEmpty) {
        pastBookings.clear();
        Get.snackbar(
          'Enquiries unavailable',
          'We could not load your enquiries right now. Please try again.',
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
      'propertyId': booking.propertyId,
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

  Future<void> cancelBooking(String bookingId) async {
    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('Cancel enquiry?'),
        content: const Text(
          'Are you sure you want to cancel this enquiry?',
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('Keep enquiry'),
          ),
          FilledButton(
            onPressed: () => Get.back(result: true),
            child: const Text('Cancel enquiry'),
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
        'Enquiry cancelled',
        'Your enquiry has been cancelled.',
        snackPosition: SnackPosition.BOTTOM,
      );
    } else {
      pastBookings.refresh();
    }
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

  int _bookingComparator(
    Map<String, dynamic> a,
    Map<String, dynamic> b,
  ) {
    final aDate =
        DateTime.tryParse(a['checkIn']?.toString() ?? '') ??
        DateTime.fromMillisecondsSinceEpoch(0);
    final bDate =
        DateTime.tryParse(b['checkIn']?.toString() ?? '') ??
        DateTime.fromMillisecondsSinceEpoch(0);
    return bDate.compareTo(aDate);
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
              'Enquiry Details',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            // Details
            _buildDetailRow('Enquiry ID', booking['id']),
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
