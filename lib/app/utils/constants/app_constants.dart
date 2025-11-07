/// Global application constants for consistent usage across the codebase.
class AppConstants {
  AppConstants._();

  // Currency
  static const String defaultCurrencyCode = 'INR';
  static const String defaultCurrencySymbol = '\u20B9'; // ₹

  // City canonicalization map (lowercase keys/values)
  static const Map<String, String> cityCanonicalMap = {
    'gurgaon': 'gurugram',
    'bangalore': 'bengaluru',
    'bombay': 'mumbai',
    'delhi ncr': 'delhi',
  };

  // Common default coordinates (if ever needed by maps or fallbacks)
  // These are intentionally centralized to avoid scattering magic numbers.
  static const double defaultLatitude = 19.0760; // Mumbai
  static const double defaultLongitude = 72.8777; // Mumbai
}

