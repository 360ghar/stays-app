/// Network-layer slice of [AppConfig].
///
/// Additive split: new code should read `AppConfig.I.api.apiBaseUrl` /
/// `AppConfig.I.api.enableAnalytics` instead of the top-level fields.
class ApiConfig {
  const ApiConfig({required this.apiBaseUrl, this.enableAnalytics = false});

  final String apiBaseUrl;
  final bool enableAnalytics;
}
