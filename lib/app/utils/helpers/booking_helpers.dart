/// Helpers for booking status checks.

/// Keywords indicating a negative/excluded booking status.
const _negativeStatusKeywords = [
  'cancel',
  'refund',
  'fail',
  'decline',
  'reject',
  'void',
  'expired',
];

/// Returns true if the booking status should be counted in spend/stats.
///
/// Excludes cancelled, refunded, failed, and other negative statuses.
bool shouldCountBookingStatus(String? status) {
  if (status == null) return false;
  final normalized = status.trim().toLowerCase();
  if (normalized.isEmpty) return false;

  if (_negativeStatusKeywords.any((keyword) => normalized.contains(keyword))) {
    return false;
  }
  return true;
}
