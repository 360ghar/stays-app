import 'package:json_annotation/json_annotation.dart';
import '../../utils/constants/app_constants.dart';

part 'hotel_model.g.dart';

@JsonSerializable()
class Hotel {
  final String id;
  final String name;
  final String imageUrl;
  final String city;
  final String country;
  final double rating;
  final int reviews;
  final double pricePerNight;
  final String currency;
  final String propertyType;
  final bool isFavorite;
  final double? latitude;
  final double? longitude;
  final List<String>? amenities;
  final String? description;

  Hotel({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.city,
    required this.country,
    required this.rating,
    required this.reviews,
    required this.pricePerNight,
    this.currency = AppConstants.defaultCurrencySymbol,
    this.propertyType = 'Hotel',
    this.isFavorite = false,
    this.latitude,
    this.longitude,
    this.amenities,
    this.description,
  });

  factory Hotel.fromJson(Map<String, dynamic> json) => _$HotelFromJson(json);
  Map<String, dynamic> toJson() => _$HotelToJson(this);

  // Mock data generator
  static List<Hotel> getMockHotels(String city) {
    final hotels = [
      Hotel(
        id: '1',
        name: 'The Grand Plaza',
        imageUrl:
            'https://images.unsplash.com/photo-1566073771259-6a8506099945',
        city: city,
        country: 'USA',
        rating: 4.8,
        reviews: 1254,
        pricePerNight: 289,
        propertyType: 'Luxury Hotel',
        amenities: ['WiFi', 'Pool', 'Gym', 'Spa', 'Restaurant'],
        description: 'Experience luxury at its finest in the heart of $city.',
      ),
      Hotel(
        id: '2',
        name: 'Sunset Boutique Hotel',
        imageUrl:
            'https://images.unsplash.com/photo-1582719508461-905c673771fd',
        city: city,
        country: 'USA',
        rating: 4.6,
        reviews: 892,
        pricePerNight: 195,
        propertyType: 'Boutique Hotel',
        amenities: ['WiFi', 'Breakfast', 'Bar', 'Parking'],
        description: 'Charming boutique hotel with stunning sunset views.',
      ),
      Hotel(
        id: '3',
        name: 'Urban Comfort Suites',
        imageUrl:
            'https://images.unsplash.com/photo-1564501049412-61c2a3083791',
        city: city,
        country: 'USA',
        rating: 4.5,
        reviews: 678,
        pricePerNight: 145,
        propertyType: 'Hotel Suite',
        amenities: ['WiFi', 'Kitchen', 'Gym', 'Business Center'],
        description: 'Modern suites perfect for business and leisure.',
      ),
      Hotel(
        id: '4',
        name: 'Riverside Inn',
        imageUrl: 'https://images.unsplash.com/photo-1551882547-ff40c63fe5fa',
        city: city,
        country: 'USA',
        rating: 4.3,
        reviews: 432,
        pricePerNight: 98,
        propertyType: 'Inn',
        amenities: ['WiFi', 'Breakfast', 'Parking'],
        description: 'Cozy inn with beautiful riverside location.',
      ),
      Hotel(
        id: '5',
        name: 'Sky Tower Hotel',
        imageUrl: 'https://images.unsplash.com/photo-1542314831-068cd1dbfeeb',
        city: city,
        country: 'USA',
        rating: 4.7,
        reviews: 1089,
        pricePerNight: 325,
        propertyType: 'Luxury Hotel',
        amenities: ['WiFi', 'Pool', 'Spa', 'Restaurant', 'Bar', 'Gym'],
        description: 'Premium hotel offering panoramic city views.',
      ),
      Hotel(
        id: '6',
        name: 'Garden Retreat',
        imageUrl:
            'https://images.unsplash.com/photo-1520250497591-112f2f40a3f4',
        city: city,
        country: 'USA',
        rating: 4.4,
        reviews: 567,
        pricePerNight: 165,
        propertyType: 'Resort',
        amenities: ['WiFi', 'Pool', 'Garden', 'Restaurant'],
        description: 'Peaceful retreat surrounded by beautiful gardens.',
      ),
    ];

    return hotels;
  }
}
