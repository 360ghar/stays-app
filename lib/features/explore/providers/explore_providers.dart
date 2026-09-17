import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart' hide Response;

import 'package:stays_app/app/controllers/favorites_controller.dart';
import 'package:stays_app/app/data/models/property_model.dart';
import 'package:stays_app/app/data/repositories/properties_repository.dart';
import 'package:stays_app/app/data/repositories/wishlist_repository.dart';
import 'package:stays_app/app/data/services/location_service.dart';
import 'package:stays_app/app/utils/logger/app_logger.dart';

// ---------------------------------------------------------------------------
// Pure helpers (unit-testable, no GetX / no Flutter)
// ---------------------------------------------------------------------------

String normalizeCity(String value) => value.toLowerCase().trim();

String greetingFor(DateTime now) {
  final hour = now.hour;
  if (hour < 12) return 'Good morning';
  if (hour < 17) return 'Good afternoon';
  return 'Good evening';
}

Property? nearestOf(List<Property> props) {
  Property? nearest;
  double minDistance = double.infinity;
  for (final property in props) {
    final distance = property.distanceKm;
    if (distance != null && distance < minDistance) {
      minDistance = distance;
      nearest = property;
    }
  }
  return nearest;
}

({List<Property> inCity, List<Property> nearby}) partitionExplore(
  List<Property> props,
  String selectedCity,
) {
  final target = normalizeCity(selectedCity);
  final inCity = <Property>[];
  final nearby = <Property>[];
  for (final property in props) {
    if (normalizeCity(property.city) == target) {
      inCity.add(property);
    } else {
      nearby.add(property);
    }
  }
  int byDistance(Property a, Property b) {
    final da = a.distanceKm ?? double.maxFinite;
    final db = b.distanceKm ?? double.maxFinite;
    return da.compareTo(db);
  }

  inCity.sort(byDistance);
  nearby.sort(byDistance);
  return (inCity: inCity, nearby: nearby);
}

// ---------------------------------------------------------------------------
// UI state
// ---------------------------------------------------------------------------

class ExploreUiState {
  const ExploreUiState({
    this.popular = const [],
    this.nearby = const [],
    this.isLoading = true,
    this.error = '',
    this.isOffline = false,
    this.showingCached = false,
    this.locationName = '',
    this.city = '',
  });
  final List<Property> popular;
  final List<Property> nearby;
  final bool isLoading;
  final String error;
  final bool isOffline;
  final bool showingCached;
  final String locationName;
  final String city;

  Property? get featured => nearestOf([...popular, ...nearby]);

  List<Property> get popularExcludingFeatured {
    final featuredId = featured?.id;
    if (featuredId == null) return popular;
    return popular.where((p) => p.id != featuredId).toList();
  }

  List<Property> get nearbyExcludingFeatured {
    final featuredId = featured?.id;
    if (featuredId == null) return nearby;
    return nearby.where((p) => p.id != featuredId).toList();
  }

  ExploreUiState copyWith({
    List<Property>? popular,
    List<Property>? nearby,
    bool? isLoading,
    String? error,
    bool? isOffline,
    bool? showingCached,
    String? locationName,
    String? city,
  }) {
    return ExploreUiState(
      popular: popular ?? this.popular,
      nearby: nearby ?? this.nearby,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      isOffline: isOffline ?? this.isOffline,
      showingCached: showingCached ?? this.showingCached,
      locationName: locationName ?? this.locationName,
      city: city ?? this.city,
    );
  }
}

// ---------------------------------------------------------------------------
// Notifier (strangler: reads legacy GetX services until Phase 3)
// ---------------------------------------------------------------------------

final exploreProvider = NotifierProvider<ExploreNotifier, ExploreUiState>(
  ExploreNotifier.new,
);

class ExploreNotifier extends Notifier<ExploreUiState> {
  @override
  ExploreUiState build() {
    unawaited(Future(() => refresh()));
    return const ExploreUiState();
  }

