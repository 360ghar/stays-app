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
  final PropertiesProvider _provider;
  PropertyCacheService? _cacheService;

  PropertiesRepository({required PropertiesProvider provider})
    : _provider = provider {
    _initCache();
  }

  void _initCache() {
    if (Get.isRegistered<PropertyCacheService>()) {
      _cacheService = Get.find<PropertyCacheService>();
    }
  }

  Future<UnifiedPropertyResponse> explore({
    double? lat,
    double? lng,
    int page = 1,
    int limit = 20,
    double radiusKm = 10,
    Map<String, dynamic>? filters,
    bool forceRefresh = false,
  }) async {
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
    final queryFilters = <String, dynamic>{...?filters}
      ..removeWhere((key, value) => value == null);
    queryFilters.putIfAbsent('purpose', () => 'short_stay');

    // Try cache first if not forcing refresh
    if (!forceRefresh && _cacheService != null) {
      final cached = _cacheService!.getCachedExploreResults(
        lat: la,
        lng: ln,
        page: page,
      );
      if (cached != null) {
        AppLogger.info('Returning cached explore results for page $page');
        // Fetch fresh data in background (stale-while-revalidate)
        unawaited(
          _refreshExploreInBackground(
            la,
            ln,
            page,
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
      page: page,
      limit: limit,
      radiusKm: radiusKm,
      filters: queryFilters,
    );

    // Cache the response
    unawaited(
      _cacheService?.cacheExploreResults(
        response,
        lat: la,
        lng: ln,
        page: page,
      ),
    );

    return response;
  }

  /// Background refresh for stale-while-revalidate pattern
  Future<void> _refreshExploreInBackground(
    double lat,
    double lng,
    int page,
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
        page: page,
        limit: limit,
        radiusKm: radiusKm,
        filters: filters,
      );
      await _cacheService?.cacheExploreResults(
        response,
        lat: lat,
        lng: lng,
        page: page,
      );
    } catch (e) {
      AppLogger.warning('Background refresh failed: $e');
    }
  }

  Future<Property> getDetails(int id, {bool forceRefresh = false}) async {
    // Try cache first
    if (!forceRefresh && _cacheService != null) {
      final cached = _cacheService!.getCachedPropertyDetails(id);
      if (cached != null) {
        AppLogger.info('Returning cached property details for ID $id');
        // Refresh in background
        unawaited(_refreshDetailsInBackground(id));
        return cached;
      }
    }

    final property = await _provider.getDetails(id);
    unawaited(_cacheService?.cachePropertyDetails(property));
    return property;
  }

  Future<void> _refreshDetailsInBackground(int id) async {
    try {
      if (Get.isRegistered<ConnectivityService>() &&
          !Get.find<ConnectivityService>().isCurrentlyOnline) {
        return;
      }
      final property = await _provider.getDetails(id);
      await _cacheService?.cachePropertyDetails(property);
    } catch (e) {
      AppLogger.warning('Background details refresh failed: $e');
    }
  }

  Future<List<Property>> recommendations({
    int limit = 10,
    bool forceRefresh = false,
  }) async {
    // Try cache first
    if (!forceRefresh && _cacheService != null) {
      final cached = _cacheService!.getCachedRecommendations();
      if (cached != null) {
        AppLogger.info('Returning cached recommendations');
        unawaited(_refreshRecommendationsInBackground(limit));
        return cached;
      }
    }

    final properties = await _provider.recommendations(limit: limit);
    unawaited(_cacheService?.cacheRecommendations(properties));
    return properties;
  }

  Future<void> _refreshRecommendationsInBackground(int limit) async {
    try {
      if (Get.isRegistered<ConnectivityService>() &&
          !Get.find<ConnectivityService>().isCurrentlyOnline) {
        return;
      }
      final properties = await _provider.recommendations(limit: limit);
      await _cacheService?.cacheRecommendations(properties);
    } catch (e) {
      AppLogger.warning('Background recommendations refresh failed: $e');
    }
  }

  /// Get cached data when offline (ignores expiry)
  UnifiedPropertyResponse? getOfflineExploreResults({
    double? lat,
    double? lng,
    int page = 1,
  }) {
    return _cacheService?.getCachedExploreResults(
      lat: lat,
      lng: lng,
      page: page,
      ignoreExpiry: true,
    );
  }

  /// Get cached property details when offline
  Property? getOfflinePropertyDetails(int id) {
    return _cacheService?.getCachedPropertyDetails(id, ignoreExpiry: true);
  }

  /// Clear all cached data
  Future<void> clearCache() async {
    await _cacheService?.clearAll();
  }
}
