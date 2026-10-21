import 'dart:async';
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/property_model.dart';
import '../models/unified_property_response.dart';
import '../../utils/logger/app_logger.dart';

/// Service for caching property data locally for offline access.
/// Uses a stale-while-revalidate pattern.
///
/// Rules this cache keeps:
/// - It never holds an owner contact number: [Property.toJson] leaves
///   `owner_contact` out.
/// - Each store has its own schema version. An entry of another version is
///   ignored.
/// - Every key carries the signed-in account. One account never reads the
///   entries of another.
/// - The whole cache is purged when the user signs out.
/// - A response that says `Cache-Control: no-store` is not written (the
///   caller checks `noStore`).
class PropertyCacheService {
  factory PropertyCacheService() => _shared;
  PropertyCacheService._internal();

  // Shared instance so the whole app shares one cache.
  static final PropertyCacheService _shared = PropertyCacheService._internal();

  /// Prefix of every key of this cache. Builds before the account scope
  /// wrote `pc_` keys that could hold owner contact numbers. [init] removes
  /// them.
  static const String _legacyPrefix = 'pc_';
  static const String _keyPrefix = 'pcache_';
  static const String _timestampSuffix = '_timestamp';

  /// Cache expiry duration (2 hours)
  static const Duration cacheExpiry = Duration(hours: 2);

  /// Schema version of each store. Bump the one whose payload shape changes.
  static const int exploreSchemaVersion = 3;
  static const int detailsSchemaVersion = 2;
  static const int recommendationsSchemaVersion = 2;

  /// Maximum number of cached property details (LRU eviction)
  static const int maxCachedProperties = 100;

  /// Maximum number of cached explore pages
  static const int maxCachedExplorePages = 10;

  SharedPreferences? _prefs;
  bool _isInitialized = false;
  StreamSubscription<AuthState>? _authSub;

  /// The signed-in account, or `anon`. Tests replace it.
  String Function() accountScope = _supabaseAccount;

  static String _supabaseAccount() {
    try {
      return Supabase.instance.client.auth.currentUser?.id ?? 'anon';
    } catch (_) {
      return 'anon';
    }
  }

  /// Initialize the cache storage
  Future<void> init() async {
    if (_isInitialized) return;
    _prefs ??= await SharedPreferences.getInstance();
    _isInitialized = true;
    await _removeLegacyKeys();
    _authSub ??= _listenForSignOut();
    AppLogger.info('PropertyCacheService initialized');
  }

  /// Stops watching the auth state.
  void dispose() {
    unawaited(_authSub?.cancel());
    _authSub = null;
  }

  void _ensureInitialized() {
    if (!_isInitialized || _prefs == null) {
      throw StateError(
        'PropertyCacheService not initialized. Call init() first.',
      );
    }
  }

  Future<void> _removeLegacyKeys() async {
    final legacy = _prefs!.getKeys().where((k) => k.startsWith(_legacyPrefix));
    for (final key in legacy.toList()) {
      await _prefs!.remove(key);
    }
  }

  /// Purges the whole cache when the user signs out.
  StreamSubscription<AuthState>? _listenForSignOut() {
    try {
      return Supabase.instance.client.auth.onAuthStateChange.listen((state) {
        if (state.event == AuthChangeEvent.signedOut) {
          unawaited(clearAll());
        }
      });
    } catch (e) {
      AppLogger.warning('Property cache could not watch sign-out: $e');
      return null;
    }
  }

  /// The account the cache is scoped to now. A caller reads it before a
  /// request and passes it back as `scope`: the write is dropped when the
  /// account changed while the request ran.
  String get scope => accountScope();

  String get _scopePrefix => '$_keyPrefix${accountScope()}_';
  String get _exploreKey => '${_scopePrefix}explore';
  String get _detailsPrefix => '${_scopePrefix}property_';
  String get _recommendationsKey => '${_scopePrefix}recommendations';
  String get _accessOrderKey => '${_scopePrefix}lru_access_order';

  /// Cache explore results. [variant] names the filters, radius and page size
  /// of the request, so a page of one filter set is never read for another.
  Future<void> cacheExploreResults(
    UnifiedPropertyResponse response, {
    double? lat,
    double? lng,
    String? cursor,
    String variant = '',
    String? scope,
  }) async {
    _ensureInitialized();
    if (response.noStore || (scope != null && scope != this.scope)) return;
    try {
      final key = _buildExploreKey(lat, lng, cursor, variant);
      final data = {
        'schema_version': exploreSchemaVersion,
        'items': response.items.map((p) => p.toJson()).toList(),
        'nextCursor': response.nextCursor,
        'hasMore': response.hasMore,
        'limit': response.limit,
        if (response.total != null) 'total': response.total,
      };
      await _prefs!.setString(key, jsonEncode(data));
      await _prefs!.setString(
        '$key$_timestampSuffix',
        DateTime.now().toIso8601String(),
      );
      AppLogger.info(
        'Cached ${response.items.length} properties for cursor ${cursor ?? 'first'}',
      );
    } catch (e) {
      AppLogger.warning('Failed to cache explore results: $e');
    }
  }

