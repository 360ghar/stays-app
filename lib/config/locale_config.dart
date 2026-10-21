/// Locale-layer slice of [AppConfig].
///
/// Canonical phone-normalization API: read `AppConfig.I.locale.*`. The
/// dial-code map and fallback consts live here only.
class LocaleConfig {
  const LocaleConfig({this.defaultCountry = fallbackDefaultCountry});

  /// ISO-3166 alpha-2 country code used for phone normalization when the user
  /// has not explicitly picked a country.
  final String defaultCountry;

  /// Built-in fallback ISO country.
  static const String fallbackDefaultCountry = 'IN';

  /// Built-in fallback dial code for countries missing from
  /// [defaultCountryDialCodes].
  static const String fallbackDefaultDialCode = '+91';

  /// Minimal fallback dial-code map. The source of truth for supported
  /// countries/dial codes lives with the country picker used by auth flow.
  static const Map<String, String> defaultCountryDialCodes = <String, String>{
    'IN': '+91',
    'US': '+1',
    'GB': '+44',
    'AE': '+971',
    'SG': '+65',
    'AU': '+61',
    'CA': '+1',
    'MY': '+60',
  };

  /// Dial code for [defaultCountry], falling back to [fallbackDefaultDialCode].
  String get defaultCountryDialCode =>
      defaultCountryDialCodes[defaultCountry] ?? fallbackDefaultDialCode;
}
