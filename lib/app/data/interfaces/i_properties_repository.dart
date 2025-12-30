import '../models/property_model.dart';
import '../models/unified_filter_model.dart';

/// Property review information
class PropertyReview {
  final int id;
  final int propertyId;
  final int userId;
  final String userName;
  final double rating;
  final String? comment;
  final DateTime createdAt;

  const PropertyReview({
    required this.id,
    required this.propertyId,
    required this.userId,
    required this.userName,
    required this.rating,
    this.comment,
    required this.createdAt,
  }) : assert(rating >= 0.0 && rating <= 5.0, 'Rating must be between 0 and 5');

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PropertyReview &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          propertyId == other.propertyId &&
          userId == other.userId &&
          userName == other.userName &&
          rating == other.rating &&
          comment == other.comment &&
          createdAt == other.createdAt;

  @override
  int get hashCode =>
      id.hashCode ^
      propertyId.hashCode ^
      userId.hashCode ^
      userName.hashCode ^
      rating.hashCode ^
      comment.hashCode ^
      createdAt.hashCode;
}

/// Property pricing information
class PropertyPricing {
  final double basePrice;
  final double totalPrice;
  final double nightlyRate;
  final List<PriceBreakdown> breakdown;
  final String currency;

  const PropertyPricing({
    required this.basePrice,
    required this.totalPrice,
    required this.nightlyRate,
    required this.breakdown,
    required this.currency,
  }) : assert(basePrice >= 0, 'Base price must be non-negative'),
       assert(totalPrice >= 0, 'Total price must be non-negative'),
       assert(nightlyRate >= 0, 'Nightly rate must be non-negative');

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PropertyPricing &&
          runtimeType == other.runtimeType &&
          basePrice == other.basePrice &&
          totalPrice == other.totalPrice &&
          nightlyRate == other.nightlyRate &&
          breakdown == other.breakdown &&
          currency == other.currency;

  @override
  int get hashCode =>
      basePrice.hashCode ^
      totalPrice.hashCode ^
      nightlyRate.hashCode ^
      breakdown.hashCode ^
      currency.hashCode;
}

/// Price breakdown component
class PriceBreakdown {
  final String label;
  final double amount;
  final String type;

  const PriceBreakdown({
    required this.label,
    required this.amount,
    required this.type,
  });
}

/// Pagination result for property listings
class PaginatedProperties {
  final List<Property> properties;
  final int totalCount;
  final int currentPage;
  final int totalPages;

  bool get hasNextPage => currentPage < totalPages;
  bool get hasPreviousPage => currentPage > 1;

  const PaginatedProperties({
    required this.properties,
    required this.totalCount,
    required this.currentPage,
    required this.totalPages,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PaginatedProperties &&
          runtimeType == other.runtimeType &&
          properties.length == other.properties.length &&
          totalCount == other.totalCount &&
          currentPage == other.currentPage &&
          totalPages == other.totalPages;

  @override
  int get hashCode =>
      properties.length.hashCode ^
      totalCount.hashCode ^
      currentPage.hashCode ^
      totalPages.hashCode;
}

/// Property search parameters
class PropertySearchParams {
  final String? query;
  final String? location;
  final UnifiedFilterModel filters;
  final int page;
  final int limit;
  final String? sortBy;
  final bool sortAscending;

  const PropertySearchParams({
    this.query,
    this.location,
    required this.filters,
    this.page = 1,
    this.limit = 20,
    this.sortBy,
    this.sortAscending = true,
  }) : assert(page >= 1, 'Page must be >= 1'),
       assert(limit > 0 && limit <= 100, 'Limit must be between 1 and 100');

  PropertySearchParams copyWith({
    String? query,
    String? location,
    UnifiedFilterModel? filters,
    int? page,
    int? limit,
    String? sortBy,
    bool? sortAscending,
  }) {
    return PropertySearchParams(
      query: query ?? this.query,
      location: location ?? this.location,
      filters: filters ?? this.filters,
      page: page ?? this.page,
      limit: limit ?? this.limit,
      sortBy: sortBy ?? this.sortBy,
      sortAscending: sortAscending ?? this.sortAscending,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PropertySearchParams &&
          runtimeType == other.runtimeType &&
          query == other.query &&
          location == other.location &&
          filters == other.filters &&
          page == other.page &&
          limit == other.limit &&
          sortBy == other.sortBy &&
          sortAscending == other.sortAscending;

  @override
  int get hashCode =>
      query.hashCode ^
      location.hashCode ^
      filters.hashCode ^
      page.hashCode ^
      limit.hashCode ^
      sortBy.hashCode ^
      sortAscending.hashCode;
}

/// Interface for properties repository operations
abstract class IPropertiesRepository {
  /// Get popular/featured properties
  Future<List<Property>> getPopularProperties({int limit = 10});

  /// Get properties near a location
  Future<List<Property>> getNearbyProperties({
    required double latitude,
    required double longitude,
    double radiusKm = 50.0,
    int limit = 20,
  });

  /// Search properties with filters
  Future<PaginatedProperties> searchProperties(PropertySearchParams params);

  /// Get property details by ID
  Future<Property?> getPropertyById(int id);

  /// Get similar properties to a given property
  Future<List<Property>> getSimilarProperties({
    required int propertyId,
    int limit = 5,
  });

  /// Get recently viewed properties
  Future<List<Property>> getRecentlyViewedProperties({int limit = 10});

  /// Add property to recently viewed
  Future<void> addToRecentlyViewed(int propertyId);

  /// Get properties by host ID
  Future<List<Property>> getPropertiesByHost(int hostId);

  /// Save property
  Future<bool> saveProperty(int propertyId);

  /// Unsave property
  Future<bool> unsaveProperty(int propertyId);

  /// Check if property is saved
  Future<bool> isPropertySaved(int propertyId);

  /// Get saved properties
  Future<List<Property>> getSavedProperties({int limit = 20});

  /// Rate a property
  Future<bool> rateProperty({
    required int propertyId,
    required double rating,
    String? review,
  });

  /// Get property reviews
  Future<List<PropertyReview>> getPropertyReviews(
    int propertyId, {
    int page = 1,
    int limit = 10,
  });

  /// Check property availability
  Future<List<DateTime>> getAvailableDates({
    required int propertyId,
    required DateTime startDate,
    required DateTime endDate,
  });

  /// Get property pricing for dates
  Future<PropertyPricing> getPropertyPricing({
    required int propertyId,
    required DateTime startDate,
    required DateTime endDate,
  });
}
