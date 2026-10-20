// Clear all removes every liked property: it follows next_cursor for the pages
// that are not loaded, and it sends at most 100 ids per batch-remove call
// (BatchRemoveRequest.property_ids has maxItems 100).

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stays_app/app/data/providers/swipes_provider.dart';
import 'package:stays_app/app/data/repositories/wishlist_repository.dart';
import 'package:stays_app/core/providers/data_providers.dart';
import 'package:stays_app/core/providers/session_provider.dart';
import 'package:stays_app/features/wishlist/providers/wishlist_providers.dart';

import '../contract/support/wire.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(useTestConfig);

  final swipes = fixture('swipes');
  final template = items(swipes['history_page']).first;
  Map<String, dynamic> liked(int id) => {...template, 'id': id};

  Map<String, dynamic> page(List<int> ids, {String? next}) => {
    'items': [for (final id in ids) liked(id)],
    'next_cursor': next,
    'has_more': next != null,
    'limit': 100,
    'total': null,
  };

  test('clearAll collects unloaded pages and chunks the ids by 100', () async {
    final adapter = RecordingAdapter((request) {
      if (request.method == 'POST') return FakeReply(swipes['batch_removed']);
      return request.uri.queryParameters['cursor'] == null
          ? FakeReply(page([1], next: 'c1'))
          : FakeReply(page([for (var i = 100; i < 220; i++) i]));
    });
    final container = ProviderContainer(
      overrides: [
        accountIdProvider.overrideWithValue('user-a'),
        wishlistRepositoryProvider.overrideWithValue(
          WishlistRepository(provider: SwipesProvider(dio: fakeDio(adapter))),
        ),
      ],
    );
    addTearDown(container.dispose);

    final notifier = container.read(wishlistProvider.notifier);
    await notifier.load();
    await pumpEventQueue();
    expect(container.read(wishlistProvider).hasMore, isTrue);

    await notifier.clearAll();

    final posts = adapter.requests.where((r) => r.method == 'POST').toList();
    final sent = [
      for (final post in posts) (obj(post.data)['property_ids'] as List).length,
    ];
    expect(sent, [100, 21]);
    for (final post in posts) {
      expectBodyMatches('BatchRemoveRequest', obj(post.data));
    }
    final cursorGets = adapter.requests.where(
      (r) => r.method == 'GET' && r.uri.queryParameters['cursor'] == 'c1',
    );
    expect(cursorGets.single.uri.queryParameters['limit'], '100');
    expect(container.read(wishlistProvider).items, isEmpty);
  });

  test('batchRemove sends nothing for an empty list', () async {
    final adapter = RecordingAdapter((_) => FakeReply(swipes['batch_removed']));
    await SwipesProvider(dio: fakeDio(adapter)).batchRemove(const []);
    expect(adapter.requests, isEmpty);
  });
}
