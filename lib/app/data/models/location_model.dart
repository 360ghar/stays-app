import '../../utils/helpers/json_helpers.dart';

class LocationModel {
  const LocationModel({
    required this.city,
    required this.country,
    required this.lat,
    required this.lng,
  });

  factory LocationModel.fromMap(Map<String, dynamic> map) => LocationModel(
    city: JsonHelpers.getStringOrDefault(map['city']),
    country: JsonHelpers.getStringOrDefault(map['country']),
    lat: JsonHelpers.getDouble(map['lat']) ?? 0,
    lng: JsonHelpers.getDouble(map['lng']) ?? 0,
  );
  final String city;
  final String country;
  final double lat;
  final double lng;

  Map<String, dynamic> toMap() => {
    'city': city,
    'country': country,
    'lat': lat,
    'lng': lng,
  };
}
