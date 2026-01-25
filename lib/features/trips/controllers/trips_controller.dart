import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:stays_app/app/controllers/base/base_controller.dart';
import 'package:stays_app/app/data/models/unified_filter_model.dart';
import 'package:stays_app/app/data/models/booking_model.dart';
import 'package:stays_app/app/data/models/property_model.dart';
import 'package:stays_app/app/data/repositories/booking_repository.dart';
import 'package:stays_app/app/data/repositories/properties_repository.dart';
import 'package:stays_app/app/controllers/filter_controller.dart';
import 'package:stays_app/app/utils/exceptions/app_exceptions.dart';
import 'package:stays_app/app/utils/helpers/app_snackbar.dart';
import 'package:stays_app/app/utils/helpers/booking_helpers.dart';
import 'package:stays_app/app/utils/logger/app_logger.dart';
import 'package:stays_app/features/trips/views/widgets/booking_details_sheet.dart';

class TripsController extends BaseController {
  final RxList<Map<String, dynamic>> pastBookings =
      <Map<String, dynamic>>[].obs;

  late final BookingRepository _bookingRepository;
  PropertiesRepository? _propertiesRepository;
  FilterController? _filterController;

  final List<Map<String, dynamic>> _allBookings = [];
  UnifiedFilterModel _activeFilters = UnifiedFilterModel.empty;

  @override
  void onInit() {
    super.onInit();
    _bookingRepository = Get.find<BookingRepository>();
    if (Get.isRegistered<PropertiesRepository>()) {
      _propertiesRepository = Get.find<PropertiesRepository>();
    } else {
      AppLogger.warning('PropertiesRepository not found for TripsController');
    }
    _initializeFilterSync();
    loadPastBookings();
  }

  void _initializeFilterSync() {
    if (!Get.isRegistered<FilterController>()) return;
    _filterController = Get.find<FilterController>();
    _activeFilters = _filterController!.filterFor(FilterScope.booking);
    trackWorker(debounce<UnifiedFilterModel>(
      _filterController!.rxFor(FilterScope.booking),
      (filters) {
        if (_activeFilters == filters) return;
        _activeFilters = filters;
        _applyFilters();
      },
      time: const Duration(milliseconds: 120),
    ));
  }

