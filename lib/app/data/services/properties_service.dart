import 'package:get/get.dart';
import 'package:stays_app/app/data/models/property_model.dart';
import 'package:stays_app/app/data/services/api_service.dart';
import 'package:stays_app/app/utils/logger/app_logger.dart';

class PropertiesService extends GetxService {
  // No longer 'late'! It's provided in the constructor.
  final ApiService _apiService;
  
  // Constructor to accept the dependency
  PropertiesService(this._apiService);

  // The init method is now simpler
  Future<PropertiesService> init() async {
    // Nothing to do here anymore, but we keep it for consistency with Get.putAsync
    return this;
  }

  /// Robust helper to safely parse properties list from any response format
  List<Property> _parsePropertiesList(dynamic responseBody, String context) {
    if (responseBody == null) {
      AppLogger.warning('Null response body for $context');
      return [];
    }

    try {
      List<dynamic> items = [];
      
      if (responseBody is Map<String, dynamic>) {
        // Try nested data.properties first
        final data = responseBody['data'];
        if (data is Map<String, dynamic>) {
          final props = data['properties'];
          if (props is List) {
            items = props;
          } else if (props != null) {
            AppLogger.warning('Expected List for data.properties in $context, got ${props.runtimeType}: $props');
            return [];
          }
        }
        
        // Try direct properties if no nested data
        if (items.isEmpty) {
          final props = responseBody['properties'];
          if (props is List) {
            items = props;
          } else if (props != null) {
            AppLogger.warning('Expected List for properties in $context, got ${props.runtimeType}: $props');
            return [];
          }
        }
      } else if (responseBody is List) {
        items = responseBody;
      } else {
        AppLogger.warning('Unexpected response type for $context: ${responseBody.runtimeType}. Value: $responseBody');
        return [];
      }

      if (items.isEmpty) {
        AppLogger.info('Empty properties list for $context');
        return [];
      }

      return items
          .map((json) {
            try {
              if (json is Map<String, dynamic>) {
                return Property.fromJson(json);
              } else {
                AppLogger.warning('Invalid property format in $context: ${json.runtimeType}');
                return null;
              }
            } catch (e) {
              AppLogger.error('Failed to parse property in $context', e);
              return null;
            }
          })
          .whereType<Property>()
          .toList();
    } catch (e) {
      AppLogger.error('Error parsing properties list for $context', e);
      return [];
    }
  }

  // CORRESPONDS TO: GET /properties
  Future<List<Property>> getListings({
    String? location,
    String? propertyType,
    int? page,
    int? limit,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'purpose': 'short_stay' // Hardcoded as per app requirement
      };
      
      if (location != null) queryParams['location'] = location;
      if (propertyType != null) queryParams['propertyType'] = propertyType;
      if (page != null) queryParams['page'] = page;
      if (limit != null) queryParams['limit'] = limit;

      final response = await _apiService.get(
        '/properties',
        query: queryParams,
      );
      
      return _parsePropertiesList(response.body, 'getListings');

    } catch (e, stackTrace) {
      AppLogger.error('Error fetching listings', e, stackTrace);
      rethrow;
    }
  }

  // Generic method to get properties with filters
  Future<List<Property>> getProperties({
    String? propertyType,
    String? city,
    String? country,
    double? minPrice,
    double? maxPrice,
    int? page,
    int? limit,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      
      if (propertyType != null) queryParams['propertyType'] = propertyType;
      if (city != null) queryParams['city'] = city;
      if (country != null) queryParams['country'] = country;
      if (minPrice != null) queryParams['minPrice'] = minPrice;
      if (maxPrice != null) queryParams['maxPrice'] = maxPrice;
      if (page != null) queryParams['page'] = page;
      if (limit != null) queryParams['limit'] = limit;

      final response = await _apiService.get(
        '/properties',
        query: queryParams,
      );
      
      return _parsePropertiesList(response.body, 'getProperties');

    } catch (e, stackTrace) {
      AppLogger.error('Error fetching properties', e, stackTrace);
      rethrow;
    }
  }

  // Get short stay properties
  Future<List<Property>> getShortStayProperties({
    String? city,
    String? country,
    double? minPrice,
    double? maxPrice,
    int? page,
    int? limit,
  }) async {
    return getProperties(
      propertyType: 'short_stay',
      city: city,
      country: country,
      minPrice: minPrice,
      maxPrice: maxPrice,
      page: page,
      limit: limit,
    );
  }

  // CORRESPONDS TO: GET /properties/:id
  Future<Property> getPropertyById(String id) async {
    try {
      final response = await _apiService.get('/properties/$id');
      if (response.body == null) {
        throw Exception('Property not found');
      }
      return Property.fromJson(response.body['data']['property']);
    } catch (e) {
      AppLogger.error('Error fetching property by ID', e);
      rethrow;
    }
  }

  // Search properties
  Future<List<Property>> searchProperties({
    required String query,
    String? propertyType,
    double? minPrice,
    double? maxPrice,
    List<String>? amenities,
    double? minRating,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'search': query,
      };
      
      if (propertyType != null) queryParams['propertyType'] = propertyType;
      if (minPrice != null) queryParams['minPrice'] = minPrice;
      if (maxPrice != null) queryParams['maxPrice'] = maxPrice;
      if (amenities != null && amenities.isNotEmpty) {
        queryParams['amenities'] = amenities.join(',');
      }
      if (minRating != null) queryParams['minRating'] = minRating;

      final response = await _apiService.get(
        '/listings/search',
        query: queryParams,
      );

      if (response.statusCode == 200) {
        return _parsePropertiesList(response.body, 'searchProperties');
      } else {
        throw Exception('Search failed');
      }
    } catch (e) {
      AppLogger.error('Error searching properties', e);
      rethrow;
    }
  }

  // Get nearby properties based on coordinates
  Future<List<Property>> getNearbyProperties({
    required double latitude,
    required double longitude,
    double radiusKm = 10,
    String? propertyType,
    int? limit,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'lat': latitude,
        'lng': longitude,
        'radius': radiusKm,
      };
      
      if (propertyType != null) queryParams['propertyType'] = propertyType;
      if (limit != null) queryParams['limit'] = limit;

      final response = await _apiService.get(
        '/listings/nearby',
        query: queryParams,
      );

      if (response.statusCode == 200) {
        return _parsePropertiesList(response.body, 'getNearbyProperties');
      } else {
        throw Exception('Failed to load nearby properties');
      }
    } catch (e) {
      AppLogger.error('Error fetching nearby properties', e);
      rethrow;
    }
  }

  // Get recommended properties
  Future<List<Property>> getRecommendedProperties({
    String? userId,
    int? limit,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      
      if (userId != null) queryParams['userId'] = userId;
      if (limit != null) queryParams['limit'] = limit;

      final response = await _apiService.get(
        '/listings/recommended',
        query: queryParams,
      );

      if (response.statusCode == 200) {
        return _parsePropertiesList(response.body, 'getRecommendedProperties');
      } else {
        throw Exception('Failed to load recommendations');
      }
    } catch (e) {
      AppLogger.error('Error fetching recommended properties', e);
      rethrow;
    }
  }
}
