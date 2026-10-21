import 'property_model.dart';
import 'wire_enums.dart';

/// Immutable filter state that can be shared across multiple property flows.
///
/// Every field maps to a query key that `GET /api/v1/properties` declares.
/// The backend answers 422 to a key it does not declare, so a filter the
/// backend has no key for (rating, instant book, self check-in, pets,
/// smoking) is not part of this model.
class UnifiedFilterModel {
  UnifiedFilterModel({
    this.minPrice,
    this.maxPrice,
    List<PropertyType>? propertyTypes,
    this.minBedrooms,
    this.maxBedrooms,
    this.minBathrooms,
    this.maxBathrooms,
    this.sortBy,
    this.city,
    this.radiusKm,
  }) : propertyTypes = propertyTypes == null
           ? const []
           : List.unmodifiable(propertyTypes);
  final double? minPrice;
  final double? maxPrice;
  final List<PropertyType> propertyTypes;
  final int? minBedrooms;
  final int? maxBedrooms;
  final int? minBathrooms;
  final int? maxBathrooms;

  /// One of the backend `SortBy` values.
  final SortBy? sortBy;
  final String? city;

  /// Search radius in whole kilometres, 1 to 100 (`radius` is an integer).
  final int? radiusKm;

  static final UnifiedFilterModel empty = UnifiedFilterModel();

  bool get isEmpty => !isNotEmpty;
  bool get isNotEmpty =>
      minPrice != null ||
      maxPrice != null ||
      propertyTypes.isNotEmpty ||
      minBedrooms != null ||
      maxBedrooms != null ||
      minBathrooms != null ||
      maxBathrooms != null ||
      sortBy != null ||
      (city != null && city!.trim().isNotEmpty) ||
      radiusKm != null;

  UnifiedFilterModel copyWith({
    double? minPrice,
    double? maxPrice,
    List<PropertyType>? propertyTypes,
    int? minBedrooms,
    int? maxBedrooms,
    int? minBathrooms,
    int? maxBathrooms,
    SortBy? sortBy,
    String? city,
    int? radiusKm,
  }) {
    return UnifiedFilterModel(
      minPrice: minPrice ?? this.minPrice,
      maxPrice: maxPrice ?? this.maxPrice,
      propertyTypes: propertyTypes ?? this.propertyTypes,
      minBedrooms: minBedrooms ?? this.minBedrooms,
      maxBedrooms: maxBedrooms ?? this.maxBedrooms,
      minBathrooms: minBathrooms ?? this.minBathrooms,
      maxBathrooms: maxBathrooms ?? this.maxBathrooms,
      sortBy: sortBy ?? this.sortBy,
      city: city ?? this.city,
      radiusKm: radiusKm ?? this.radiusKm,
    );
  }

  UnifiedFilterModel merge(UnifiedFilterModel other) {
    if (identical(this, other)) return this;
    return UnifiedFilterModel(
      minPrice: other.minPrice ?? minPrice,
      maxPrice: other.maxPrice ?? maxPrice,
      propertyTypes: other.propertyTypes.isNotEmpty
          ? other.propertyTypes
          : propertyTypes,
      minBedrooms: other.minBedrooms ?? minBedrooms,
      maxBedrooms: other.maxBedrooms ?? maxBedrooms,
      minBathrooms: other.minBathrooms ?? minBathrooms,
      maxBathrooms: other.maxBathrooms ?? maxBathrooms,
      sortBy: other.sortBy ?? sortBy,
      city: other.city ?? city,
      radiusKm: other.radiusKm ?? radiusKm,
    );
  }

  Map<String, dynamic> toJson() => toQueryParameters();

