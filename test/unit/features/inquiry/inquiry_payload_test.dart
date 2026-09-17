import 'package:flutter_test/flutter_test.dart';
import 'package:stays_app/app/data/models/booking_pricing_model.dart';
import 'package:stays_app/features/inquiry/providers/inquiry_providers.dart';

BookingPricingModel _pricing({double total = 5000}) {
  return BookingPricingModel(
    baseAmount: 4000,
    taxesAmount: 600,
    serviceCharges: 400,
    totalAmount: total,
    nights: 2,
  );
}

Map<String, dynamic> _base() {
  return {
    'pricing': _pricing(),
    'propertyId': 7,
    'checkInIso': '2026-10-01T00:00:00.000',
    'checkOutIso': '2026-10-03T00:00:00.000',
    'guests': 2,
    'primaryGuestName': 'Asha',
    'primaryGuestPhone': '+919999999999',
    'primaryGuestEmail': 'asha@example.com',
  };
}

void main() {
  test('builds payload from server pricing', () {
    final args = _base();
    final payload = buildInquiryPayload(
      pricing: args['pricing'] as BookingPricingModel,
      propertyId: args['propertyId'] as int,
      checkInIso: args['checkInIso'] as String,
      checkOutIso: args['checkOutIso'] as String,
      guests: args['guests'] as int,
      primaryGuestName: args['primaryGuestName'] as String,
      primaryGuestPhone: args['primaryGuestPhone'] as String,
      primaryGuestEmail: args['primaryGuestEmail'] as String,
    );
    expect(payload['property_id'], 7);
    expect(payload['total_amount'], 5000);
    expect(payload['base_amount'], 4000);
    expect(payload['booking_status'], 'pending');
    expect(payload['payment_status'], 'pending');
    expect(payload['nights'], 2);
    expect((payload['guest_details'] as Map)['adults'], 2);
  });

  test('extra payload cannot override money fields', () {
    final payload = buildInquiryPayload(
      pricing: _pricing(),
      propertyId: 7,
      checkInIso: '2026-10-01T00:00:00.000',
      checkOutIso: '2026-10-03T00:00:00.000',
      guests: 2,
      primaryGuestName: 'Asha',
      primaryGuestPhone: '+919999999999',
      primaryGuestEmail: '',
      additionalPayload: {'total_amount': 1, 'base_amount': 1},
    );
    expect(payload['total_amount'], 5000);
    expect(payload['base_amount'], 4000);
  });

  test('throws when pricing invalid', () {
    expect(
      () => buildInquiryPayload(
        pricing: const BookingPricingModel(
          baseAmount: -1,
          taxesAmount: 0,
          serviceCharges: 0,
          totalAmount: -1,
        ),
        propertyId: 7,
        checkInIso: '2026-10-01T00:00:00.000',
        checkOutIso: '2026-10-03T00:00:00.000',
        guests: 2,
        primaryGuestName: 'Asha',
        primaryGuestPhone: '+919999999999',
        primaryGuestEmail: '',
      ),
      throwsA(isA<PricingUnavailableException>()),
    );
  });

  test('trims special requests, drops blanks', () {
    final withRequests = buildInquiryPayload(
      pricing: _pricing(),
      propertyId: 7,
      checkInIso: '2026-10-01T00:00:00.000',
      checkOutIso: '2026-10-03T00:00:00.000',
      guests: 2,
      primaryGuestName: 'Asha',
      primaryGuestPhone: '+919999999999',
      primaryGuestEmail: '',
      specialRequests: '  late checkout  ',
    );
    expect(withRequests['special_requests'], 'late checkout');

    final withoutRequests = buildInquiryPayload(
      pricing: _pricing(),
      propertyId: 7,
      checkInIso: '2026-10-01T00:00:00.000',
      checkOutIso: '2026-10-03T00:00:00.000',
      guests: 2,
      primaryGuestName: 'Asha',
      primaryGuestPhone: '+919999999999',
      primaryGuestEmail: '',
      specialRequests: '   ',
    );
    expect(withoutRequests.containsKey('special_requests'), isFalse);
  });
}
