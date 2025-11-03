import 'package:json_annotation/json_annotation.dart';
import 'property_image_model.dart';

part 'property_model.g.dart';

@JsonSerializable()
class Property {
  final int id;
  @JsonKey(name: 'title')
  final String name;
  final String? description;
  @JsonKey(name: 'property_type')
  final String propertyType;
  final String purpose;

  // Location
  @JsonKey(name: 'full_address')
  final String? address;
  final String city;
  final String? state;
  final String country;
  final double? latitude;
  final double? longitude;
  @JsonKey(name: 'pincode')
  final String? zipCode;
  final String? locality;
  @JsonKey(name: 'sub_locality')
  final String? subLocality;
  final String? landmark;

  // Pricing
  @JsonKey(name: 'daily_rate')
  final double pricePerNight;
  final String currency;
  @JsonKey(name: 'base_price')
  final double? basePrice;
  @JsonKey(name: 'monthly_rent')
  final double? monthlyRent;
  @JsonKey(name: 'security_deposit')
  final double? securityDeposit;
  @JsonKey(name: 'maintenance_charges')
  final double? maintenanceCharges;
  @JsonKey(name: 'price_per_sqft')
  final double? pricePerSqft;

  // Property details
  final int? bedrooms;
  final int? bathrooms;
  final int? balconies;
  @JsonKey(name: 'max_occupancy')
  final int? maxGuests;
  @JsonKey(name: 'area_sqft')
  final double? squareFeet;
  @JsonKey(name: 'floor_number')
  final int? floor;
  @JsonKey(name: 'total_floors')
  final int? totalFloors;
  @JsonKey(name: 'parking_spaces')
  final int? parkingSpaces;
  @JsonKey(name: 'age_of_property')
  final int? ageOfProperty;
  @JsonKey(name: 'minimum_stay_days')
  final int? minimumStay;

  // Stats
  @JsonKey(name: 'view_count')
  final int? viewCount;
  @JsonKey(name: 'like_count')
  final int? likeCount;
  @JsonKey(name: 'interest_count')
  final int? interestCount;
  final double? rating;
  final int? reviewsCount;

  // Owner information
  @JsonKey(name: 'owner_id')
  final int? ownerId;
  @JsonKey(name: 'owner_name')
  final String? ownerName;
  @JsonKey(name: 'owner_contact')
  final String? ownerContact;
  @JsonKey(name: 'builder_name')
  final String? builderName;

  // Images and media
  @JsonKey(fromJson: _imagesFromJson)
  final List<PropertyImage>? images;
  @JsonKey(name: 'main_image_url')
  final String? coverImage;
  @JsonKey(name: 'virtual_tour_url')
  final String? virtualTourUrl;
  final bool? has360View;

  bool get hasVirtualTour => virtualTourUrl?.isNotEmpty == true;

  // Features and amenities
  @JsonKey(fromJson: _stringListFromJson)
  final List<String>? features;
  @JsonKey(fromJson: _stringListFromJson)
  final List<String>? amenities;
  @JsonKey(fromJson: _stringListFromJson)
  final List<String>? tags;

  // Availability
  @JsonKey(name: 'is_available')
  final bool? available;
  @JsonKey(name: 'available_from')
  final DateTime? availableFrom;
  final String? status;
  @JsonKey(name: 'calendar_data')
  final Map<String, dynamic>? calendarData;

  // Additional fields from API
  @JsonKey(name: 'created_at')
  final DateTime? createdAt;
  @JsonKey(name: 'updated_at')
  final DateTime? updatedAt;
  @JsonKey(name: 'distance_km')
  final double? distanceKm;
  final bool? liked;
  @JsonKey(name: 'user_has_scheduled_visit')
  final bool? userHasScheduledVisit;

  // Local state (not from API)
  @JsonKey(includeFromJson: false, includeToJson: false)
  final bool isFavorite;

  Property({
    required this.id,
    required this.name,
    this.description,
    required this.propertyType,
    this.purpose = 'short_stay',
    this.address,
    required this.city,
    this.state,
    required this.country,
    this.latitude,
    this.longitude,
    this.zipCode,
    this.locality,
    this.subLocality,
    this.landmark,
    required this.pricePerNight,
    this.currency = 'INR',
    this.basePrice,
    this.monthlyRent,
    this.securityDeposit,
    this.maintenanceCharges,
    this.pricePerSqft,
    this.bedrooms,
    this.bathrooms,
    this.balconies,
    this.maxGuests,
    this.squareFeet,
    this.floor,
    this.totalFloors,
    this.parkingSpaces,
    this.ageOfProperty,
    this.minimumStay,
    this.viewCount,
    this.likeCount,
    this.interestCount,
    this.rating,
    this.reviewsCount,
    this.ownerId,
    this.ownerName,
    this.ownerContact,
    this.builderName,
    this.images,
    this.coverImage,
    this.virtualTourUrl,
    this.has360View,
    this.features,
    this.amenities,
    this.tags,
    this.available,
    this.availableFrom,
    this.status,
    this.calendarData,
    this.createdAt,
    this.updatedAt,
    this.distanceKm,
    this.liked,
    this.userHasScheduledVisit,
    this.isFavorite = false,
  });

