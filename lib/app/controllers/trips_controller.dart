import 'package:flutter/material.dart';
import 'package:get/get.dart';

class TripsController extends GetxController {
  final RxList<Map<String, dynamic>> pastBookings = <Map<String, dynamic>>[].obs;
  final RxBool isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    loadPastBookings();
  }

  void loadPastBookings() {
    isLoading.value = true;
    
    // Simulate loading past bookings - in real app this would come from API
    Future.delayed(const Duration(seconds: 1), () {
      pastBookings.value = [
        {
          'id': 'booking_001',
          'hotelName': 'Grand Hotel Marina',
          'image': 'https://images.unsplash.com/photo-1566073771259-6a8506099945',
          'location': 'Miami Beach, Florida',
          'checkIn': '2024-01-15',
          'checkOut': '2024-01-18',
          'guests': 2,
          'rooms': 1,
          'totalAmount': 890.00,
          'bookingDate': '2023-12-20',
          'status': 'completed',
          'rating': 4.8,
          'canReview': true,
          'canRebook': true,
        },
        {
          'id': 'booking_002',
          'hotelName': 'Mountain View Resort',
          'image': 'https://images.unsplash.com/photo-1587061949409-02df41d5e562',
          'location': 'Aspen, Colorado',
          'checkIn': '2023-12-22',
          'checkOut': '2023-12-26',
          'guests': 4,
          'rooms': 2,
          'totalAmount': 1250.00,
          'bookingDate': '2023-11-10',
          'status': 'completed',
          'rating': 4.9,
          'canReview': false,
          'canRebook': true,
        },
        {
          'id': 'booking_003',
          'hotelName': 'City Center Boutique',
          'image': 'https://images.unsplash.com/photo-1560448204-e02f11c3d0e2',
          'location': 'New York, NY',
          'checkIn': '2023-10-05',
          'checkOut': '2023-10-08',
          'guests': 2,
          'rooms': 1,
          'totalAmount': 720.00,
          'bookingDate': '2023-09-15',
          'status': 'completed',
          'rating': 4.6,
          'canReview': false,
          'canRebook': true,
        },
      ];
      isLoading.value = false;
    });
  }

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
                  icon: const Icon(Icons.star_border, color: Colors.amber, size: 32),
                );
              }),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel'),
          ),
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
            Text(
              'Booking Details',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
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
            _buildDetailRow('Total Amount', '\$${booking['totalAmount'].toStringAsFixed(2)}'),
            _buildDetailRow('Status', booking['status'].toString().toUpperCase()),
            
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
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
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
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
      ];
      return '${date.day} ${months[date.month - 1]}, ${date.year}';
    } catch (e) {
      return dateStr;
    }
  }

  int get totalBookings => pastBookings.length;
  
  double get totalSpent => pastBookings.fold(0, (sum, booking) => sum + booking['totalAmount']);
  
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