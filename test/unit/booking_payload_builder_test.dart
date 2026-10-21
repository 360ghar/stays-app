import 'package:flutter_test/flutter_test.dart';

import 'package:stays_app/app/data/models/booking_pricing_model.dart';
import 'package:stays_app/features/inquiry/providers/inquiry_providers.dart';

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

  group('BookingPricingModel.fromMap', () {
    test('reads every amount of BookingPricing', () {
      final pricing = BookingPricingModel.fromMap(const {
        'base_amount': 10500.0,
        'taxes_amount': 1260.5,
        'service_charges': 525,
        'discount_amount': 0.0,
        'total_amount': 12285.5,
        'nights': 3,
      });
      expect(pricing.totalAmount, 12285.5);
      expect(pricing.serviceCharges, 525.0);
      expect(pricing.nights, 3);
      expect(pricing.hasValidAmounts, isTrue);
    });

    test('a missing amount throws and is never read as 0', () {
      expect(
        () => BookingPricingModel.fromMap(const {
          'base_amount': 10,
          'taxes_amount': 1,
          'service_charges': 1,
          'discount_amount': 0,
        }),
        throwsFormatException,
      );
    });
  });

  group('buildInquiryPayload', () {
    Map<String, dynamic> build({String? specialRequests}) {
      return buildInquiryPayload(
        propertyId: 42,
        checkIn: DateTime(2026, 8),
        checkOut: DateTime(2026, 8, 3),
        guests: 2,
        primaryGuestName: 'Test User',
        primaryGuestPhone: '+919876543210',
        primaryGuestEmail: 'test@example.com',
        specialRequests: specialRequests,
      );
    }

    test('sends stay dates as YYYY-MM-DD', () {
      final payload = build();
      expect(payload['check_in_date'], '2026-08-01');
      expect(payload['check_out_date'], '2026-08-03');
    });

    test('sends only the keys BookingCreate declares', () {
      final payload = build(specialRequests: 'late check-in');
      expect(payload.keys.toSet(), {
        'property_id',
        'check_in_date',
        'check_out_date',
        'guests',
        'primary_guest_name',
        'primary_guest_phone',
        'primary_guest_email',
        'guest_details',
        'special_requests',
      });
      expect(payload['property_id'], 42);
      expect((payload['guest_details'] as Map)['adults'], 2);
    });

    test('sends no money, nights or status field', () {
      final payload = build();
      for (final key in const [
        'base_amount',
        'taxes_amount',
        'service_charges',
        'discount_amount',
        'total_amount',
        'nights',
        'booking_status',
        'payment_status',
      ]) {
        expect(payload.containsKey(key), isFalse, reason: key);
      }
    });

    test('trims special requests and drops blanks', () {
      expect(
        build(specialRequests: '  late checkout  ')['special_requests'],
        'late checkout',
      );
      expect(
        build(specialRequests: '   ').containsKey('special_requests'),
        isFalse,
      );
    });
  });
}