  /// Get cached explore results
  UnifiedPropertyResponse? getCachedExploreResults({
    double? lat,
    double? lng,
    String? cursor,
    String variant = '',
    bool ignoreExpiry = false,
  }) {
    _ensureInitialized();
    try {
      final key = _buildExploreKey(lat, lng, cursor, variant);

      if (!ignoreExpiry && _isCacheExpired(key)) {
        return null;
      }

      final jsonStr = _prefs!.getString(key);
      if (jsonStr == null) return null;

      final data = jsonDecode(jsonStr) as Map<String, dynamic>;
      // Ignore entries written by another schema version.
      if (data['schema_version'] != exploreSchemaVersion) return null;
      final items = (data['items'] as List)
          .map((json) => Property.fromJson(json as Map<String, dynamic>))
          .toList();

      return UnifiedPropertyResponse(
        items: items,
        nextCursor: data['nextCursor'] as String?,
        hasMore: (data['hasMore'] as bool?) ?? false,
        limit: (data['limit'] as num?)?.toInt() ?? items.length,
        total: (data['total'] as num?)?.toInt(),
      );
    } catch (e) {
      AppLogger.warning('Failed to read cached explore results: $e');
      return null;
    }
  }

  /// Cache property details
  Future<void> cachePropertyDetails(
    Property property, {
    bool noStore = false,
    String? scope,
  }) async {
    _ensureInitialized();
    if (noStore || (scope != null && scope != this.scope)) return;
    try {
      await _evictOldPropertiesIfNeeded();
      final key = '$_detailsPrefix${property.id}';
      await _prefs!.setString(
        key,
        jsonEncode({
          'schema_version': detailsSchemaVersion,
          'property': property.toJson(),
        }),
      );
      await _prefs!.setString(
        '$key$_timestampSuffix',
        DateTime.now().toIso8601String(),
      );
      await _updateAccessOrder(property.id);
      AppLogger.info('Cached property details for ID ${property.id}');
    } catch (e) {
      AppLogger.warning('Failed to cache property details: $e');
    }
  }

  /// Get cached property details
  Property? getCachedPropertyDetails(int id, {bool ignoreExpiry = false}) {
    _ensureInitialized();
    try {
      final key = '$_detailsPrefix$id';

      if (!ignoreExpiry && _isCacheExpired(key)) {
        return null;
      }

      final jsonStr = _prefs!.getString(key);
      if (jsonStr == null) return null;
      final data = jsonDecode(jsonStr) as Map<String, dynamic>;
      if (data['schema_version'] != detailsSchemaVersion) return null;
      // Update access order asynchronously (fire-and-forget)
      unawaited(_updateAccessOrder(id));

      return Property.fromJson(data['property'] as Map<String, dynamic>);
    } catch (e) {
      AppLogger.warning('Failed to read cached property details: $e');
      return null;
    }
  }

  /// Cache recommendations
  Future<void> cacheRecommendations(
    List<Property> properties, {
    bool noStore = false,
    String? scope,
  }) async {
    _ensureInitialized();
    if (noStore || (scope != null && scope != this.scope)) return;
    try {
      final data = {
        'schema_version': recommendationsSchemaVersion,
        'items': properties.map((p) => p.toJson()).toList(),
      };
      await _prefs!.setString(_recommendationsKey, jsonEncode(data));
      await _prefs!.setString(
        '$_recommendationsKey$_timestampSuffix',
        DateTime.now().toIso8601String(),
      );
      AppLogger.info('Cached ${properties.length} recommendations');
    } catch (e) {
      AppLogger.warning('Failed to cache recommendations: $e');
    }
  }

