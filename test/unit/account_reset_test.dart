// Account-bound providers hold one account's data in memory. They must reset
// on sign-out and when another user signs in during the same app run, and a
// request that started for the old account must not write into the new state.

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:stays_app/app/data/models/booking_model.dart';
import 'package:stays_app/app/data/models/cursor_page.dart';
import 'package:stays_app/app/data/models/unified_property_response.dart';
import 'package:stays_app/app/data/providers/bookings_provider.dart';
import 'package:stays_app/app/data/providers/swipes_provider.dart';
import 'package:stays_app/app/data/repositories/properties_repository.dart';
import 'package:stays_app/app/data/repositories/wishlist_repository.dart';
import 'package:stays_app/app/data/services/location_service.dart';
import 'package:stays_app/core/providers/data_providers.dart';
import 'package:stays_app/core/providers/favorites_provider.dart';
import 'package:stays_app/core/providers/session_provider.dart';
import 'package:stays_app/features/explore/providers/explore_providers.dart';
import 'package:stays_app/features/trips/providers/trips_providers.dart';
import 'package:stays_app/features/wishlist/providers/wishlist_providers.dart';

import '../contract/support/wire.dart';

/// A Supabase client whose user and auth events the test controls.
class _FakeAuth extends Fake implements GoTrueClient {
  User? user;
  final events = StreamController<AuthState>.broadcast();

  @override
  User? get currentUser => user;

  @override
  Stream<AuthState> get onAuthStateChange => events.stream;

  void emit(AuthChangeEvent event, User? next) {
    user = next;
    events.add(AuthState(event, null));
  }
}

class _FakeClient extends Fake implements SupabaseClient {
  _FakeClient(this.auth);

  @override
  final GoTrueClient auth;
}

User _user(String id) => User(
  id: id,
  appMetadata: const {},
  userMetadata: const {},
  aud: 'authenticated',
  createdAt: '2026-01-01T00:00:00Z',
);

/// Stands in for the Supabase session: the test signs users in and out.
class _Session extends Notifier<String?> {
  @override
  String? build() => 'user-a';

  void as(String? id) => state = id;
}

final _session = NotifierProvider<_Session, String?>(_Session.new);

class _FakeBookings extends BookingsProvider {
  int calls = 0;
  Completer<void>? gate;

  @override
  Future<CursorPage<Booking>> listBookings({
    String? cursor,
    int limit = 20,
  }) async {
    final id = ++calls;
    await gate?.future;
    final json = obj(fixture('bookings')['created'])..['id'] = id;
    return CursorPage(
      items: [Booking.fromJson(json)],
      nextCursor: null,
      hasMore: false,
      limit: limit,
    );
  }
}

class _FakeLocation extends Fake implements LocationService {
  @override
  String get currentCity => 'Goa';

  @override
  String get locationName => 'Goa, India';

  @override
  double get latitude => 15.3;

  @override
  double get longitude => 74.0;
}

class _FakeProperties extends Fake implements PropertiesRepository {
  int calls = 0;

