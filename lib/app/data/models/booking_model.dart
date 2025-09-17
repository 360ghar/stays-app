import 'package:stays_app/app/data/models/property_model.dart';

class Booking {
  final int id;
  final int propertyId;
  final int userId;
  final String bookingReference;
  final DateTime checkInDate;
  final DateTime checkOutDate;
  final int guests;
  final int nights;
  final double totalAmount;
  final String bookingStatus;
  final String paymentStatus;
  final DateTime createdAt;
  final Property? property;
  final String? propertyTitle;
  final String? propertyCity;
  final String? propertyCountry;
  final String? propertyImageUrl;

  Booking({
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

  factory Booking.fromJson(Map<String, dynamic> json) {
    final checkIn =
        json['check_in_date'] != null
            ? DateTime.parse(json['check_in_date'] as String)
            : DateTime.now();
    final checkOut =
        json['check_out_date'] != null
            ? DateTime.parse(json['check_out_date'] as String)
            : checkIn.add(const Duration(days: 1));
    final propertyData = json['property'];
    Property? property;
    if (propertyData is Map<String, dynamic>) {
      property = Property.fromJson(Map<String, dynamic>.from(propertyData));
    }

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
      createdAt:
          json['created_at'] != null
              ? DateTime.parse(json['created_at'] as String)
              : DateTime.now(),
      property: property,
      propertyTitle: json['property_title']?.toString(),
      propertyCity: json['property_city']?.toString(),
      propertyCountry: json['property_country']?.toString(),
      propertyImageUrl:
          json['property_image_url']?.toString() ??
          json['property_main_image']?.toString(),
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

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'property_id': propertyId,
      'user_id': userId,
      'booking_reference': bookingReference,
      'check_in_date': checkInDate.toIso8601String(),
      'check_out_date': checkOutDate.toIso8601String(),
      'guests': guests,
      'nights': nights,
      'total_amount': totalAmount,
      'booking_status': bookingStatus,
      'payment_status': paymentStatus,
      'created_at': createdAt.toIso8601String(),
      'property_title': propertyTitle,
      'property_city': propertyCity,
      'property_country': propertyCountry,
      'property_image_url': propertyImageUrl,
      if (property != null) 'property': property!.toJson(),
    };
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
