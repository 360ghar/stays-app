import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// A bottom sheet widget displaying detailed booking/inquiry information.
class BookingDetailsSheet extends StatelessWidget {
  const BookingDetailsSheet({
    required this.booking,
    required this.onRebook,
    super.key,
  });

  final Map<String, dynamic> booking;
  final VoidCallback onRebook;

  @override
  Widget build(BuildContext context) {
    return Container(
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
            'Inquiry Details',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),

          // Details
          _buildDetailRow('Inquiry ID', booking['id']?.toString() ?? ''),
          _buildDetailRow('Hotel', booking['hotelName']?.toString() ?? ''),
          _buildDetailRow('Location', booking['location']?.toString() ?? ''),
          _buildDetailRow('Check-in', _formatDate(booking['checkIn']?.toString() ?? '')),
          _buildDetailRow('Check-out', _formatDate(booking['checkOut']?.toString() ?? '')),
          _buildDetailRow('Guests', '${booking['guests'] ?? 0} guests'),
          _buildDetailRow('Rooms', '${booking['rooms'] ?? 1} room(s)'),
          _buildDetailRow(
            'Total Amount',
            '\$${(booking['totalAmount'] as num?)?.toStringAsFixed(2) ?? '0.00'}',
          ),
          _buildDetailRow(
            'Status',
            (booking['status']?.toString() ?? '').toUpperCase(),
          ),

          const SizedBox(height: 24),

          // Actions
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    Get.back();
                    onRebook();
                  },
                  child: const Text('Inquire Again'),
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
    if (dateStr.isEmpty) return '';
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
}
