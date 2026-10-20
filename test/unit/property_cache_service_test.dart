import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:stays_app/app/data/models/property_model.dart';
import 'package:stays_app/app/data/models/unified_property_response.dart';
import 'package:stays_app/app/data/services/property_cache_service.dart';

import '../contract/support/wire.dart';

const _ownerNumber = '+911800000360';

UnifiedPropertyResponse _page({bool noStore = false}) {
  return UnifiedPropertyResponse.fromJson(
    fixture('properties')['list_page'],
    noStore: noStore,
  );
}

Property _property() =>
    Property.fromJson(items(fixture('properties')['list_page']).first);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(useTestConfig);

  final cache = PropertyCacheService();
  late SharedPreferences prefs;

  setUpAll(() async {
    // Builds before the account scope wrote `pc_` keys. They held the contact
    // number of the owner.
    SharedPreferences.setMockInitialValues({
      'pc_explore_results_19.07_72.88_first': jsonEncode({
        'items': [
          {'id': 1, 'owner_contact': _ownerNumber},
        ],
      }),
      'pc_explore_results_19.07_72.88_first_timestamp': 'x',
      'pc_property_1': jsonEncode({'id': 1, 'owner_contact': _ownerNumber}),
      'pc_recommendations': '[]',
      'unrelated_key': 'keep',
    });
    prefs = await SharedPreferences.getInstance();
    await cache.init();
  });

  setUp(() async {
    cache.accountScope = () => 'user-1';
    await cache.clearAll();
  });

  bool storedAnywhere(String text) =>
      prefs.getKeys().any((k) => '${prefs.get(k)}'.contains(text));

  test('init removes the old keys and keeps the others', () {
    expect(prefs.getKeys().where((k) => k.startsWith('pc_')), isEmpty);
    expect(prefs.getString('unrelated_key'), 'keep');
  });

  test('explore pages never hold an owner contact number', () async {
    final page = _page();
    await cache.cacheExploreResults(page, lat: 15.5, lng: 73.7);
    expect(storedAnywhere('owner_contact'), isFalse);
    expect(storedAnywhere(_ownerNumber), isFalse);

    final back = cache.getCachedExploreResults(lat: 15.5, lng: 73.7)!;
    expect(back.items.map((p) => p.id), [1, 2]);
    expect(back.items.first.pricePerNight, 3500);
    expect(back.nextCursor, page.nextCursor);
    expect(back.hasMore, isTrue);
  });

  test(
    'details and recommendations never hold an owner contact number',
    () async {
      final property = _property();
      await cache.cachePropertyDetails(property);
      await cache.cacheRecommendations([property]);
      expect(storedAnywhere('owner_contact'), isFalse);
      expect(storedAnywhere(_ownerNumber), isFalse);
      expect(cache.getCachedPropertyDetails(1)?.name, 'Sea View Villa 1');
      expect(cache.getCachedRecommendations()?.single.id, 1);
    },
  );

  test('another account never reads these entries', () async {
    await cache.cacheExploreResults(_page(), lat: 15.5, lng: 73.7);
    await cache.cachePropertyDetails(_property());
    await cache.cacheRecommendations([_property()]);

    cache.accountScope = () => 'user-2';
    expect(cache.getCachedExploreResults(lat: 15.5, lng: 73.7), isNull);
    expect(cache.getCachedPropertyDetails(1), isNull);
    expect(cache.getCachedRecommendations(), isNull);
    // Even an offline read ignores the scope check only for expiry.
    expect(
      cache.getCachedExploreResults(lat: 15.5, lng: 73.7, ignoreExpiry: true),
      isNull,
    );

    cache.accountScope = () => 'user-1';
    expect(cache.getCachedPropertyDetails(1), isNotNull);
  });

  test('a signed-out reader has its own scope', () async {
    await cache.cachePropertyDetails(_property());
    cache.accountScope = () => 'anon';
    expect(cache.getCachedPropertyDetails(1), isNull);
  });

  test('clearAll purges every account', () async {
    await cache.cachePropertyDetails(_property());
    cache.accountScope = () => 'user-2';
    await cache.cachePropertyDetails(_property());
    await cache.cacheExploreResults(_page());

    await cache.clearAll();

    expect(prefs.getKeys().where((k) => k.startsWith('pcache_')), isEmpty);
    expect(cache.getCachedPropertyDetails(1), isNull);
    cache.accountScope = () => 'user-1';
    expect(cache.getCachedPropertyDetails(1), isNull);
    expect(prefs.getString('unrelated_key'), 'keep');
  });

  test('an entry of another schema version is ignored', () async {
    Future<void> setVersion(String keyPart, int version) async {
      final key = prefs.getKeys().firstWhere(
        (k) => k.contains(keyPart) && !k.endsWith('_timestamp'),
      );
      final data = jsonDecode(prefs.getString(key)!) as Map<String, dynamic>;
      data['schema_version'] = version;
      await prefs.setString(key, jsonEncode(data));
    }

    await cache.cacheExploreResults(_page(), lat: 15.5, lng: 73.7);
    await cache.cachePropertyDetails(_property());
    await cache.cacheRecommendations([_property()]);

    await setVersion('_explore_', 1);
    await setVersion('property_1', 1);
    await setVersion('recommendations', 1);

    expect(cache.getCachedExploreResults(lat: 15.5, lng: 73.7), isNull);
    expect(cache.getCachedPropertyDetails(1), isNull);
    expect(cache.getCachedRecommendations(), isNull);
  });

  test('every store has its own version constant', () {
    expect(PropertyCacheService.exploreSchemaVersion, isPositive);
    expect(PropertyCacheService.detailsSchemaVersion, isPositive);
    expect(PropertyCacheService.recommendationsSchemaVersion, isPositive);
  });

  test('a no-store response is not written', () async {
    await cache.cacheExploreResults(_page(noStore: true), lat: 1, lng: 2);
    await cache.cachePropertyDetails(_property(), noStore: true);
    await cache.cacheRecommendations([_property()], noStore: true);
    expect(prefs.getKeys().where((k) => k.startsWith('pcache_')), isEmpty);
    expect(cache.getCachedExploreResults(lat: 1, lng: 2), isNull);
    expect(cache.getCachedPropertyDetails(1), isNull);
  });

  test('a page cached for one filter set is not served for another', () async {
    await cache.cacheExploreResults(_page(), lat: 1, lng: 2, variant: 'a');
    expect(
      cache.getCachedExploreResults(lat: 1, lng: 2, variant: 'a'),
      isNotNull,
    );
    expect(cache.getCachedExploreResults(lat: 1, lng: 2, variant: 'b'), isNull);
    expect(cache.getCachedExploreResults(lat: 1, lng: 2), isNull);
  });

  test('an expired entry is ignored unless the read is offline', () async {
    await cache.cachePropertyDetails(_property());
    final stamp = prefs.getKeys().firstWhere((k) => k.endsWith('_timestamp'));
    await prefs.setString(
      stamp,
      DateTime.now().subtract(const Duration(hours: 3)).toIso8601String(),
    );
    expect(cache.getCachedPropertyDetails(1), isNull);
    expect(cache.getCachedPropertyDetails(1, ignoreExpiry: true), isNotNull);
  });
}
