import 'package:stays_app/app/data/models/wire_enums.dart';
import 'package:stays_app/app/utils/helpers/json_helpers.dart';

/// The property a booking is for: `{id, title, city, country, cover_image_url}`.
class BookingPropertySummary {
  const BookingPropertySummary({
    required this.id,
    required this.title,
    this.city,
    this.country,
    this.coverImageUrl,
  });

  factory BookingPropertySummary.fromJson(Map<String, dynamic> json) {
    return BookingPropertySummary(
      id: JsonHelpers.getInt(json['id']) ?? 0,
      title: JsonHelpers.getStringOrDefault(json['title']),
      city: JsonHelpers.getString(json['city']),
      country: JsonHelpers.getString(json['country']),
      coverImageUrl: JsonHelpers.getString(json['cover_image_url']),
    );
  }

  final int id;
  final String title;
  final String? city;
  final String? country;
  final String? coverImageUrl;

  Map<String, dynamic> toMap() => {
    'id': id,
    'title': title,
    'city': city,
    'country': country,
    'cover_image_url': coverImageUrl,
  };
}

class Booking {
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
    required this.createdAt,
    this.bookingStatus,
    this.paymentStatus,
    this.property,
  });

  factory Booking.fromJson(Map<String, dynamic> json) {
    final checkIn =
        stayDate(json['check_in_date']) ??
        (throw const FormatException('A booking needs check_in_date.'));
    final checkOut =
        stayDate(json['check_out_date']) ??
        (throw const FormatException('A booking needs check_out_date.'));
    final propertyData = json['property'];
    return Booking(
      id: JsonHelpers.getInt(json['id']) ?? 0,
      propertyId: JsonHelpers.getInt(json['property_id']) ?? 0,
      userId: JsonHelpers.getInt(json['user_id']) ?? 0,
      bookingReference: JsonHelpers.getStringOrDefault(
        json['booking_reference'],
      ),
      checkInDate: checkIn,
      checkOutDate: checkOut,
      guests: JsonHelpers.getInt(json['guests']) ?? 1,
      nights:
          JsonHelpers.getInt(json['nights']) ??
          checkOut.difference(checkIn).inDays,
      totalAmount: JsonHelpers.getDouble(json['total_amount']) ?? 0,
      // An unknown status reads as null (and is logged). It is not turned
      // into a real status.
      bookingStatus: BookingStatus.fromJson(json['booking_status']),
      paymentStatus: PaymentStatus.fromJson(json['payment_status']),
      createdAt:
          JsonHelpers.getDateTime(json['created_at']) ??
          DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      property: propertyData is Map
          ? BookingPropertySummary.fromJson(
              Map<String, dynamic>.from(propertyData),
            )
          : null,
    );
  }

  /// A stay date. The backend keeps it as midnight UTC. The calendar date is
  /// the value, so it is read from the UTC date and not shifted by the
  /// device time zone.
  static DateTime? stayDate(Object? value) {
    final parsed = JsonHelpers.getDateTime(value);
    if (parsed == null) return null;
    final utc = parsed.toUtc();
    return DateTime(utc.year, utc.month, utc.day);
  }

  final int id;
  final int propertyId;
  final int userId;
  final String bookingReference;
  final DateTime checkInDate;
  final DateTime checkOutDate;
  final int guests;
  final int nights;
  final double totalAmount;
  final BookingStatus? bookingStatus;
  final PaymentStatus? paymentStatus;
  final DateTime createdAt;
  final BookingPropertySummary? property;

  String get displayTitle {
    final title = property?.title ?? '';
    return title.isEmpty ? 'Stay' : title;
  }

  String get displayImage => property?.coverImageUrl ?? '';

  String get displayLocation {
    final city = property?.city;
    final country = property?.country;
    final hasCity = city != null && city.isNotEmpty;
    final hasCountry = country != null && country.isNotEmpty;
    if (hasCity && hasCountry) return '$city, $country';
    if (hasCity) return city;
    if (hasCountry) return country;
    return '';
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'property_id': propertyId,
      'user_id': userId,
      'booking_reference': bookingReference,
      'check_in_date': JsonHelpers.toDateOnly(checkInDate),
      'check_out_date': JsonHelpers.toDateOnly(checkOutDate),
      'guests': guests,
      'nights': nights,
      'total_amount': totalAmount,
      'booking_status': bookingStatus?.wire,
      'payment_status': paymentStatus?.wire,
      'created_at': JsonHelpers.toUtcIso8601(createdAt),
      if (property != null) 'property': property!.toMap(),
    };
  }
}
