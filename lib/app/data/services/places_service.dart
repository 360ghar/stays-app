import 'package:dio/dio.dart';
import 'package:stays_app/config/app_config.dart';
import 'package:stays_app/app/utils/logger/app_logger.dart';

class PlacePrediction {
  final String description;
  final String placeId;
  const PlacePrediction({required this.description, required this.placeId});
}

class PlaceDetailsResult {
  final double lat;
  final double lng;
  final String name; // formatted address or name
  const PlaceDetailsResult({
    required this.lat,
    required this.lng,
    required this.name,
  });
}

class PlacesService {
  final Dio _dio;
  PlacesService({Dio? dio}) : _dio = dio ?? Dio();

  String get _apiKey =>
      AppConfig.I.googleMapsApiKey ?? 'YOUR_GOOGLE_MAPS_API_KEY';

  Future<List<PlacePrediction>> autocomplete(
    String input, {
    double? lat,
    double? lng,
  }) async {
    if (input.trim().isEmpty) return [];
    try {
      final params = {
        'input': input,
        'key': _apiKey,
        'types': 'geocode',
        // Optional biasing around a location for better suggestions
        if (lat != null && lng != null) 'location': '$lat,$lng',
        if (lat != null && lng != null) 'radius': '20000', // 20km bias
      };
      final res = await _dio.get(
        'https://maps.googleapis.com/maps/api/place/autocomplete/json',
        queryParameters: params,
      );
      if (res.data is! Map) return [];
      final data = res.data as Map;
      final status = data['status'] as String? ?? '';
      if (status != 'OK' && status != 'ZERO_RESULTS') {
        AppLogger.warning('Places autocomplete status: $status');
      }
      final preds = (data['predictions'] as List? ?? []);
      return preds
          .map((e) {
            final m = Map<String, dynamic>.from(e);
            return PlacePrediction(
              description: (m['description'] as String?) ?? '',
              placeId: (m['place_id'] as String?) ?? '',
            );
          })
          .where((p) => p.placeId.isNotEmpty && p.description.isNotEmpty)
          .toList();
    } catch (e) {
      AppLogger.error('Places autocomplete failed', e);
      return [];
    }
  }

  Future<PlaceDetailsResult?> details(String placeId) async {
    if (placeId.isEmpty) return null;
    try {
      final res = await _dio.get(
        'https://maps.googleapis.com/maps/api/place/details/json',
        queryParameters: {
          'place_id': placeId,
          'fields': 'geometry/location,name,formatted_address',
          'key': _apiKey,
        },
      );
      if (res.data is! Map) return null;
      final data = res.data as Map;
      final status = data['status'] as String? ?? '';
      if (status != 'OK') {
        AppLogger.warning('Place details status: $status');
        return null;
      }
      final result = Map<String, dynamic>.from(data['result']);
      final geometry = Map<String, dynamic>.from(result['geometry']);
      final location = Map<String, dynamic>.from(geometry['location']);
      final lat = (location['lat'] as num?)?.toDouble();
      final lng = (location['lng'] as num?)?.toDouble();
      if (lat == null || lng == null) return null;
      final name =
          (result['formatted_address'] as String?) ??
          (result['name'] as String? ?? 'Selected location');
      return PlaceDetailsResult(lat: lat, lng: lng, name: name);
    } catch (e) {
      AppLogger.error('Place details failed', e);
      return null;
    }
  }
}
