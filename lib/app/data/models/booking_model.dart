import 'package:json_annotation/json_annotation.dart';
import 'package:stays_app/app/data/models/property_model.dart';

part 'booking_model.g.dart';

@JsonSerializable(createFactory: false)
class Booking {
  final int id;
  @JsonKey(name: 'property_id')
  final int propertyId;
  @JsonKey(name: 'user_id')
  final int userId;
  @JsonKey(name: 'booking_reference')
  final String bookingReference;
  @JsonKey(name: 'check_in_date')
  final DateTime checkInDate;
  @JsonKey(name: 'check_out_date')
  final DateTime checkOutDate;
  final int guests;
  final int nights;
  @JsonKey(name: 'total_amount')
  final double totalAmount;
  @JsonKey(name: 'booking_status')
  final String bookingStatus;
  @JsonKey(name: 'payment_status')
  final String paymentStatus;
  @JsonKey(name: 'created_at')
  final DateTime createdAt;
  @JsonKey(includeToJson: false)
  final Property? property;
  @JsonKey(name: 'property_title')
  final String? propertyTitle;
  @JsonKey(name: 'property_city')
  final String? propertyCity;
  @JsonKey(name: 'property_country')
  final String? propertyCountry;
  @JsonKey(name: 'property_image_url')
  final String? propertyImageUrl;

  const Booking({
    required this.id,
    required this.propertyId,
    required this.userId,
    required this.bookingReference,
    required this.checkInDate,
    required this.checkOutDate,
    required this.guests,
    required this.nights,
    required this.totalAmount,
    required this.bookingStatus,
    required this.paymentStatus,
    required this.createdAt,
    this.property,
    this.propertyTitle,
    this.propertyCity,
    this.propertyCountry,
    this.propertyImageUrl,
  });

  // Custom fromJson to handle complex API response variations
  factory Booking.fromJson(Map<String, dynamic> json) {
    final checkIn = json['check_in_date'] != null
        ? DateTime.parse(json['check_in_date'] as String)
        : DateTime.now();
    final checkOut = json['check_out_date'] != null
        ? DateTime.parse(json['check_out_date'] as String)
        : checkIn.add(const Duration(days: 1));
    final propertyData = json['property'];
    Property? property;
    if (propertyData is Map) {
      property = _safePropertyFromJson(propertyData);
    } else if (propertyData is List && propertyData.isNotEmpty) {
      final first = propertyData.first;
      if (first is Map) {
        property = _safePropertyFromJson(first);
      }
    }

    final propertyTitleSource =
        json['property_title'] ??
        _readPropertyField(propertyData, ['title', 'name']);
    final propertyCitySource =
        json['property_city'] ?? _readPropertyField(propertyData, ['city']);
    final propertyCountrySource =
        json['property_country'] ??
        _readPropertyField(propertyData, ['country']);
    final propertyImageSource =
        json['property_image_url'] ??
        json['property_main_image'] ??
        _readPropertyField(propertyData, [
          'property_image_url',
          'main_image_url',
          'coverImage',
          'image_url',
        ]);

    return Booking(
      id: _parseInt(json['id']),
      propertyId: _parseInt(json['property_id']),
      userId: _parseInt(json['user_id']),
      bookingReference: json['booking_reference']?.toString() ?? 'N/A',
      checkInDate: checkIn,
      checkOutDate: checkOut,
      guests: _parseInt(json['guests'], fallback: 1),
      nights: _parseInt(
        json['nights'],
        fallback: checkOut.difference(checkIn).inDays.clamp(1, 365),
      ),
      totalAmount: _parseDouble(json['total_amount']),
      bookingStatus: json['booking_status']?.toString() ?? 'pending',
      paymentStatus: json['payment_status']?.toString() ?? 'pending',
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      property: property,
      propertyTitle: _stringOrNull(propertyTitleSource),
      propertyCity: _stringOrNull(propertyCitySource),
      propertyCountry: _stringOrNull(propertyCountrySource),
      propertyImageUrl: _stringOrNull(propertyImageSource),
    );
  }

  String get displayTitle => property?.name ?? propertyTitle ?? 'Stay';

  String get displayImage => property?.displayImage ?? propertyImageUrl ?? '';

  String get displayLocation {
    final city = property?.city ?? propertyCity;
    final country = property?.country ?? propertyCountry;
    if ((city == null || city.isEmpty) &&
        (country == null || country.isEmpty)) {
      return '';
    }
    if (city != null &&
        city.isNotEmpty &&
        country != null &&
        country.isNotEmpty) {
      return '$city, $country';
    }
    return (city ?? country) ?? '';
  }

  Map<String, dynamic> toJson() {
    final result = _$BookingToJson(this);
    if (property != null) {
      result['property'] = property!.toJson();
    }
    return result;
  }

  // Backwards compatibility
  Map<String, dynamic> toMap() => toJson();

  static Property? _safePropertyFromJson(Map<dynamic, dynamic> value) {
    try {
      final mapped = value.map((key, val) => MapEntry(key.toString(), val));
      return Property.fromJson(Map<String, dynamic>.from(mapped));
    } catch (_) {
      return null;
    }
  }

  static String? _stringOrNull(dynamic value) {
    if (value == null) return null;
    if (value is String) return value;
    if (value is num || value is bool) return value.toString();
    if (value is List) {
      return value.whereType<String>().join(', ');
    }
    return value.toString();
  }

  static dynamic _readPropertyField(dynamic source, List<String> keys) {
    if (source is List && source.isNotEmpty) {
      return _readPropertyField(source.first, keys);
    }
    if (source is Map) {
      for (final key in keys) {
        if (source.containsKey(key) && source[key] != null) {
          return source[key];
        }
      }
    }
    return null;
  }

  static int _parseInt(dynamic value, {int fallback = 0}) {
    if (value == null) return fallback;
    if (value is int) return value;
    if (value is double) return value.toInt();
    final parsed = int.tryParse(value.toString());
    return parsed ?? fallback;
  }

  static double _parseDouble(dynamic value, {double fallback = 0}) {
    if (value == null) return fallback;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    final parsed = double.tryParse(value.toString());
    return parsed ?? fallback;
  }
}