  PropertiesRepository? get _repo => Get.isRegistered<PropertiesRepository>()
      ? Get.find<PropertiesRepository>()
      : null;

  LocationService? get _location =>
      Get.isRegistered<LocationService>() ? Get.find<LocationService>() : null;

  FavoritesController? get _favorites => Get.isRegistered<FavoritesController>()
      ? Get.find<FavoritesController>()
      : null;

  WishlistRepository? get _wishlist => Get.isRegistered<WishlistRepository>()
      ? Get.find<WishlistRepository>()
      : null;

  String get _selectedCity {
    final location = _location;
    if (location == null) return '';
    final city = location.currentCity.isNotEmpty
        ? location.currentCity
        : location.locationName.split(',').last;
    return city.trim();
  }

  Future<void> refresh() async {
    state = state.copyWith(isLoading: true, error: '');
    final repo = _repo;
    if (repo == null) {
      state = state.copyWith(
        isLoading: false,
        error: 'Still starting up. Pull to retry.',
      );
      return;
    }
    try {
      final resp = await repo.explore(limit: 30, radiusKm: 100);
      _applyProps(resp.items, cached: false);
    } catch (e, s) {
      AppLogger.error('Explore v2: load failed', e, s);
      final cached = _cachedFallback();
      if (cached != null && cached.isNotEmpty) {
        _applyProps(cached, cached: true);
        state = state.copyWith(
          error: 'Could not refresh. Showing saved stays.',
        );
        return;
      }
      state = state.copyWith(
        isLoading: false,
        error: 'Unable to load stays. Pull down to retry.',
        isOffline: true,
      );
    }
  }

  List<Property>? _cachedFallback() {
    try {
      final location = _location;
      return _repo
          ?.getOfflineExploreResults(
            lat: location?.latitude,
            lng: location?.longitude,
          )
          ?.items;
    } catch (_) {
      return null;
    }
  }

  void _applyProps(List<Property> props, {required bool cached}) {
    final favorites = _favorites;
    if (favorites != null) {
      favorites.addAll(
        props.where((p) => p.isFavorite || p.liked == true).map((p) => p.id),
      );
    }
    final parts = partitionExplore(props, _selectedCity);
    final location = _location;
    state = ExploreUiState(
      popular: parts.inCity,
      nearby: parts.nearby,
      isLoading: false,
      showingCached: cached,
      locationName: location?.locationName ?? '',
      city: _selectedCity,
    );
  }

  Future<void> useMyLocation() async {
    final location = _location;
    if (location == null) return;
    state = state.copyWith(isLoading: true);
    try {
      location.clearSelectedLocation();
      await location.updateLocation(ensurePrecise: true);
    } catch (e) {
      AppLogger.error('Explore v2: location failed', e);
    }
    await refresh();
  }

  bool isFavorite(int id) => _favorites?.isFavorite(id) ?? false;

  Future<void> toggleFavorite(Property property) async {
    final favorites = _favorites;
    final wishlist = _wishlist;
    final nowFavorite = favorites?.isFavorite(property.id) ?? false;
    _setLocalFavorite(property.id, !nowFavorite);
    if (favorites == null || wishlist == null) return;
    try {
      if (nowFavorite) {
        favorites.removeFavorite(property.id);
        await wishlist.remove(property.id);
      } else {
        favorites.addFavorite(property.id);
        await wishlist.add(property.id);
      }
    } catch (e) {
      AppLogger.error('Explore v2: favorite toggle failed', e);
      _setLocalFavorite(property.id, nowFavorite);
    }
  }

  void _setLocalFavorite(int id, bool favorite) {
    List<Property> mark(List<Property> list) => list
        .map((p) => p.id == id ? p.copyWith(isFavorite: favorite) : p)
        .toList();
    state = state.copyWith(
      popular: mark(state.popular),
      nearby: mark(state.nearby),
    );
  }
}