  /// Query keys for `GET /api/v1/properties`. A list value stays a list: it is
  /// sent as repeated keys (`property_type=villa&property_type=house`).
  Map<String, dynamic> toQueryParameters() => {
    if (minPrice != null) 'price_min': minPrice,
    if (maxPrice != null) 'price_max': maxPrice,
    if (propertyTypes.isNotEmpty)
      'property_type': [for (final type in propertyTypes) type.wire],
    if (minBedrooms != null) 'bedrooms_min': minBedrooms,
    if (maxBedrooms != null) 'bedrooms_max': maxBedrooms,
    if (minBathrooms != null) 'bathrooms_min': minBathrooms,
    if (maxBathrooms != null) 'bathrooms_max': maxBathrooms,
    if (sortBy != null) 'sort_by': sortBy!.wire,
    if (city != null && city!.trim().isNotEmpty) 'city': city,
    if (radiusKm != null) 'radius': radiusKm!.clamp(1, 100),
  };

  bool matchesProperty(Property property) {
    final price = property.pricePerNight;
    if (minPrice != null && (price == null || price < minPrice!)) {
      return false;
    }
    if (maxPrice != null && (price == null || price > maxPrice!)) {
      return false;
    }
    if (propertyTypes.isNotEmpty &&
        !propertyTypes.contains(property.propertyType)) {
      return false;
    }
    if (minBedrooms != null) {
      final bedrooms = property.bedrooms ?? 0;
      if (bedrooms < minBedrooms!) return false;
    }
    if (maxBedrooms != null && property.bedrooms != null) {
      if (property.bedrooms! > maxBedrooms!) return false;
    }
    if (minBathrooms != null) {
      final baths = property.bathrooms ?? 0;
      if (baths < minBathrooms!) return false;
    }
    if (maxBathrooms != null && property.bathrooms != null) {
      if (property.bathrooms! > maxBathrooms!) return false;
    }
    if (city != null && city!.trim().isNotEmpty) {
      final cityVal = property.city.toLowerCase().trim();
      if (!cityVal.contains(city!.toLowerCase().trim())) return false;
    }
    return true;
  }

  bool matchesBooking(Map<String, dynamic> booking) {
    if (minPrice != null) {
      final amount = (booking['totalAmount'] as num?)?.toDouble() ?? 0;
      if (amount < minPrice!) return false;
    }
    if (maxPrice != null) {
      final amount = (booking['totalAmount'] as num?)?.toDouble() ?? 0;
      if (amount > maxPrice!) return false;
    }
    if (city != null && city!.trim().isNotEmpty) {
      final location = booking['location']?.toString().toLowerCase() ?? '';
      if (!location.contains(city!.toLowerCase().trim())) return false;
    }
    return true;
  }

  List<String> activeTags() {
    final tags = <String>[];
    if (minPrice != null || maxPrice != null) {
      final min = minPrice?.toStringAsFixed(0) ?? '0';
      final max = maxPrice?.toStringAsFixed(0) ?? 'inf';
      tags.add('Rs $min - Rs $max');
    }
    if (propertyTypes.isNotEmpty) {
      tags.addAll(propertyTypes.map((e) => e.wire.replaceAll('_', ' ')));
    }
    if (minBedrooms != null) tags.add('${minBedrooms!}+ beds');
    if (minBathrooms != null) tags.add('${minBathrooms!}+ baths');
    if (city != null && city!.trim().isNotEmpty) tags.add(city!.trim());
    return tags;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! UnifiedFilterModel) return false;
    return minPrice == other.minPrice &&
        maxPrice == other.maxPrice &&
        _listEquals(propertyTypes, other.propertyTypes) &&
        minBedrooms == other.minBedrooms &&
        maxBedrooms == other.maxBedrooms &&
        minBathrooms == other.minBathrooms &&
        maxBathrooms == other.maxBathrooms &&
        sortBy == other.sortBy &&
        city == other.city &&
        radiusKm == other.radiusKm;
  }

  @override
  int get hashCode => Object.hash(
    minPrice,
    maxPrice,
    Object.hashAll(propertyTypes),
    minBedrooms,
    maxBedrooms,
    minBathrooms,
    maxBathrooms,
    sortBy,
    city,
    radiusKm,
  );

  static bool _listEquals(List<PropertyType> a, List<PropertyType> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
