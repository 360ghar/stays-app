/// Centralized storage key constants to avoid magic strings.
/// Use these keys for all storage operations across the app.
class StorageKeys {
  StorageKeys._();

  // Token storage keys (secure storage)
  static const accessToken = 'access_token';
  static const refreshToken = 'refresh_token';
  static const tokenExpiresAt = 'token_expires_at';

  // User data storage
  static const userData = 'user_data';

  // Remember-me preferences
  static const rememberMeBox = 'auth_preferences';
  static const rememberMeFlag = 'remember_me';
  static const rememberedAccessToken = 'remembered_access_token';
  static const rememberedRefreshToken = 'remembered_refresh_token';

  // App storage boxes
  static const appStorageBox = 'app_storage';
  static const propertyCacheBox = 'property_cache';

  // Theme preferences
  static const themeMode = 'theme_mode';

  // Locale preferences
  static const localeCode = 'locale_code';

  // Device/push notification
  static const deviceToken = 'device_token';
  static const pushNotificationsEnabled = 'push_notifications_enabled';

  // Cache prefixes
  static const cachePrefix = 'cache_';
}
