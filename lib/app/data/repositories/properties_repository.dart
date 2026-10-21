import 'dart:async';

import '../providers/properties_provider.dart';
import '../models/property_model.dart';
import '../models/unified_property_response.dart';
import '../models/wire_enums.dart';
import '../services/location_service.dart';
import '../services/property_cache_service.dart';
import '../../utils/logger/app_logger.dart';
import '../../utils/services/connectivity_service.dart';

class PropertiesRepository {
  PropertiesRepository({
    required PropertiesProvider provider,
    PropertyCacheService? cacheService,
    LocationService? locationService,
    ConnectivityService? connectivityService,
  }) : _provider = provider,
       _cacheService = cacheService,
       _locationService = locationService,
       _connectivityService = connectivityService;
  final PropertiesProvider _provider;
  PropertyCacheService? _cacheService;
  final LocationService? _locationService;
  final ConnectivityService? _connectivityService;

  /// In-flight request dedupe: concurrent calls with the same key share one
  /// network request. Entries are removed when the future completes.
  final Map<String, Future<dynamic>> _inFlight = {};

  /// Late-bound cache service for graphs that construct the repository
  /// before the cache finishes initializing.
  // ignore: use_setters_to_change_properties
  void bindCacheService(PropertyCacheService cache) {
    _cacheService ??= cache;
  }

  PropertyCacheService? _cache() => _cacheService;

  Future<UnifiedPropertyResponse> explore({
    double? lat,
    double? lng,
    String? cursor,
    int limit = 20,
    int radiusKm = 10,
    Map<String, dynamic>? filters,
    bool forceRefresh = false,
  }) {
    const defaultLat = 19.0760;
    const defaultLng = 72.8777;

    double? la = lat;
    double? ln = lng;
    final loc = _locationService;
    if ((la == null || ln == null) && loc != null) {
      la ??= loc.latitude;
      ln ??= loc.longitude;
    }
    la ??= defaultLat;
    ln ??= defaultLng;
    final resolvedLat = la;
    final resolvedLng = ln;
    final queryFilters = <String, dynamic>{...?filters}
      ..removeWhere((key, value) => value == null);
    queryFilters.putIfAbsent('purpose', () => PropertyPurpose.shortStay.wire);

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
    int radiusKm,
    Map<String, dynamic> queryFilters,
    bool forceRefresh,
  ) async {
    // A page is cached under the filters, radius and page size it was read
    // with, so a page of one filter set is never served for another.
    final variant = _variant(limit, radiusKm, queryFilters);
    // Try cache first if not forcing refresh
    final cache = _cache();
    if (!forceRefresh && cache != null) {
      final cached = cache.getCachedExploreResults(
        lat: la,
        lng: ln,
        cursor: cursor,
        variant: variant,
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

    final scope = cache?.scope;
    final response = await _provider.explore(
      lat: la,
      lng: ln,
      cursor: cursor,
      limit: limit,
      radiusKm: radiusKm,
      filters: queryFilters,
    );

    // Cache the response. The cache skips a `Cache-Control: no-store` body and
    // a response whose account changed while it was in flight.
    unawaited(
      cache?.cacheExploreResults(
        response,
        lat: la,
        lng: ln,
        cursor: cursor,
        variant: variant,
        scope: scope,
      ),
    );

    return response;
  }

  String _variant(int limit, int radiusKm, Map<String, dynamic> filters) =>
      '$limit|$radiusKm|${_stableFiltersHash(filters)}';

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
    // Clean up regardless of outcome. The derived future's error is handled
    // here (callers await the ORIGINAL future, which still propagates errors);
    // without the onError handler a failed request would produce an unhandled
    // async error on the derived future.
    unawaited(
      future
          .then<void>((_) {}, onError: (Object _, StackTrace _) {})
          .whenComplete(() {
            if (identical(_inFlight[key], future)) {
              unawaited(_inFlight.remove(key));
            }
          }),
    );
    return future;
  }

  /// Background refresh for stale-while-revalidate pattern
  Future<void> _refreshExploreInBackground(
    double lat,
    double lng,
    String? cursor,
    int limit,
    int radiusKm,
    Map<String, dynamic> filters,
  ) async {
    try {
      final connectivity = _connectivityService;
      if (connectivity != null && !connectivity.isCurrentlyOnline) {
        return;
      }
      final scope = _cacheService?.scope;
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
        variant: _variant(limit, radiusKm, filters),
        scope: scope,
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

    final scope = cache?.scope;
    final result = await _provider.getDetails(id);
    unawaited(
      cache?.cachePropertyDetails(
        result.property,
        noStore: result.noStore,
        scope: scope,
      ),
    );
    return result.property;
  }

  Future<void> _refreshDetailsInBackground(int id) async {
    try {
      final connectivity = _connectivityService;
      if (connectivity != null && !connectivity.isCurrentlyOnline) {
        return;
      }
      final scope = _cache()?.scope;
      final result = await _provider.getDetails(id);
      await _cache()?.cachePropertyDetails(
        result.property,
        noStore: result.noStore,
        scope: scope,
      );
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

    final scope = cache?.scope;
    final response = await _provider.recommendations(limit: limit);
    unawaited(
      cache?.cacheRecommendations(
        response.items,
        noStore: response.noStore,
        scope: scope,
      ),
    );
    return response.items;
  }

  Future<void> _refreshRecommendationsInBackground(int limit) async {
    try {
      final connectivity = _connectivityService;
      if (connectivity != null && !connectivity.isCurrentlyOnline) {
        return;
      }
      final scope = _cache()?.scope;
      final response = await _provider.recommendations(limit: limit);
      await _cache()?.cacheRecommendations(
        response.items,
        noStore: response.noStore,
        scope: scope,
      );
    } catch (e) {
      AppLogger.warning('Background recommendations refresh failed: $e');
    }
  }

  /// Get cached data when offline (ignores expiry)
  UnifiedPropertyResponse? getOfflineExploreResults({
    double? lat,
    double? lng,
    String? cursor,
    int limit = 20,
    int radiusKm = 10,
    Map<String, dynamic>? filters,
  }) {
    final queryFilters = <String, dynamic>{...?filters}
      ..removeWhere((key, value) => value == null);
    queryFilters.putIfAbsent('purpose', () => PropertyPurpose.shortStay.wire);
    return _cache()?.getCachedExploreResults(
      lat: lat,
      lng: lng,
      cursor: cursor,
      variant: _variant(limit, radiusKm, queryFilters),
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
