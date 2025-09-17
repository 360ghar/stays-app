import 'property_model.dart';

/// Immutable filter state that can be shared across multiple property flows.
///
/// The fields intentionally mirror the backend query parameters so the model
/// can be serialized directly when hitting the unified properties endpoint.
class UnifiedFilterModel {
  final double? minPrice;
  final double? maxPrice;
  final List<String> propertyTypes;
  final int? minBedrooms;
  final int? maxBedrooms;
  final int? minBathrooms;
  final int? maxBathrooms;
  final double? minRating;
  final String? sortBy;
  final bool? instantBook;
  final bool? selfCheckIn;
  final bool? petsAllowed;
  final bool? smokingAllowed;
  final String? city;
  final double? radiusKm;

  UnifiedFilterModel({
    this.minPrice,
    this.maxPrice,
    List<String>? propertyTypes,
    this.minBedrooms,
    this.maxBedrooms,
    this.minBathrooms,
    this.maxBathrooms,
    this.minRating,
    this.sortBy,
    this.instantBook,
    this.selfCheckIn,
    this.petsAllowed,
    this.smokingAllowed,
    this.city,
    this.radiusKm,
  }) : propertyTypes =
           propertyTypes == null
               ? const []
               : List.unmodifiable(
                 propertyTypes.map((type) => type.toLowerCase().trim()),
               );

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
      minRating != null ||
      sortBy != null ||
      instantBook != null ||
      selfCheckIn != null ||
      petsAllowed != null ||
      smokingAllowed != null ||
      (city != null && city!.trim().isNotEmpty) ||
      radiusKm != null;

  UnifiedFilterModel copyWith({
    double? minPrice,
    double? maxPrice,
    List<String>? propertyTypes,
    int? minBedrooms,
    int? maxBedrooms,
    int? minBathrooms,
    int? maxBathrooms,
    double? minRating,
    String? sortBy,
    bool? instantBook,
    bool? selfCheckIn,
    bool? petsAllowed,
    bool? smokingAllowed,
    String? city,
    double? radiusKm,
  }) {
    return UnifiedFilterModel(
      minPrice: minPrice ?? this.minPrice,
      maxPrice: maxPrice ?? this.maxPrice,
      propertyTypes: propertyTypes ?? this.propertyTypes,
      minBedrooms: minBedrooms ?? this.minBedrooms,
      maxBedrooms: maxBedrooms ?? this.maxBedrooms,
      minBathrooms: minBathrooms ?? this.minBathrooms,
      maxBathrooms: maxBathrooms ?? this.maxBathrooms,
      minRating: minRating ?? this.minRating,
      sortBy: sortBy ?? this.sortBy,
      instantBook: instantBook ?? this.instantBook,
      selfCheckIn: selfCheckIn ?? this.selfCheckIn,
      petsAllowed: petsAllowed ?? this.petsAllowed,
      smokingAllowed: smokingAllowed ?? this.smokingAllowed,
      city: city ?? this.city,
      radiusKm: radiusKm ?? this.radiusKm,
    );
  }

  UnifiedFilterModel merge(UnifiedFilterModel other) {
    if (identical(this, other)) return this;
    return UnifiedFilterModel(
      minPrice: other.minPrice ?? minPrice,
      maxPrice: other.maxPrice ?? maxPrice,
      propertyTypes:
          other.propertyTypes.isNotEmpty ? other.propertyTypes : propertyTypes,
      minBedrooms: other.minBedrooms ?? minBedrooms,
      maxBedrooms: other.maxBedrooms ?? maxBedrooms,
      minBathrooms: other.minBathrooms ?? minBathrooms,
      maxBathrooms: other.maxBathrooms ?? maxBathrooms,
      minRating: other.minRating ?? minRating,
      sortBy: other.sortBy ?? sortBy,
      instantBook: other.instantBook ?? instantBook,
      selfCheckIn: other.selfCheckIn ?? selfCheckIn,
      petsAllowed: other.petsAllowed ?? petsAllowed,
      smokingAllowed: other.smokingAllowed ?? smokingAllowed,
      city: other.city ?? city,
      radiusKm: other.radiusKm ?? radiusKm,
    );
  }

  Map<String, dynamic> toJson() => toQueryParameters();

  Map<String, dynamic> toQueryParameters() => {
    if (minPrice != null) 'price_min': minPrice,
    if (maxPrice != null) 'price_max': maxPrice,
    if (propertyTypes.isNotEmpty) 'property_type': propertyTypes,
    if (minBedrooms != null) 'bedrooms_min': minBedrooms,
    if (maxBedrooms != null) 'bedrooms_max': maxBedrooms,
    if (minBathrooms != null) 'bathrooms_min': minBathrooms,
    if (maxBathrooms != null) 'bathrooms_max': maxBathrooms,
    if (minRating != null) 'rating_min': minRating,
    if (sortBy != null) 'sort_by': sortBy,
    if (instantBook != null) 'instant_book': instantBook,
    if (selfCheckIn != null) 'self_check_in': selfCheckIn,
    if (petsAllowed != null) 'pets_allowed': petsAllowed,
    if (smokingAllowed != null) 'smoking_allowed': smokingAllowed,
    if (city != null && city!.trim().isNotEmpty) 'city': city,
    if (radiusKm != null) 'radius': radiusKm,
  };

  bool matchesProperty(Property property) {
    if (minPrice != null && property.pricePerNight < minPrice!) {
      return false;
    }
    if (maxPrice != null && property.pricePerNight > maxPrice!) {
      return false;
    }
    if (propertyTypes.isNotEmpty &&
        !propertyTypes
            .map((type) => type.toLowerCase())
            .contains(property.propertyType.toLowerCase())) {
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
    if (minRating != null) {
      final rating = property.rating ?? 0;
      if (rating < minRating!) return false;
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

  bool matchesHotel({
    required double price,
    double? rating,
    String? propertyType,
  }) {
    if (minPrice != null && price < minPrice!) return false;
    if (maxPrice != null && price > maxPrice!) return false;
    if (minRating != null && (rating ?? 0) < minRating!) return false;
    if (propertyTypes.isNotEmpty && propertyType != null) {
      final normalized = propertyType.toLowerCase();
      if (!propertyTypes.contains(normalized)) return false;
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
      tags.addAll(propertyTypes.map((e) => e.replaceAll('_', ' ')));
    }
    if (minRating != null) {
      tags.add('${minRating!.toStringAsFixed(1)}+ stars');
    }
    if (minBedrooms != null) tags.add('${minBedrooms!}+ beds');
    if (minBathrooms != null) tags.add('${minBathrooms!}+ baths');
    if (instantBook == true) tags.add('Instant book');
    if (selfCheckIn == true) tags.add('Self check-in');
    if (petsAllowed == true) tags.add('Pets allowed');
    if (smokingAllowed == true) tags.add('Smoking');
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
        minRating == other.minRating &&
        sortBy == other.sortBy &&
        instantBook == other.instantBook &&
        selfCheckIn == other.selfCheckIn &&
        petsAllowed == other.petsAllowed &&
        smokingAllowed == other.smokingAllowed &&
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
    minRating,
    sortBy,
    instantBook,
    selfCheckIn,
    petsAllowed,
    smokingAllowed,
    city,
    radiusKm,
  );

  static bool _listEquals(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
