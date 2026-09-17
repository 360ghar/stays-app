import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart' hide Response;

import 'package:stays_app/app/data/models/property_model.dart';
import 'package:stays_app/app/data/repositories/properties_repository.dart';
import 'package:stays_app/app/data/services/location_service.dart';
import 'package:stays_app/app/data/services/places_service.dart';
import 'package:stays_app/app/utils/logger/app_logger.dart';

class SearchUiState {
  const SearchUiState({
    this.query = '',
    this.predictions = const [],
    this.isSearching = false,
  });
  final String query;
  final List<PlacePrediction> predictions;
  final bool isSearching;

  SearchUiState copyWith({
    String? query,
    List<PlacePrediction>? predictions,
    bool? isSearching,
  }) {
    return SearchUiState(
      query: query ?? this.query,
      predictions: predictions ?? this.predictions,
      isSearching: isSearching ?? this.isSearching,
    );
  }
}

final searchProvider =
    NotifierProvider.autoDispose<SearchNotifier, SearchUiState>(
      SearchNotifier.new,
    );

class SearchNotifier extends AutoDisposeNotifier<SearchUiState> {
  Timer? _debounce;

  @override
  SearchUiState build() {
    ref.onDispose(() => _debounce?.cancel());
    return const SearchUiState();
  }

  PlacesService? get _places =>
      Get.isRegistered<PlacesService>() ? Get.find<PlacesService>() : null;

  LocationService? get _location =>
      Get.isRegistered<LocationService>() ? Get.find<LocationService>() : null;

  void onQueryChanged(String value) {
    state = state.copyWith(query: value);
    _debounce?.cancel();
    if (value.trim().isEmpty) {
      state = state.copyWith(predictions: const [], isSearching: false);
      return;
    }
    state = state.copyWith(isSearching: true);
    _debounce = Timer(const Duration(milliseconds: 350), () async {
      final places = _places;
      if (places == null) {
        state = state.copyWith(isSearching: false);
        return;
      }
      try {
        final results = await places.autocomplete(
          value,
          lat: _location?.latitude,
          lng: _location?.longitude,
        );
        state = state.copyWith(predictions: results, isSearching: false);
      } catch (e) {
        AppLogger.error('Search v2: autocomplete failed', e);
        state = state.copyWith(predictions: const [], isSearching: false);
      }
    });
  }

  /// Resolves a prediction to coordinates and pins it as the selected
  /// location (mirrors legacy search). Returns null when unavailable.
  Future<PlaceDetailsResult?> selectPrediction(PlacePrediction p) async {
    final places = _places;
    if (places == null) return null;
    try {
      final details = await places.details(p.placeId);
      if (details == null) return null;
      _location?.setSelectedLocation(
        lat: details.lat,
        lng: details.lng,
        locationName: details.name,
      );
      return details;
    } catch (e) {
      AppLogger.error('Search v2: details failed', e);
      return null;
    }
  }
}

final searchResultsProvider = FutureProvider.autoDispose
    .family<List<Property>, ({double lat, double lng})>((ref, args) async {
      if (!Get.isRegistered<PropertiesRepository>()) {
        throw StateError('PropertiesRepository not ready');
      }
      final resp = await Get.find<PropertiesRepository>().explore(
        lat: args.lat,
        lng: args.lng,
        limit: 30,
        radiusKm: 100,
      );
      return resp.items;
    });