  @override
  void onClose() {
    // Worker is automatically disposed by BaseController via trackWorker
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
      await _enrichBookingsWithProperties(mapped);
      _allBookings
        ..clear()
        ..addAll(mapped);
      _applyFilters();
    } on ApiException catch (error, stackTrace) {
      AppLogger.error('Failed to load bookings', error, stackTrace);
      if (forceRefresh || _allBookings.isEmpty) {
        pastBookings.clear();
        AppSnackbar.error(
          title: 'Inquiries unavailable',
          message: error.message,
        );
      }
    } catch (error, stackTrace) {
      AppLogger.error(
        'Unexpected error while loading bookings',
        error,
        stackTrace,
      );
      if (forceRefresh || _allBookings.isEmpty) {
        pastBookings.clear();
        AppSnackbar.error(
          title: 'Inquiries unavailable',
          message: 'We could not load your inquiries right now. Please try again.',
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

  Future<void> _enrichBookingsWithProperties(
    List<Map<String, dynamic>> bookings,
  ) async {
    if (_propertiesRepository == null) return;
    final targets = bookings
        .where(_needsPropertyHydration)
        .map((booking) => booking['propertyId'])
        .whereType<int>()
        .toSet();
    if (targets.isEmpty) return;

    final fetchedEntries = await Future.wait(
      targets.map((propertyId) async {
        try {
          final property = await _propertiesRepository!.getDetails(propertyId);
          return MapEntry(propertyId, property);
        } catch (error, stackTrace) {
          AppLogger.error(
            'Failed to load property $propertyId for bookings',
            error,
            stackTrace,
          );
          return null;
        }
      }),
    );
    final propertyById = <int, Property>{};
    for (final entry in fetchedEntries) {
      if (entry == null) continue;
      propertyById[entry.key] = entry.value;
    }
    if (propertyById.isEmpty) return;

    for (final booking in bookings) {
      final propertyId = booking['propertyId'];
      if (propertyId is! int) continue;
      final property = propertyById[propertyId];
      if (property == null) continue;
      booking
        ..['hotelName'] = property.name
        ..['image'] = property.displayImage ?? ''
        ..['location'] = property.fullAddress
        ..['property'] = property;
    }
  }

  bool _needsPropertyHydration(Map<String, dynamic> booking) {
    final image = booking['image']?.toString() ?? '';
    final title = booking['hotelName']?.toString() ?? '';
    final location = booking['location']?.toString() ?? '';
    return image.isEmpty || title == 'Stay' || location.isEmpty;
  }

  _BookingSnapshot? _setBookingStatusLocally(
    String bookingId, {
    required String status,
  }) {
    final index = _allBookings.indexWhere(
      (booking) => booking['id'] == bookingId,
    );
    if (index == -1) return null;
    final previous = Map<String, dynamic>.from(_allBookings[index]);
    final updated = Map<String, dynamic>.from(previous)..['status'] = status;
    _allBookings[index] = updated;

    final pastIndex = pastBookings.indexWhere(
      (booking) => booking['id'] == bookingId,
    );
    if (pastIndex != -1) {
      pastBookings[pastIndex] = Map<String, dynamic>.from(updated);
    }
    _applyFilters();
    return _BookingSnapshot(index: index, booking: previous);
  }

  void _restoreBookingSnapshot(_BookingSnapshot? snapshot) {
    if (snapshot == null) return;
    if (snapshot.index >= 0 && snapshot.index < _allBookings.length) {
      _allBookings[snapshot.index] = snapshot.booking;
    }
    _applyFilters();
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
    final filtered = _allBookings
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
        title: const Text('Cancel inquiry?'),
        content: const Text('Are you sure you want to cancel this inquiry?'),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('Keep inquiry'),
          ),
          FilledButton(
            onPressed: () => Get.back(result: true),
            child: const Text('Cancel inquiry'),
          ),
        ],
      ),
    );

    if (confirmed != true) {
      return;
    }

    final parsedId = int.tryParse(bookingId);
    if (parsedId == null) {
      AppSnackbar.warning(
        title: 'Unable to cancel',
        message: 'This inquiry is missing a valid identifier.',
      );
      return;
    }

    final snapshot = _setBookingStatusLocally(bookingId, status: 'cancelled');
    try {
      await _bookingRepository.cancelBooking(bookingId: parsedId);
      AppSnackbar.success(
        title: 'Inquiry cancelled',
        message: 'Your inquiry has been cancelled.',
      );
    } on ApiException catch (error) {
      _restoreBookingSnapshot(snapshot);
      AppSnackbar.error(
        title: 'Unable to cancel',
        message: error.message,
      );
    } catch (_) {
      _restoreBookingSnapshot(snapshot);
      AppSnackbar.error(
        title: 'Unable to cancel',
        message: 'We could not cancel this inquiry. Please try again.',
      );
    }
  }

  bool get hasActiveFilters => _activeFilters.isNotEmpty;

  int get totalHistoryCount => _allBookings.length;

  void rebookHotel(Map<String, dynamic> booking) {
    AppSnackbar.info(
      title: 'Rebooking',
      message: 'Redirecting to ${booking['hotelName']} inquiry page',
    );
    // In real app: Get.toNamed('/inquiry', arguments: booking);
  }

  int _bookingComparator(Map<String, dynamic> a, Map<String, dynamic> b) {
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
                    AppSnackbar.success(
                      title: 'Thank You!',
                      message: 'Your ${index + 1} star review has been submitted',
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
      BookingDetailsSheet(
        booking: booking,
        onRebook: () => rebookHotel(booking),
      ),
      isScrollControlled: true,
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

  double get totalSpent => pastBookings.fold<double>(0, (sum, booking) {
    final status = booking['status']?.toString();
    if (!shouldCountBookingStatus(status)) {
      return sum;
    }
    final amount = booking['totalAmount'];
    if (amount is num) {
      return sum + amount.toDouble();
    }
    return sum;
  });

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

class _BookingSnapshot {
  const _BookingSnapshot({required this.index, required this.booking});
  final int index;
  final Map<String, dynamic> booking;
}
