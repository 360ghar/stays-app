import 'dart:async';

import 'package:get/get.dart';

import '../providers/properties_provider.dart';
import '../models/property_model.dart';
import '../models/unified_property_response.dart';
import '../services/location_service.dart';
import '../services/property_cache_service.dart';
import '../../utils/logger/app_logger.dart';
import '../../utils/services/connectivity_service.dart';

class PropertiesRepository {
  PropertiesRepository({required PropertiesProvider provider})
    : _provider = provider {
    _initCache();
  }
  final PropertiesProvider _provider;
  PropertyCacheService? _cacheService;

  /// In-flight request dedupe: concurrent calls with the same key share one
  /// network request. Entries are removed when the future completes.
  final Map<String, Future<dynamic>> _inFlight = {};

  void _initCache() {
    if (Get.isRegistered<PropertyCacheService>()) {
      _cacheService = Get.find<PropertyCacheService>();
    }
  }

  /// Lazily re-resolves the cache service (cheap) so a late registration
  /// (e.g. InitialBinding's putAsync completing after this repository was
  /// constructed) is still picked up.
  PropertyCacheService? _cache() {
    final cached = _cacheService;
    if (cached != null) return cached;
    if (Get.isRegistered<PropertyCacheService>()) {
      _cacheService = Get.find<PropertyCacheService>();
    }
    return _cacheService;
  }

  Future<UnifiedPropertyResponse> explore({
    double? lat,
    double? lng,
    String? cursor,
    int limit = 20,
    double radiusKm = 10,
    Map<String, dynamic>? filters,
    bool forceRefresh = false,
  }) {
    const defaultLat = 19.0760;
    const defaultLng = 72.8777;

    double? la = lat;
    double? ln = lng;
    if (la == null || ln == null) {
      try {
        final loc = Get.find<LocationService>();
        la ??= loc.latitude;
        ln ??= loc.longitude;
      } catch (_) {}
    }
    la ??= defaultLat;
    ln ??= defaultLng;
    final resolvedLat = la;
    final resolvedLng = ln;
    final queryFilters = <String, dynamic>{...?filters}
      ..removeWhere((key, value) => value == null);
    queryFilters.putIfAbsent('purpose', () => 'short_stay');

    return _dedupe(
      'explore|$resolvedLat|$resolvedLng|$cursor|$limit|$radiusKm|${_stableFiltersHash(queryFilters)}',
      () => _explore(
        resolvedLat,
        resolvedLng,
        cursor,
        limit,
        radiusKm,
        queryFilters,
        forceRefresh,
      ),
    );
  }

  Future<UnifiedPropertyResponse> _explore(
    double la,
    double ln,
    String? cursor,
    int limit,
    double radiusKm,
    Map<String, dynamic> queryFilters,
    bool forceRefresh,
  ) async {
    // Try cache first if not forcing refresh
    final cache = _cache();
    if (!forceRefresh && cache != null) {
      final cached = cache.getCachedExploreResults(
        lat: la,
        lng: ln,
        cursor: cursor,
      );
      if (cached != null) {
        AppLogger.info(
          'Returning cached explore results for cursor ${cursor ?? 'first'}',
        );
        // Fetch fresh data in background (stale-while-revalidate)
        unawaited(
          _refreshExploreInBackground(
            la,
            ln,
            cursor,
            limit,
            radiusKm,
            queryFilters,
          ),
        );
        return cached;
      }
    }

    final response = await _provider.explore(
      lat: la,
      lng: ln,
      cursor: cursor,
      limit: limit,
      radiusKm: radiusKm,
      filters: queryFilters,
    );

    // Cache the response
    unawaited(
      cache?.cacheExploreResults(response, lat: la, lng: ln, cursor: cursor),
    );

    return response;
  }

  /// Deterministic, order-independent fingerprint of the filters map so the
  /// dedupe key is stable across equivalent requests.
  String _stableFiltersHash(Map<String, dynamic> filters) {
    final sorted = filters.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    return sorted.map((e) => '${e.key}=${e.value.toString()}').join('&');
  }

