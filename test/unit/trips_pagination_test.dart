import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:stays_app/app/data/models/booking_model.dart';
import 'package:stays_app/app/data/models/cursor_page.dart';
import 'package:stays_app/app/data/providers/bookings_provider.dart';
import 'package:stays_app/core/providers/data_providers.dart';
import 'package:stays_app/core/providers/session_provider.dart';
import 'package:stays_app/features/trips/providers/trips_providers.dart';

import '../contract/support/wire.dart';

Booking _booking(int id) {
  final json = obj(fixture('bookings')['created'])..['id'] = id;
  return Booking.fromJson(json);
}

class _FakeBookings extends BookingsProvider {
  final cursors = <String?>[];
  Completer<void>? gate;

  @override
  Future<CursorPage<Booking>> listBookings({
    String? cursor,
    int limit = 20,
  }) async {
    cursors.add(cursor);
    await gate?.future;
    switch (cursor) {
      case null:
        return CursorPage(
          items: [_booking(3), _booking(2)],
          nextCursor: 'c2',
          hasMore: true,
          limit: 2,
        );
      case 'c2':
        return CursorPage(
          items: [_booking(1)],
          nextCursor: 'c3',
          hasMore: true,
          limit: 2,
        );
      default:
        return CursorPage(
          items: [_booking(0)],
          nextCursor: null,
          hasMore: false,
          limit: 2,
        );
    }
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(useTestConfig);

  late _FakeBookings fake;
  late ProviderContainer container;

  setUp(() async {
    fake = _FakeBookings();
    container = ProviderContainer(
      overrides: [
        accountIdProvider.overrideWithValue('user-a'),
        bookingsProviderProvider.overrideWithValue(fake),
      ],
    );
    addTearDown(container.dispose);
    container.read(tripsProvider);
    await pumpEventQueue();
  });

  List<int> ids() =>
      container.read(tripsProvider).bookings.map((b) => b.id).toList();

  test('the first page loads and keeps the server order', () {
    final state = container.read(tripsProvider);
    expect(ids(), [3, 2]);
    expect(state.isLoading, isFalse);
    expect(state.hasMore, isTrue);
    expect(state.nextCursor, 'c2');
    expect(fake.cursors, [null]);
  });

  test(
    'loadMore sends the cursor unchanged and appends the next page',
    () async {
      await container.read(tripsProvider.notifier).loadMore();
      expect(fake.cursors, [null, 'c2']);
      expect(ids(), [3, 2, 1]);
      expect(container.read(tripsProvider).nextCursor, 'c3');
    },
  );

  test('loadMore follows next_cursor to the last page, then stops', () async {
    final notifier = container.read(tripsProvider.notifier);
    await notifier.loadMore();
    await notifier.loadMore();
    expect(ids(), [3, 2, 1, 0]);
    final state = container.read(tripsProvider);
    expect(state.hasMore, isFalse);
    expect(state.nextCursor, isNull);

    await notifier.loadMore();
    expect(fake.cursors, [null, 'c2', 'c3']);
    expect(ids(), [3, 2, 1, 0]);
  });

  test('two loadMore calls at once read the page once', () async {
    fake.gate = Completer<void>();
    final notifier = container.read(tripsProvider.notifier);
    final first = notifier.loadMore();
    final second = notifier.loadMore();
    fake.gate!.complete();
    await Future.wait([first, second]);
    expect(fake.cursors, [null, 'c2']);
    expect(ids(), [3, 2, 1]);
  });

  test('refresh starts again from the first page', () async {
    final notifier = container.read(tripsProvider.notifier);
    await notifier.loadMore();
    await notifier.refresh();
    expect(ids(), [3, 2]);
    expect(fake.cursors.last, isNull);
    expect(container.read(tripsProvider).nextCursor, 'c2');
  });
}
