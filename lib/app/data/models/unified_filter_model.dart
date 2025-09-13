class UnifiedFilterModel {
  final double? minPrice;
  final double? maxPrice;
  final List<String>? amenities;
  final List<String>? propertyTypes;
  final int? minBedrooms;
  final int? maxBedrooms;
  final int? minBathrooms;
  final int? maxBathrooms;
  final double? rating;
  final bool? instantBook;
  final bool? selfCheckIn;
  final bool? petsAllowed;
  final bool? smokingAllowed;
  final String? sortBy;
  final String? location;
  final double? radius;

  UnifiedFilterModel({
    this.minPrice,
    this.maxPrice,
    this.amenities,
    this.propertyTypes,
    this.minBedrooms,
    this.maxBedrooms,
    this.minBathrooms,
    this.maxBathrooms,
    this.rating,
    this.instantBook,
    this.selfCheckIn,
    this.petsAllowed,
    this.smokingAllowed,
    this.sortBy,
    this.location,
    this.radius,
  });

  Map<String, dynamic> toJson() => {
    if (minPrice != null) 'minPrice': minPrice,
    if (maxPrice != null) 'maxPrice': maxPrice,
    if (amenities != null && amenities!.isNotEmpty) 'amenities': amenities,
    if (propertyTypes != null && propertyTypes!.isNotEmpty)
      'propertyTypes': propertyTypes,
    if (minBedrooms != null) 'minBedrooms': minBedrooms,
    if (maxBedrooms != null) 'maxBedrooms': maxBedrooms,
    if (minBathrooms != null) 'minBathrooms': minBathrooms,
    if (maxBathrooms != null) 'maxBathrooms': maxBathrooms,
    if (rating != null) 'rating': rating,
    if (instantBook != null) 'instantBook': instantBook,
    if (selfCheckIn != null) 'selfCheckIn': selfCheckIn,
    if (petsAllowed != null) 'petsAllowed': petsAllowed,
    if (smokingAllowed != null) 'smokingAllowed': smokingAllowed,
    if (sortBy != null) 'sortBy': sortBy,
    if (location != null) 'location': location,
    if (radius != null) 'radius': radius,
  };
}
