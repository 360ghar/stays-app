import 'package:flutter_test/flutter_test.dart';

import 'package:stays_app/app/data/models/booking_pricing_model.dart';
import 'package:stays_app/features/inquiry/controllers/inquiry_controller.dart';

void main() {
  const validPricing = BookingPricingModel(
    baseAmount: 1000.0,
    taxesAmount: 120.0,
    serviceCharges: 50.0,
    totalAmount: 1170.0,
    discountAmount: 0,
    nights: 2,
  );

  group('BookingPricingModel.hasValidAmounts', () {
    test('accepts a complete server pricing payload', () {
      expect(validPricing.hasValidAmounts, isTrue);
    });

    test('rejects zero/negative totals', () {
      const zero = BookingPricingModel(
        baseAmount: 0,
        taxesAmount: 0,
        serviceCharges: 0,
        totalAmount: 0,
      );
      expect(zero.hasValidAmounts, isFalse);

      const negative = BookingPricingModel(
        baseAmount: -100,
        taxesAmount: 0,
        serviceCharges: 0,
        totalAmount: -100,
      );
      expect(negative.hasValidAmounts, isFalse);
    });

    test('rejects NaN/Infinity amounts', () {
      const nan = BookingPricingModel(
        baseAmount: double.nan,
        taxesAmount: 0,
        serviceCharges: 0,
        totalAmount: 100,
      );
      expect(nan.hasValidAmounts, isFalse);

      const inf = BookingPricingModel(
        baseAmount: 100,
        taxesAmount: 0,
        serviceCharges: double.infinity,
        totalAmount: 100,
      );
      expect(inf.hasValidAmounts, isFalse);
    });
  });

  group('buildBookingPayload', () {
    test('builds a payload with server-authoritative money fields', () {
      final payload = buildBookingPayload(
        pricing: validPricing,
        propertyId: 42,
        checkInIso: '2026-08-01T00:00:00Z',
        checkOutIso: '2026-08-03T00:00:00Z',
        guests: 2,
        primaryGuestName: 'Test User',
        primaryGuestPhone: '+919876543210',
        primaryGuestEmail: 'test@example.com',
      );

      expect(payload['property_id'], 42);
      expect(payload['base_amount'], 1000.0);
      expect(payload['taxes_amount'], 120.0);
      expect(payload['service_charges'], 50.0);
      expect(payload['total_amount'], 1170.0);
      expect(payload['discount_amount'], 0);
      expect(payload['nights'], 2);
      expect(payload['booking_status'], 'pending');
      expect(payload['payment_status'], 'pending');
    });

    test('throws PricingUnavailableException for invalid pricing', () {
      const invalid = BookingPricingModel(
        baseAmount: 0,
        taxesAmount: 0,
        serviceCharges: 0,
        totalAmount: 0,
      );
      expect(
        () => buildBookingPayload(
          pricing: invalid,
          propertyId: 1,
          checkInIso: '2026-08-01T00:00:00Z',
          checkOutIso: '2026-08-02T00:00:00Z',
          guests: 1,
          primaryGuestName: 'A',
          primaryGuestPhone: '+911234567890',
          primaryGuestEmail: 'a@b.com',
        ),
        throwsA(isA<PricingUnavailableException>()),
      );
    });

    test('additionalPayload can never override money fields', () {
      final payload = buildBookingPayload(
        pricing: validPricing,
        propertyId: 1,
        checkInIso: '2026-08-01T00:00:00Z',
        checkOutIso: '2026-08-02T00:00:00Z',
        guests: 1,
        primaryGuestName: 'A',
        primaryGuestPhone: '+911234567890',
        primaryGuestEmail: 'a@b.com',
        additionalPayload: <String, dynamic>{
          'total_amount': 1.0,
          'base_amount': 1.0,
          'property_title': 'My Stay',
        },
      );

      expect(payload['total_amount'], 1170.0);
      expect(payload['base_amount'], 1000.0);
      expect(payload['property_title'], 'My Stay');
    });

    test('caller nights win over pricing nights when provided', () {
      final payload = buildBookingPayload(
        pricing: validPricing,
        propertyId: 1,
        checkInIso: '2026-08-01T00:00:00Z',
        checkOutIso: '2026-08-02T00:00:00Z',
        guests: 1,
        primaryGuestName: 'A',
        primaryGuestPhone: '+911234567890',
        primaryGuestEmail: 'a@b.com',
        nights: 5,
      );
      expect(payload['nights'], 5);
    });
  });
}