  factory Property.fromJson(Map<String, dynamic> json) {
    double? _toDouble(dynamic value) {
      if (value == null) return null;
      if (value is num) return value.toDouble();
      if (value is String) return double.tryParse(value);
      return null;
    }

    final Map<String, dynamic> map = Map<String, dynamic>.from(json);
    final double resolvedRate =
        _toDouble(map['daily_rate']) ?? _toDouble(map['base_price']) ?? 0.0;
    map['daily_rate'] = resolvedRate;
    map['base_price'] = _toDouble(map['base_price']);

    final model = _$PropertyFromJson(map);
    final dynamic likedValue = map['liked'] ?? map['is_liked'];
    final bool shouldMarkFavorite =
        likedValue is bool ? likedValue : model.liked == true;
    return shouldMarkFavorite ? model.copyWith(isFavorite: true) : model;
  }
  Map<String, dynamic> toJson() => _$PropertyToJson(this);

  // Safe converters to handle non-list values gracefully
  static List<PropertyImage>? _imagesFromJson(dynamic value) {
    try {
      if (value is List) {
        return value
            .whereType<Map>()
            .map((e) => PropertyImage.fromJson(Map<String, dynamic>.from(e)))
            .toList();
      }
    } catch (_) {}
    return null;
  }

  static List<String>? _stringListFromJson(dynamic value) {
    try {
      if (value is List) {
        return value.map((e) => e?.toString()).whereType<String>().toList();
      }
      if (value is String && value.isNotEmpty) {
        return [value];
      }
    } catch (_) {}
    return null;
  }

  // Helper methods
  String? get displayImage {
    if (coverImage != null && coverImage!.isNotEmpty) return coverImage!;
    if (images != null && images!.isNotEmpty) {
      final mainImage = images!.firstWhere(
        (img) => img.isMainImage,
        orElse: () => images!.first,
      );
      if (mainImage.imageUrl.isNotEmpty) return mainImage.imageUrl;
    }
    // Return null instead of empty string to prevent NetworkImage crashes
    return null;
  }

  String get displayPrice => '₹${pricePerNight.toStringAsFixed(0)}';

  String get fullAddress => [
    if (locality != null) locality,
    if (subLocality != null) subLocality,
    city,
    if (state != null) state,
    country,
  ].where((s) => s != null && s.isNotEmpty).join(', ');

  String get ratingText {
    if (rating == null) return 'New';
    return rating!.toStringAsFixed(1);
  }

  String get reviewsText {
    if (likeCount == null || likeCount == 0) return 'No likes';
    if (likeCount == 1) return '1 like';
    return '$likeCount likes';
  }

  bool get hasLocation => latitude != null && longitude != null;

  String get propertyTypeDisplay => propertyType
      .replaceAll('_', ' ')
      .split(' ')
      .map((word) => word[0].toUpperCase() + word.substring(1))
      .join(' ');

  Property copyWith({bool? isFavorite}) {
    return Property(
      id: id,
      name: name,
      description: description,
      propertyType: propertyType,
      purpose: purpose,
      address: address,
      city: city,
      state: state,
      country: country,
      latitude: latitude,
      longitude: longitude,
      zipCode: zipCode,
      locality: locality,
      subLocality: subLocality,
      landmark: landmark,
      pricePerNight: pricePerNight,
      currency: currency,
      basePrice: basePrice,
      monthlyRent: monthlyRent,
      securityDeposit: securityDeposit,
      maintenanceCharges: maintenanceCharges,
      pricePerSqft: pricePerSqft,
      bedrooms: bedrooms,
      bathrooms: bathrooms,
      balconies: balconies,
      maxGuests: maxGuests,
      squareFeet: squareFeet,
      floor: floor,
      totalFloors: totalFloors,
      parkingSpaces: parkingSpaces,
      ageOfProperty: ageOfProperty,
      minimumStay: minimumStay,
      viewCount: viewCount,
      likeCount: likeCount,
      interestCount: interestCount,
      rating: rating,
      reviewsCount: reviewsCount,
      ownerId: ownerId,
      ownerName: ownerName,
      ownerContact: ownerContact,
      builderName: builderName,
      images: images,
      coverImage: coverImage,
      virtualTourUrl: virtualTourUrl,
      has360View: has360View,
      features: features,
      amenities: amenities,
      tags: tags,
      available: available,
      availableFrom: availableFrom,
      status: status,
      calendarData: calendarData,
      createdAt: createdAt,
      updatedAt: updatedAt,
      distanceKm: distanceKm,
      liked: liked,
      userHasScheduledVisit: userHasScheduledVisit,
      isFavorite: isFavorite ?? this.isFavorite,
    );
  }
}
