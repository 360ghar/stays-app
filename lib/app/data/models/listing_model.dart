import '../../utils/helpers/currency_helper.dart';
import '../../utils/helpers/json_helpers.dart';
import 'amenity_model.dart';
import 'location_model.dart';
import 'user_model.dart';

enum PropertyType {
  apartment,
  house,
  villa,
  condo,
  studio,
  penthouse,
  builderFloor,
  room,
  loft,
  pg;

  /// Canonical wire form used in API requests/responses. Single source of
  /// truth for the snake_case encoding shared with the backend and the
  /// filter sheet.
  String get wireName {
    switch (this) {
      case PropertyType.builderFloor:
        return 'builder_floor';
      default:
        return name;
    }
  }

  static PropertyType? fromWireName(String? value) {
    if (value == null || value.isEmpty) return null;
    for (final t in PropertyType.values) {
      if (t.wireName == value) return t;
    }
    return null;
  }
}

class ListingModel {
  ListingModel({
    required this.id,
    required this.title,
    required this.description,
    required this.propertyType,
    required this.location,
    required this.pricePerNight,
    required this.images,
    required this.amenities,
    required this.host,
    required this.maxGuests,
    required this.bedrooms,
    required this.bathrooms,
    required this.createdAt,
    required this.updatedAt,
    this.rating = 0,
    this.reviewCount = 0,
    this.houseRules = const [],
  });

  factory ListingModel.fromMap(Map<String, dynamic> map) => ListingModel(
    id: map['id']?.toString() ?? '',
    title: JsonHelpers.getStringOrDefault(map['title']),
    description: JsonHelpers.getStringOrDefault(map['description']),
    propertyType: _parsePropertyType(
      JsonHelpers.getString(map['propertyType']),
    ),
    location: LocationModel.fromMap(
      JsonHelpers.getMap(map['location']) ?? const {},
    ),
    pricePerNight: JsonHelpers.getDouble(map['pricePerNight']) ?? 0,
    images: _stringList(map['images']),
    amenities:
        JsonHelpers.getMapList(
          map['amenities'],
        )?.map(AmenityModel.fromMap).toList() ??
        <AmenityModel>[],
    host: UserModel.fromMap(JsonHelpers.getMap(map['host']) ?? const {}),
    maxGuests: JsonHelpers.getInt(map['maxGuests']) ?? 1,
    bedrooms: JsonHelpers.getInt(map['bedrooms']) ?? 1,
    bathrooms: JsonHelpers.getInt(map['bathrooms']) ?? 1,
    rating: JsonHelpers.getDouble(map['rating']) ?? 0,
    reviewCount: JsonHelpers.getInt(map['reviewCount']) ?? 0,
    houseRules: _stringList(map['houseRules']),
    createdAt: JsonHelpers.getDateTime(map['createdAt']) ?? DateTime.now(),
    updatedAt: JsonHelpers.getDateTime(map['updatedAt']) ?? DateTime.now(),
  );
  final String id;
  final String title;
  final String description;
  final PropertyType propertyType;
  final LocationModel location;
  final double pricePerNight;
  final List<String> images;
  final List<AmenityModel> amenities;
  final UserModel host;
  final int maxGuests;
  final int bedrooms;
  final int bathrooms;
  final double rating;
  final int reviewCount;
  final List<String> houseRules;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// Safely extracts a list of strings from a JSON value.
  static List<String> _stringList(dynamic value) {
    if (value is! List) return <String>[];
    return value.whereType<String>().map((e) => e).toList();
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'title': title,
    'description': description,
    'propertyType': propertyType.wireName,
    'location': location.toMap(),
    'pricePerNight': pricePerNight,
    'images': images,
    'amenities': amenities.map((e) => e.toMap()).toList(),
    'host': host.toMap(),
    'maxGuests': maxGuests,
    'bedrooms': bedrooms,
    'bathrooms': bathrooms,
    'rating': rating,
    'reviewCount': reviewCount,
    'houseRules': houseRules,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };

  String get primaryImage => images.isNotEmpty ? images.first : '';
  String get formattedPrice => CurrencyHelper.format(pricePerNight);

  static PropertyType _parsePropertyType(String? value) {
    return PropertyType.fromWireName(value) ?? PropertyType.apartment;
  }
}
