// Contract tests for the booking routes: list, create, pricing, occupancy and
// the booking chat.

import 'package:flutter_test/flutter_test.dart';
import 'package:stays_app/app/data/models/booking_model.dart';
import 'package:stays_app/app/data/models/wire_enums.dart';
import 'package:stays_app/app/data/providers/bookings_provider.dart';
import 'package:stays_app/app/utils/exceptions/app_exceptions.dart';
import 'package:stays_app/features/inquiry/providers/inquiry_providers.dart';

import 'support/wire.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(useTestConfig);

  final bookings = fixture('bookings');
  final errors = fixture('errors');

  group('Booking parsing', () {
    test('a booking reads its property summary', () {
      final booking = Booking.fromJson(items(bookings['list_page']).first);
      expect(booking.id, 11);
      expect(booking.property?.id, 1);
      expect(booking.property?.title, 'Sea View Villa 1');
      expect(booking.displayTitle, 'Sea View Villa 1');
      expect(booking.displayImage, 'https://cdn.example.com/p1/main.jpg');
      expect(booking.displayLocation, 'Goa, India');
      expect(booking.totalAmount, 12285.5);
      expect(booking.bookingReference, 'BK-2026-00011');
    });

    test('a booking without a property summary shows a plain title', () {
      final booking = Booking.fromJson(items(bookings['list_page']).last);
      expect(booking.property, isNull);
      expect(booking.displayTitle, 'Stay');
      expect(booking.displayImage, isEmpty);
      expect(booking.displayLocation, isEmpty);
    });

    test('statuses read the backend values', () {
      final list = items(bookings['list_page']).map(Booking.fromJson).toList();
      expect(list.first.bookingStatus, BookingStatus.pending);
      expect(list.first.paymentStatus, PaymentStatus.pending);
      expect(list.last.bookingStatus, BookingStatus.confirmed);
      expect(list.last.paymentStatus, PaymentStatus.paid);
    });

    test('an unknown status reads as null, not as pending', () {
      final json = items(bookings['list_page']).first
        ..['booking_status'] = 'teleported'
        ..['payment_status'] = 'bartered';
      final booking = Booking.fromJson(json);
      expect(booking.bookingStatus, isNull);
      expect(booking.paymentStatus, isNull);
    });

    test('stay dates are calendar dates, whatever the device time zone', () {
      final booking = Booking.fromJson(items(bookings['list_page']).first);
      expect(booking.checkInDate, DateTime(2026, 11, 10));
      expect(booking.checkOutDate, DateTime(2026, 11, 13));
      expect(booking.nights, 3);
    });

    test('created_at stays a UTC instant', () {
      final booking = Booking.fromJson(items(bookings['list_page']).first);
      expect(booking.createdAt.isUtc, isTrue);
      expect(booking.createdAt, DateTime.utc(2026, 9, 30, 10, 15, 2));
    });

    test('a booking without dates is rejected', () {
      final json = items(bookings['list_page']).first..remove('check_in_date');
      expect(() => Booking.fromJson(json), throwsFormatException);
    });
  });

  group('GET /bookings (cursor pages)', () {
    test('a page carries the cursor and the flag', () async {
      final adapter = RecordingAdapter((_) => FakeReply(bookings['list_page']));
      final page = await BookingsProvider(dio: fakeDio(adapter)).listBookings();
      expect(page.items.map((b) => b.id), [11, 12]);
      expect(page.hasNextPage, isTrue);
      expect(page.nextCursor, isNotEmpty);
      expectQueryDeclared(adapter.last, 'GET /api/v1/bookings');
    });

    test('the cursor goes back unchanged and the last page ends', () async {
      final adapter = RecordingAdapter((request) {
        return request.queryParameters.containsKey('cursor')
            ? FakeReply(bookings['last_page'])
            : FakeReply(bookings['list_page']);
      });
      final provider = BookingsProvider(dio: fakeDio(adapter));
      final first = await provider.listBookings();
      final second = await provider.listBookings(cursor: first.nextCursor);
      expect(queryOf(adapter.last)['cursor'], [first.nextCursor]);
      expect(second.items.map((b) => b.id), [13]);
      expect(second.hasNextPage, isFalse);
      expect(second.nextCursor, isNull);
    });
  });

  group('POST /bookings', () {
    final payload = buildInquiryPayload(
      propertyId: 1,
      checkIn: DateTime(2026, 11, 10),
      checkOut: DateTime(2026, 11, 13),
      guests: 2,
      primaryGuestName: 'Asha Verma',
      primaryGuestPhone: '+919800000000',
      primaryGuestEmail: 'asha@example.com',
      specialRequests: 'Late check-in',
    );

    test('the body satisfies BookingCreate', () {
      expectBodyMatches('BookingCreate', payload);
    });

    test('the body carries the Idempotency-Key it was given', () async {
      final adapter = RecordingAdapter(
        (_) => FakeReply(bookings['created'], status: 201),
      );
      final booking = await BookingsProvider(
        dio: fakeDio(adapter),
      ).createBooking(payload, idempotencyKey: 'key-1');
      expect(adapter.last.method, 'POST');
      expect(adapter.last.path, '/api/v1/bookings');
      expect(adapter.last.headers['Idempotency-Key'], 'key-1');
      expect(booking.id, 14);
    });

    test('a 422 reads its field errors from the envelope', () async {
      final adapter = RecordingAdapter(
        (_) => FakeReply(errors['validation'], status: 422),
      );
      await expectLater(
        BookingsProvider(
          dio: fakeDio(adapter),
        ).createBooking(payload, idempotencyKey: 'key-1'),
        throwsA(
          isA<ApiException>()
              .having((e) => e.statusCode, 'status', 422)
              .having((e) => e.code, 'code', 'VALIDATION_ERROR')
              .having((e) => e.fieldErrors.length, 'fields', 2)
              .having(
                (e) => e.fieldErrors.first.name,
                'first field',
                'primary_guest_email',
              ),
        ),
      );
    });
  });

  group('POST /bookings/calculate-pricing', () {
    test(
      'the body satisfies BookingAvailability and dates are YYYY-MM-DD',
      () async {
        final adapter = RecordingAdapter((_) => FakeReply(bookings['pricing']));
        final pricing = await BookingsProvider(dio: fakeDio(adapter))
            .calculatePricing(
              propertyId: 1,
              checkIn: '2026-11-10',
              checkOut: '2026-11-13',
              guests: 2,
            );
        final body = obj(adapter.last.data);
        expectBodyMatches('BookingAvailability', body);
        expect(body['check_in_date'], '2026-11-10');
        expect(pricing.totalAmount, 12285.5);
        expect(pricing.taxesAmount, 1260.5);
        expect(pricing.nights, 3);
        expect(pricing.hasValidAmounts, isTrue);
      },
    );

    test('a pricing error is a 4xx envelope with the server reason', () async {
      final adapter = RecordingAdapter(
        (_) => FakeReply(errors['pricing_unavailable'], status: 400),
      );
      await expectLater(
        BookingsProvider(dio: fakeDio(adapter)).calculatePricing(
          propertyId: 1,
          checkIn: '2026-11-10',
          checkOut: '2026-11-13',
          guests: 2,
        ),
        throwsA(
          isA<ApiException>()
              .having((e) => e.statusCode, 'status', 400)
              .having((e) => e.code, 'code', 'PRICING_UNAVAILABLE')
              .having(
                (e) => e.message,
                'message',
                'This stay has no nightly rate.',
              ),
        ),
      );
    });

    test('an unknown property is a 404 PROPERTY_NOT_FOUND', () async {
      final adapter = RecordingAdapter(
        (_) => FakeReply(errors['not_found'], status: 404),
      );
      await expectLater(
        BookingsProvider(dio: fakeDio(adapter)).calculatePricing(
          propertyId: 9,
          checkIn: '2026-11-10',
          checkOut: '2026-11-13',
          guests: 2,
        ),
        throwsA(
          isA<ApiException>().having(
            (e) => e.code,
            'code',
            'PROPERTY_NOT_FOUND',
          ),
        ),
      );
    });
  });

  group('POST /bookings/check-availability', () {
    test('sends {property_id, guests} and reads occupancy_ok', () async {
      final adapter = RecordingAdapter(
        (_) => FakeReply(bookings['occupancy_full']),
      );
      final result = await BookingsProvider(
        dio: fakeDio(adapter),
      ).checkOccupancy(propertyId: 1, guests: 9);
      final body = obj(adapter.last.data);
      expectBodyMatches('BookingOccupancyCheck', body);
      expect(body.keys, unorderedEquals(['property_id', 'guests']));
      expect(result.occupancyOk, isFalse);
      expect(result.reason, 'Maximum 4 guests');
      expect(result.maxOccupancy, 4);
    });

    test('an accepted guest count', () async {
      final adapter = RecordingAdapter(
        (_) => FakeReply(bookings['occupancy_ok']),
      );
      final result = await BookingsProvider(
        dio: fakeDio(adapter),
      ).checkOccupancy(propertyId: 1, guests: 2);
      expect(result.occupancyOk, isTrue);
      expect(result.reason, isNull);
    });
  });

  group('POST /bookings/cancel', () {
    test('the body satisfies BookingCancel', () async {
      final adapter = RecordingAdapter((_) => FakeReply(bookings['created']));
      await BookingsProvider(
        dio: fakeDio(adapter),
      ).cancelBooking(bookingId: 14, reason: 'Plans changed');
      expectBodyMatches('BookingCancel', obj(adapter.last.data));
    });
  });

  group('booking chat', () {
    test(
      'GET /bookings/{id}/messages is a cursor page, newest first',
      () async {
        final adapter = RecordingAdapter(
          (_) => FakeReply(bookings['messages_page']),
        );
        final page = await BookingsProvider(
          dio: fakeDio(adapter),
        ).listMessages(14, cursor: 'abc', limit: 30);
        expect(adapter.last.path, '/api/v1/bookings/14/messages');
        expectQueryDeclared(
          adapter.last,
          'GET /api/v1/bookings/{booking_id}/messages',
        );
        expect(page.items.map((m) => m.id), [502, 501]);
        expect(page.items.first.senderId, 7);
        expect(page.items.first.body, 'See you on the 10th.');
        expect(page.items.first.createdAt.isUtc, isTrue);
        expect(page.hasNextPage, isTrue);
      },
    );

    test('POST /bookings/{id}/messages sends {body} only', () async {
      final adapter = RecordingAdapter(
        (_) => FakeReply(bookings['message_created'], status: 201),
      );
      final message = await BookingsProvider(
        dio: fakeDio(adapter),
      ).sendMessage(14, 'Thanks!');
      expect(adapter.last.path, '/api/v1/bookings/14/messages');
      expectBodyMatches('BookingMessageCreate', obj(adapter.last.data));
      expect(message.id, 503);
      expect(message.senderId, 50);
      expect(message.isMine(50), isTrue);
      expect(message.isMine(7), isFalse);
    });

    test('a stranger gets 404 BOOKING_NOT_FOUND', () async {
      final adapter = RecordingAdapter(
        (_) => const FakeReply({
          'error': {
            'code': 'BOOKING_NOT_FOUND',
            'message': 'Booking not found',
          },
        }, status: 404),
      );
      await expectLater(
        BookingsProvider(dio: fakeDio(adapter)).listMessages(1),
        throwsA(
          isA<ApiException>().having(
            (e) => e.code,
            'code',
            'BOOKING_NOT_FOUND',
          ),
        ),
      );
    });
  });
}
