// Helpers for parsing dynamic values to bool.

/// Parses a dynamic value to a boolean with a fallback.
///
/// Handles bool, num (non-zero = true), and String truthy/falsy tokens.
/// Returns [fallback] if the value is null or cannot be parsed.
bool parseBool(dynamic value, {required bool fallback}) {
  if (value is bool) return value;
  if (value is num) return value != 0;
  if (value is String) {
    final normalized = value.trim().toLowerCase();
    if (normalized == 'true' || normalized == '1' || normalized == 'yes') {
      return true;
    }
    if (normalized == 'false' || normalized == '0' || normalized == 'no') {
      return false;
    }
    return fallback;
  }
  return fallback;
}
