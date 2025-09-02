import '../../utils/helpers/currency_helper.dart';
import 'amenity_model.dart';
import 'location_model.dart';
import 'user_model.dart';

enum PropertyType { apartment, house, villa, condo }

class ListingModel {
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
    this.rating = 0,
    this.reviewCount = 0,
    this.houseRules = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  factory ListingModel.fromMap(Map<String, dynamic> map) => ListingModel(
        id: map['id']?.toString() ?? '',
        title: map['title'] as String? ?? '',
        description: map['description'] as String? ?? '',
        propertyType: _parsePropertyType(map['propertyType'] as String?),
        location: LocationModel.fromMap(map['location'] as Map<String, dynamic>? ?? const {}),
        pricePerNight: (map['pricePerNight'] as num?)?.toDouble() ?? 0,
        images: (map['images'] as List? ?? []).cast<String>(),
        amenities: ((map['amenities'] as List? ?? [])
                .cast<Map<String, dynamic>>())
            .map(AmenityModel.fromMap)
            .toList(),
        host: UserModel.fromMap(map['host'] as Map<String, dynamic>? ?? const {}),
        maxGuests: map['maxGuests'] as int? ?? 1,
        bedrooms: map['bedrooms'] as int? ?? 1,
        bathrooms: map['bathrooms'] as int? ?? 1,
        rating: (map['rating'] as num?)?.toDouble() ?? 0,
        reviewCount: map['reviewCount'] as int? ?? 0,
        houseRules: (map['houseRules'] as List? ?? []).cast<String>(),
        createdAt: DateTime.tryParse(map['createdAt'] as String? ?? '') ?? DateTime.now(),
        updatedAt: DateTime.tryParse(map['updatedAt'] as String? ?? '') ?? DateTime.now(),
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'description': description,
        'propertyType': propertyType.name,
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
    switch (value) {
      case 'apartment':
        return PropertyType.apartment;
      case 'house':
        return PropertyType.house;
      case 'villa':
        return PropertyType.villa;
      case 'condo':
        return PropertyType.condo;
      default:
        return PropertyType.apartment;
    }
  }
}

