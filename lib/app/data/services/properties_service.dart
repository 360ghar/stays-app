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
      
      if (response.body == null) {
        return [];
      }
      
      final List<dynamic> data = response.body['data']?['properties'] ?? [];
      return data.map((json) => Property.fromJson(json)).toList();

    } catch (e) {
      AppLogger.error('Error fetching listings', e);
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
      
      if (response.body == null) {
        return [];
      }
      
      final List<dynamic> data = response.body['data']?['properties'] ?? [];
      return data.map((json) => Property.fromJson(json)).toList();

    } catch (e) {
      AppLogger.error('Error fetching properties', e);
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
        final responseData = response.body;
        final List<dynamic> data = responseData is Map<String, dynamic> 
            ? responseData['properties'] ?? []
            : responseData is List ? responseData : [];
        
        return data.map((json) => Property.fromJson(json)).toList();
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
        final responseData = response.body;
        final List<dynamic> data = responseData is Map<String, dynamic> 
            ? responseData['properties'] ?? []
            : responseData is List ? responseData : [];
        
        return data.map((json) => Property.fromJson(json)).toList();
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
        final responseData = response.body;
        final List<dynamic> data = responseData is Map<String, dynamic> 
            ? responseData['properties'] ?? []
            : responseData is List ? responseData : [];
        
        return data.map((json) => Property.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load recommendations');
      }
    } catch (e) {
      AppLogger.error('Error fetching recommended properties', e);
      rethrow;
    }
  }
}