  /// Get cached recommendations
  List<Property>? getCachedRecommendations({bool ignoreExpiry = false}) {
    _ensureInitialized();
    try {
      if (!ignoreExpiry && _isCacheExpired(_recommendationsKey)) {
        return null;
      }

      final jsonStr = _prefs!.getString(_recommendationsKey);
      if (jsonStr == null) return null;

      final data = jsonDecode(jsonStr) as Map<String, dynamic>;
      if (data['schema_version'] != recommendationsSchemaVersion) return null;
      return (data['items'] as List)
          .map((json) => Property.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      AppLogger.warning('Failed to read cached recommendations: $e');
      return null;
    }
  }

  /// Clear all cached data of every account (only keys owned by this service).
  Future<void> clearAll() async {
    _ensureInitialized();
    for (final key
        in _prefs!.getKeys().where((k) => k.startsWith(_keyPrefix)).toList()) {
      await _prefs!.remove(key);
    }
    AppLogger.info('Property cache cleared');
  }

  /// Clear expired cache entries
  Future<void> clearExpired() async {
    _ensureInitialized();
    final keyList = _prefs!
        .getKeys()
        .where(
          (k) =>
              k.startsWith(_keyPrefix) &&
              !k.endsWith(_timestampSuffix) &&
              !k.endsWith('lru_access_order'),
        )
        .toList();
    if (keyList.isEmpty) return;
    for (final key in keyList) {
      if (_isCacheExpired(key)) {
        await _prefs!.remove(key);
        await _prefs!.remove('$key$_timestampSuffix');
      }
    }
    AppLogger.info('Cleared expired cache entries');
  }

  /// Evict oldest property details if cache exceeds limit (LRU)
  Future<void> _evictOldPropertiesIfNeeded() async {
    try {
      final accessOrder = _getAccessOrder();
      if (accessOrder.length < maxCachedProperties) return;

      // Calculate how many to evict (remove 20% when limit reached)
      final toEvict = (maxCachedProperties * 0.2).ceil();
      final idsToRemove = accessOrder.take(toEvict).toList();

      for (final id in idsToRemove) {
        final key = '$_detailsPrefix$id';
        await _prefs!.remove(key);
        await _prefs!.remove('$key$_timestampSuffix');
      }

      // Update access order
      final newOrder = accessOrder.skip(toEvict).toList();
      await _prefs!.setString(_accessOrderKey, jsonEncode(newOrder));

      AppLogger.info('Evicted $toEvict old property cache entries');
    } catch (e) {
      AppLogger.warning('Failed to evict old properties: $e');
    }
  }

  /// Update LRU access order for a property
  Future<void> _updateAccessOrder(int propertyId) async {
    try {
      final accessOrder = _getAccessOrder();
      // Remove if exists and add to end (most recently accessed)
      accessOrder.remove(propertyId);
      accessOrder.add(propertyId);
      await _prefs!.setString(_accessOrderKey, jsonEncode(accessOrder));
    } catch (e) {
      AppLogger.warning('Failed to update access order: $e');
    }
  }

  /// Get current LRU access order
  List<int> _getAccessOrder() {
    try {
      final jsonStr = _prefs?.getString(_accessOrderKey);
      if (jsonStr == null) return [];
      final list = jsonDecode(jsonStr) as List;
      return list.map((e) => e as int).toList();
    } catch (_) {
      return [];
    }
  }

  /// Get cache statistics for debugging/monitoring
  Map<String, dynamic> getCacheStats() {
    _ensureInitialized();
    final keyList = _prefs!.getKeys().toList();
    final propertyKeys = keyList
        .where(
          (k) => k.startsWith(_detailsPrefix) && !k.endsWith(_timestampSuffix),
        )
        .length;
    final exploreKeys = keyList
        .where(
          (k) => k.startsWith(_exploreKey) && !k.endsWith(_timestampSuffix),
        )
        .length;
    return {
      'cachedProperties': propertyKeys,
      'cachedExplorePages': exploreKeys,
      'maxProperties': maxCachedProperties,
      'maxExplorePages': maxCachedExplorePages,
    };
  }

  String _buildExploreKey(
    double? lat,
    double? lng,
    String? cursor,
    String variant,
  ) {
    final roundedLat = lat != null ? (lat * 100).round() / 100 : 'null';
    final roundedLng = lng != null ? (lng * 100).round() / 100 : 'null';
    // Cursor tokens are opaque; hash them so the cache key stays short
    // and stable. A null cursor represents the first page.
    final cursorKey = (cursor == null || cursor.isEmpty)
        ? 'first'
        : 'c${cursor.hashCode}';
    return '${_exploreKey}_${roundedLat}_${roundedLng}_${variant.hashCode}_$cursorKey';
  }

  bool _isCacheExpired(String key) {
    final timestampStr = _prefs!.getString('$key$_timestampSuffix');
    if (timestampStr == null) return true;

    try {
      final timestamp = DateTime.parse(timestampStr);
      return DateTime.now().difference(timestamp) > cacheExpiry;
    } catch (_) {
      return true;
    }
  }
}
