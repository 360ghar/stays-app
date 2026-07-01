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
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
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
                color: colors.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Title
          Text(
            'Inquiry Details',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),

          // Details
          _buildDetailRow(
            context,
            'Inquiry ID',
            booking['id']?.toString() ?? '',
          ),
          _buildDetailRow(
            context,
            'Hotel',
            booking['hotelName']?.toString() ?? '',
          ),
          _buildDetailRow(
            context,
            'Location',
            booking['location']?.toString() ?? '',
          ),
          _buildDetailRow(
            context,
            'Check-in',
            _formatDate(booking['checkIn']?.toString() ?? ''),
          ),
          _buildDetailRow(
            context,
            'Check-out',
            _formatDate(booking['checkOut']?.toString() ?? ''),
          ),
          _buildDetailRow(
            context,
            'Guests',
            '${booking['guests'] ?? 0} guests',
          ),
          _buildDetailRow(context, 'Rooms', '${booking['rooms'] ?? 1} room(s)'),
          _buildDetailRow(
            context,
            'Total Amount',
            '\$${(booking['totalAmount'] as num?)?.toStringAsFixed(2) ?? '0.00'}',
          ),
          _buildDetailRow(
            context,
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
                child: FilledButton(
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

  Widget _buildDetailRow(BuildContext context, String label, String value) {
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(color: colors.onSurfaceVariant, fontSize: 14),
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
