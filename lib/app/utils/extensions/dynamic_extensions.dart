/// Helpers for parsing dynamic values to bool.

/// Parses a dynamic value to a boolean with a fallback.
///
/// Handles bool, num (non-zero = true), and String ('true', '1', 'yes').
/// Returns [fallback] if the value is null or cannot be parsed.
bool parseBool(dynamic value, {required bool fallback}) {
  if (value is bool) return value;
  if (value is num) return value != 0;
  if (value is String) {
    final normalized = value.toLowerCase();
    return normalized == 'true' || normalized == '1' || normalized == 'yes';
  }
  return fallback;
}
