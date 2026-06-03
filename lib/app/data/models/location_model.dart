class LocationModel {
  final String city;
  final String country;
  final double lat;
  final double lng;

  const LocationModel({
    required this.city,
    required this.country,
    required this.lat,
    required this.lng,
  });

  factory LocationModel.fromMap(Map<String, dynamic> map) => LocationModel(
    city: map['city'] as String? ?? '',
    country: map['country'] as String? ?? '',
    lat: (map['lat'] as num?)?.toDouble() ?? 0,
    lng: (map['lng'] as num?)?.toDouble() ?? 0,
  );

  Map<String, dynamic> toMap() => {
    'city': city,
    'country': country,
    'lat': lat,
    'lng': lng,
  };
}
