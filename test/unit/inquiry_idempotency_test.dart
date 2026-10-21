import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:stays_app/app/data/models/booking_model.dart';
import 'package:stays_app/app/data/models/booking_pricing_model.dart';
import 'package:stays_app/app/data/providers/bookings_provider.dart';
import 'package:stays_app/app/utils/exceptions/app_exceptions.dart';
import 'package:stays_app/app/utils/exceptions/network_exceptions.dart';
import 'package:stays_app/core/providers/data_providers.dart';
import 'package:stays_app/features/inquiry/providers/inquiry_providers.dart';

import '../contract/support/wire.dart';

class _FakeBookings extends BookingsProvider {
  final keys = <String>[];
  final payloads = <Map<String, dynamic>>[];
  Object? failWith;
  Object? pricingFailure;

  @override
  Future<BookingPricingModel> calculatePricing({
    required int propertyId,
    required String checkIn,
    required String checkOut,
    required int guests,
  }) async {
    final failure = pricingFailure;
    if (failure != null) throw failure;
    return const BookingPricingModel(
      baseAmount: 1000,
      taxesAmount: 100,
      serviceCharges: 50,
      discountAmount: 0,
      totalAmount: 1150,
      nights: 2,
    );
  }

  @override
  Future<Booking> createBooking(
    Map<String, dynamic> payload, {
    required String idempotencyKey,
  }) async {
    keys.add(idempotencyKey);
    payloads.add(payload);
    final failure = failWith;
    if (failure != null) throw failure;
    return Booking.fromJson(obj(fixture('bookings')['created']));
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(useTestConfig);

  late _FakeBookings fake;
  late ProviderContainer container;
  late InquiryFormNotifier form;

  setUp(() {
    fake = _FakeBookings();
    container = ProviderContainer(
      overrides: [bookingsProviderProvider.overrideWithValue(fake)],
    );
    addTearDown(container.dispose);
    // The provider is auto-disposed: keep it alive for the test.
    container.listen(inquiryFormProvider, (_, _) {});
    form = container.read(inquiryFormProvider.notifier);
  });

  Future<void> fillForm({int guests = 2}) async {
    form
      ..setDates(DateTime(2026, 11, 10), DateTime(2026, 11, 12))
      ..setGuests(guests)
      ..setContact(
        name: 'Asha Verma',
        phone: '+919800000000',
        email: 'asha@example.com',
      );
    await form.loadPricing(1);
  }

  final timeout = ApiException(
    message: 'Request timed out. Please try again.',
    statusCode: 408,
    transportFailure: TransportFailureKind.possiblySent,
  );

  test('a manual retry after a failure reuses the Idempotency-Key', () async {
    await fillForm();
    fake.failWith = timeout;
    expect(await form.submit(1), isFalse);
    expect(container.read(inquiryFormProvider).status, InquiryStatus.error);

    fake.failWith = null;
    expect(await form.submit(1), isTrue);
    expect(fake.keys, hasLength(2));
    expect(fake.keys.first, isNotEmpty);
    expect(fake.keys.last, fake.keys.first);
  });

  test('a repeated tap on the same request keeps one key', () async {
    await fillForm();
    fake.failWith = timeout;
    await form.submit(1);
    await form.submit(1);
    await form.submit(1);
    expect(fake.keys.toSet(), hasLength(1));
  });

  test('the key is not blank and fits the backend limit', () async {
    await fillForm();
    await form.submit(1);
    expect(fake.keys.single.trim(), isNotEmpty);
    expect(fake.keys.single.length, lessThanOrEqualTo(128));
  });

  test('a new booking after success gets a new key', () async {
    await fillForm();
    await form.submit(1);
    await form.submit(1);
    expect(fake.keys, hasLength(2));
    expect(fake.keys.last, isNot(fake.keys.first));
  });

  test('a changed request gets a new key', () async {
    await fillForm();
    fake.failWith = timeout;
    await form.submit(1);

    await fillForm(guests: 3);
    await form.submit(1);
    expect(fake.keys, hasLength(2));
    expect(fake.keys.last, isNot(fake.keys.first));
    expect(fake.payloads.last['guests'], 3);
  });

  test('the request carries no money or status key', () async {
    await fillForm();
    await form.submit(1);
    final payload = fake.payloads.single;
    expect(payload['check_in_date'], '2026-11-10');
    expect(payload['check_out_date'], '2026-11-12');
    for (final key in const [
      'total_amount',
      'base_amount',
      'nights',
      'booking_status',
      'payment_status',
    ]) {
      expect(payload.containsKey(key), isFalse, reason: key);
    }
  });

  test('a rejected request shows the server reason', () async {
    await fillForm();
    fake.failWith = ApiException(
      message: 'primary_guest_phone: Invalid phone number',
      statusCode: 422,
      code: 'VALIDATION_ERROR',
    );
    await form.submit(1);
    expect(
      container.read(inquiryFormProvider).error,
      'primary_guest_phone: Invalid phone number',
    );
  });

  test('a pricing error shows the server reason, not a generic text', () async {
    fake.pricingFailure = ApiException(
      message: 'This stay has no nightly rate.',
      statusCode: 400,
      code: 'PRICING_UNAVAILABLE',
    );
    await fillForm();
    final state = container.read(inquiryFormProvider);
    expect(state.status, InquiryStatus.error);
    expect(state.error, 'This stay has no nightly rate.');
    expect(state.pricing, isNull);
    expect(state.canSubmit, isFalse);
  });

  test(
    'a form without an email cannot submit (the backend needs one)',
    () async {
      await fillForm();
      form.setContact(email: '');
      expect(container.read(inquiryFormProvider).canSubmit, isFalse);
      form.setContact(email: 'asha@example.com');
      expect(container.read(inquiryFormProvider).canSubmit, isTrue);
    },
  );
}