  /// Runs [operation], deduplicating concurrent calls with the same [key].
  Future<T> _dedupe<T>(String key, Future<T> Function() operation) {
    final existing = _inFlight[key];
    if (existing != null) {
      AppLogger.debug('Deduping in-flight request: $key');
      return existing as Future<T>;
    }
    final future = operation();
    _inFlight[key] = future;
    future.whenComplete(() {
      // Only remove if this exact future is still registered.
      if (identical(_inFlight[key], future)) {
        _inFlight.remove(key);
      }
    });
    return future;
  }

  /// Background refresh for stale-while-revalidate pattern
  Future<void> _refreshExploreInBackground(
    double lat,
    double lng,
    String? cursor,
    int limit,
    double radiusKm,
    Map<String, dynamic> filters,
  ) async {
    try {
      if (Get.isRegistered<ConnectivityService>() &&
          !Get.find<ConnectivityService>().isCurrentlyOnline) {
        return;
      }
      final response = await _provider.explore(
        lat: lat,
        lng: lng,
        cursor: cursor,
        limit: limit,
        radiusKm: radiusKm,
        filters: filters,
      );
      await _cacheService?.cacheExploreResults(
        response,
        lat: lat,
        lng: lng,
        cursor: cursor,
      );
    } catch (e) {
      AppLogger.warning('Background refresh failed: $e');
    }
  }

  Future<Property> getDetails(int id, {bool forceRefresh = false}) {
    return _dedupe('details|$id', () => _getDetails(id, forceRefresh));
  }

  Future<Property> _getDetails(int id, bool forceRefresh) async {
    // Try cache first
    final cache = _cache();
    if (!forceRefresh && cache != null) {
      final cached = cache.getCachedPropertyDetails(id);
      if (cached != null) {
        AppLogger.info('Returning cached property details for ID $id');
        // Refresh in background
        unawaited(_refreshDetailsInBackground(id));
        return cached;
      }
    }

    final property = await _provider.getDetails(id);
    unawaited(cache?.cachePropertyDetails(property));
    return property;
  }

  Future<void> _refreshDetailsInBackground(int id) async {
    try {
      if (Get.isRegistered<ConnectivityService>() &&
          !Get.find<ConnectivityService>().isCurrentlyOnline) {
        return;
      }
      final property = await _provider.getDetails(id);
      await _cache()?.cachePropertyDetails(property);
    } catch (e) {
      AppLogger.warning('Background details refresh failed: $e');
    }
  }

  Future<List<Property>> recommendations({
    int limit = 10,
    bool forceRefresh = false,
  }) {
    return _dedupe(
      'recommendations|$limit',
      () => _recommendations(limit, forceRefresh),
    );
  }

  Future<List<Property>> _recommendations(int limit, bool forceRefresh) async {
    // Try cache first
    final cache = _cache();
    if (!forceRefresh && cache != null) {
      final cached = cache.getCachedRecommendations();
      if (cached != null) {
        AppLogger.info('Returning cached recommendations');
        unawaited(_refreshRecommendationsInBackground(limit));
        return cached;
      }
    }

    final properties = await _provider.recommendations(limit: limit);
    unawaited(cache?.cacheRecommendations(properties));
    return properties;
  }

  Future<void> _refreshRecommendationsInBackground(int limit) async {
    try {
      if (Get.isRegistered<ConnectivityService>() &&
          !Get.find<ConnectivityService>().isCurrentlyOnline) {
        return;
      }
      final properties = await _provider.recommendations(limit: limit);
      await _cache()?.cacheRecommendations(properties);
    } catch (e) {
      AppLogger.warning('Background recommendations refresh failed: $e');
    }
  }

  /// Get cached data when offline (ignores expiry)
  UnifiedPropertyResponse? getOfflineExploreResults({
    double? lat,
    double? lng,
    String? cursor,
  }) {
    return _cache()?.getCachedExploreResults(
      lat: lat,
      lng: lng,
      cursor: cursor,
      ignoreExpiry: true,
    );
  }

  /// Get cached property details when offline
  Property? getOfflinePropertyDetails(int id) {
    return _cache()?.getCachedPropertyDetails(id, ignoreExpiry: true);
  }

  /// Clear all cached data
  Future<void> clearCache() async {
    await _cache()?.clearAll();
  }
}
