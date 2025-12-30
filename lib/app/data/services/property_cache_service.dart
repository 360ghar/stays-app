import 'dart:convert';

import 'package:get_storage/get_storage.dart';

import '../models/property_model.dart';
import '../models/unified_property_response.dart';
import '../../utils/logger/app_logger.dart';

/// Service for caching property data locally for offline access.
/// Uses a stale-while-revalidate pattern.
class PropertyCacheService {
  static const String _boxName = 'property_cache';
  static const String _exploreKey = 'explore_results';
  static const String _detailsPrefix = 'property_';
  static const String _recommendationsKey = 'recommendations';
  static const String _timestampSuffix = '_timestamp';
  static const String _accessOrderKey = '_lru_access_order';

  /// Cache expiry duration (2 hours)
  static const Duration cacheExpiry = Duration(hours: 2);

  /// Maximum number of cached property details (LRU eviction)
  static const int maxCachedProperties = 100;

  /// Maximum number of cached explore pages
  static const int maxCachedExplorePages = 10;

  late final GetStorage _storage;
  bool _isInitialized = false;

  /// Initialize the cache storage
  Future<void> init() async {
    if (_isInitialized) return;
    await GetStorage.init(_boxName);
    _storage = GetStorage(_boxName);
    _isInitialized = true;
    AppLogger.info('PropertyCacheService initialized');
  }

  void _ensureInitialized() {
    if (!_isInitialized) {
      throw StateError(
        'PropertyCacheService not initialized. Call init() first.',
      );
    }
  }

  /// Cache explore results
  Future<void> cacheExploreResults(
    UnifiedPropertyResponse response, {
    double? lat,
    double? lng,
    int page = 1,
  }) async {
    _ensureInitialized();
    try {
      final key = _buildExploreKey(lat, lng, page);
      final data = {
        'properties': response.properties.map((p) => p.toJson()).toList(),
        'totalCount': response.totalCount,
        'currentPage': response.currentPage,
        'totalPages': response.totalPages,
        'pageSize': response.pageSize,
      };
      await _storage.write(key, jsonEncode(data));
      await _storage.write(
        '$key$_timestampSuffix',
        DateTime.now().toIso8601String(),
      );
      AppLogger.info(
        'Cached ${response.properties.length} properties for page $page',
      );
    } catch (e) {
      AppLogger.warning('Failed to cache explore results: $e');
    }
  }

  /// Get cached explore results
  UnifiedPropertyResponse? getCachedExploreResults({
    double? lat,
    double? lng,
    int page = 1,
    bool ignoreExpiry = false,
  }) {
    _ensureInitialized();
    try {
      final key = _buildExploreKey(lat, lng, page);

      if (!ignoreExpiry && _isCacheExpired(key)) {
        return null;
      }

      final jsonStr = _storage.read<String>(key);
      if (jsonStr == null) return null;

      final data = jsonDecode(jsonStr) as Map<String, dynamic>;
      final properties = (data['properties'] as List)
          .map((json) => Property.fromJson(json as Map<String, dynamic>))
          .toList();

      return UnifiedPropertyResponse(
        properties: properties,
        totalCount: data['totalCount'] as int? ?? properties.length,
        currentPage: data['currentPage'] as int? ?? page,
        totalPages: data['totalPages'] as int? ?? 1,
        pageSize: data['pageSize'] as int? ?? 20,
      );
    } catch (e) {
      AppLogger.warning('Failed to read cached explore results: $e');
      return null;
    }
  }

  /// Cache property details
  Future<void> cachePropertyDetails(Property property) async {
    _ensureInitialized();
    try {
      await _evictOldPropertiesIfNeeded();
      final key = '$_detailsPrefix${property.id}';
      await _storage.write(key, jsonEncode(property.toJson()));
      await _storage.write(
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

      final jsonStr = _storage.read<String>(key);
      if (jsonStr == null) return null;
      // Update access order asynchronously (fire-and-forget)
      _updateAccessOrder(id);

      return Property.fromJson(jsonDecode(jsonStr) as Map<String, dynamic>);
    } catch (e) {
      AppLogger.warning('Failed to read cached property details: $e');
      return null;
    }
  }

  /// Cache recommendations
  Future<void> cacheRecommendations(List<Property> properties) async {
    _ensureInitialized();
    try {
      final data = properties.map((p) => p.toJson()).toList();
      await _storage.write(_recommendationsKey, jsonEncode(data));
      await _storage.write(
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

      final jsonStr = _storage.read<String>(_recommendationsKey);
      if (jsonStr == null) return null;

      final data = jsonDecode(jsonStr) as List;
      return data
          .map((json) => Property.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      AppLogger.warning('Failed to read cached recommendations: $e');
      return null;
    }
  }

  /// Clear all cached data
  Future<void> clearAll() async {
    _ensureInitialized();
    await _storage.erase();
    AppLogger.info('Property cache cleared');
  }

  /// Clear expired cache entries
  Future<void> clearExpired() async {
    _ensureInitialized();
    final allKeys = _storage.getKeys();
    if (allKeys == null) return;
    final keyList = allKeys.whereType<String>().toList();
    for (final key in keyList) {
      if (!key.endsWith(_timestampSuffix) && _isCacheExpired(key)) {
        await _storage.remove(key);
        await _storage.remove('$key$_timestampSuffix');
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
        await _storage.remove(key);
        await _storage.remove('$key$_timestampSuffix');
      }

      // Update access order
      final newOrder = accessOrder.skip(toEvict).toList();
      await _storage.write(_accessOrderKey, jsonEncode(newOrder));

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
      await _storage.write(_accessOrderKey, jsonEncode(accessOrder));
    } catch (e) {
      AppLogger.warning('Failed to update access order: $e');
    }
  }

  /// Get current LRU access order
  List<int> _getAccessOrder() {
    try {
      final jsonStr = _storage.read<String>(_accessOrderKey);
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
    final allKeys = _storage.getKeys();
    final keyList = allKeys?.whereType<String>().toList() ?? [];
    final propertyKeys = keyList.where((k) => k.startsWith(_detailsPrefix) && !k.endsWith(_timestampSuffix)).length;
    final exploreKeys = keyList.where((k) => k.startsWith(_exploreKey) && !k.endsWith(_timestampSuffix)).length;
    return {
      'cachedProperties': propertyKeys,
      'cachedExplorePages': exploreKeys,
      'maxProperties': maxCachedProperties,
      'maxExplorePages': maxCachedExplorePages,
    };
  }

  String _buildExploreKey(double? lat, double? lng, int page) {
    final roundedLat = lat != null ? (lat * 100).round() / 100 : 'null';
    final roundedLng = lng != null ? (lng * 100).round() / 100 : 'null';
    return '${_exploreKey}_${roundedLat}_${roundedLng}_p$page';
  }

  bool _isCacheExpired(String key) {
    final timestampStr = _storage.read<String>('$key$_timestampSuffix');
    if (timestampStr == null) return true;

    try {
      final timestamp = DateTime.parse(timestampStr);
      return DateTime.now().difference(timestamp) > cacheExpiry;
    } catch (_) {
      return true;
    }
  }
}