  @override
  Future<UnifiedPropertyResponse> explore({
    double? lat,
    double? lng,
    String? cursor,
    int limit = 20,
    int radiusKm = 10,
    Map<String, dynamic>? filters,
    bool forceRefresh = false,
  }) async {
    calls++;
    return UnifiedPropertyResponse.fromJson(fixture('properties')['list_page']);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(useTestConfig);

  late _FakeBookings bookings;
  late _FakeProperties properties;
  late RecordingAdapter swipes;
  late ProviderContainer container;

  int wishlistCalls() => swipes.requests.where((r) => r.method == 'GET').length;

  setUp(() async {
    bookings = _FakeBookings();
    properties = _FakeProperties();
    final liked = items(fixture('swipes')['history_page']).first;
    swipes = RecordingAdapter(
      (_) => FakeReply({
        'items': [
          {...liked, 'id': 7},
          {...liked, 'id': 8},
        ],
        'next_cursor': null,
        'has_more': false,
        'limit': 20,
        'total': null,
      }),
    );
    container = ProviderContainer(
      overrides: [
        accountIdProvider.overrideWith((ref) => ref.watch(_session)),
        bookingsProviderProvider.overrideWithValue(bookings),
        propertiesRepositoryProvider.overrideWithValue(properties),
        locationServiceProvider.overrideWithValue(_FakeLocation()),
        wishlistRepositoryProvider.overrideWithValue(
          WishlistRepository(provider: SwipesProvider(dio: fakeDio(swipes))),
        ),
      ],
    );
    addTearDown(container.dispose);

    // Keep the providers alive, as the screens do.
    for (final provider in [
      tripsProvider,
      wishlistProvider,
      favoritesProvider,
      exploreProvider,
    ]) {
      container.listen(provider, (_, _) {});
    }
    await pumpEventQueue();
  });

  void signInAs(String? id) => container.read(_session.notifier).as(id);

  test('account A loads its data', () {
    expect(container.read(tripsProvider).bookings.map((b) => b.id), [1]);
    expect(container.read(wishlistProvider).items.map((p) => p.id), [7, 8]);
    expect(container.read(favoritesProvider), {7, 8});
    expect(container.read(exploreProvider).popular, isNotEmpty);
  });

  test(
    'sign-out empties every account-bound provider and loads nothing',
    () async {
      signInAs(null);
      await pumpEventQueue();

      expect(container.read(tripsProvider).bookings, isEmpty);
      expect(container.read(wishlistProvider).items, isEmpty);
      expect(container.read(favoritesProvider), isEmpty);
      final explore = container.read(exploreProvider);
      expect(explore.popular, isEmpty);
      expect(explore.nearby, isEmpty);
      // Nobody is signed in: no request goes out.
      expect(bookings.calls, 1);
      expect(wishlistCalls(), 1);
      expect(properties.calls, 1);
    },
  );

  test('the next account loads from the API again', () async {
    signInAs(null);
    await pumpEventQueue();
    signInAs('user-b');
    await pumpEventQueue();

    expect(bookings.calls, 2);
    expect(wishlistCalls(), 2);
    expect(properties.calls, 2);
    // Booking 2 is account B's: nothing of account A is left.
    expect(container.read(tripsProvider).bookings.map((b) => b.id), [2]);
    expect(container.read(favoritesProvider), {7, 8});
  });

  test('switching straight to another account resets too', () async {
    signInAs('user-b');
    await pumpEventQueue();

    expect(bookings.calls, 2);
    expect(container.read(tripsProvider).bookings.map((b) => b.id), [2]);
  });

  test('the same account keeps its state', () async {
    signInAs('user-a');
    await pumpEventQueue();

    expect(bookings.calls, 1);
    expect(wishlistCalls(), 1);
  });

  test('an answer for the old account is dropped', () async {
    // Account A asks for its trips. The answer comes after A signed out.
    final gate = bookings.gate = Completer<void>();
    final pending = container
        .read(tripsProvider.notifier)
        .load(forceRefresh: true);
    signInAs(null);
    await pumpEventQueue();
    gate.complete();
    await pending;
    await pumpEventQueue();

    expect(container.read(tripsProvider).bookings, isEmpty);
  });

  test('accountIdProvider follows the Supabase session', () async {
    final auth = _FakeAuth()..user = _user('user-a');
    addTearDown(auth.events.close);
    final c = ProviderContainer(
      overrides: [supabaseClientProvider.overrideWithValue(_FakeClient(auth))],
    );
    addTearDown(c.dispose);
    final seen = <String?>[];
    c.listen(accountIdProvider, (_, id) => seen.add(id), fireImmediately: true);

    auth.emit(AuthChangeEvent.tokenRefreshed, _user('user-a'));
    await pumpEventQueue();
    auth.emit(AuthChangeEvent.signedOut, null);
    await pumpEventQueue();
    auth.emit(AuthChangeEvent.signedIn, _user('user-b'));
    await pumpEventQueue();

    // A token refresh keeps the id, so it tells nobody.
    expect(seen, ['user-a', null, 'user-b']);
  });
}
