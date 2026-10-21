import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:stays_app/app/data/models/booking_model.dart';
import 'package:stays_app/app/data/models/cursor_page.dart';
import 'package:stays_app/app/data/providers/bookings_provider.dart';
import 'package:stays_app/core/providers/data_providers.dart';
import 'package:stays_app/core/providers/session_provider.dart';
import 'package:stays_app/features/trips/views/trips_screen.dart';

import '../contract/support/wire.dart';

Booking _booking(int id, {String status = 'pending', String? title}) {
  final json = obj(fixture('bookings')['created'])
    ..['id'] = id
    ..['booking_status'] = status
    // No photo: the widget test has no image cache.
    ..['property'] = title == null
        ? null
        : {'id': 1, 'title': title, 'city': 'Goa', 'country': 'India'};
  return Booking.fromJson(json);
}

class _FakeBookings extends BookingsProvider {
  final cursors = <String?>[];

  @override
  Future<CursorPage<Booking>> listBookings({
    String? cursor,
    int limit = 20,
  }) async {
    cursors.add(cursor);
    if (cursor == null) {
      return CursorPage(
        items: [
          _booking(2, status: 'confirmed', title: 'Beach House'),
          _booking(1, status: 'cancelled', title: 'Hill Cabin'),
        ],
        nextCursor: 'c2',
        hasMore: true,
        limit: 2,
      );
    }
    return CursorPage(
      items: [_booking(0)],
      nextCursor: null,
      hasMore: false,
      limit: 2,
    );
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(useTestConfig);

  Future<_FakeBookings> pumpTrips(WidgetTester tester) async {
    final fake = _FakeBookings();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          accountIdProvider.overrideWithValue('user-a'),
          bookingsProviderProvider.overrideWithValue(fake),
        ],
        child: const MaterialApp(home: TripsScreen()),
      ),
    );
    await tester.pumpAndSettle();
    return fake;
  }

  testWidgets('shows the booking title and status from the property summary', (
    tester,
  ) async {
    await pumpTrips(tester);
    expect(find.text('Beach House'), findsOneWidget);
    expect(find.text('Hill Cabin'), findsOneWidget);
    expect(find.text('confirmed'), findsOneWidget);
    expect(find.text('cancelled'), findsOneWidget);
    expect(find.text('Stay'), findsNothing);
  });

  testWidgets('Load more reads the next page with the cursor', (tester) async {
    final fake = await pumpTrips(tester);
    expect(fake.cursors, [null]);
    expect(find.text('Stay'), findsNothing);

    await tester.tap(find.text('Load more'));
    await tester.pumpAndSettle();

    expect(fake.cursors, [null, 'c2']);
    // The first page is kept. The new row has no property summary, so it
    // shows the plain title.
    expect(find.text('Beach House'), findsOneWidget);
    expect(find.text('Stay'), findsOneWidget);
    // The last page has no footer.
    expect(find.text('Load more'), findsNothing);
  });
}
