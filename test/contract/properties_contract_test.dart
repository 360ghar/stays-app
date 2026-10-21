// Contract tests for the property routes: GET /properties, GET /properties/{id},
// GET /properties/recommendations and GET /swipes.
//
// The fixtures are the backend's own `CursorPage[Property]` and `PropertyDetail`
// dumps (tool/api_fixtures.py).

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:stays_app/app/data/models/property_model.dart';
import 'package:stays_app/app/data/models/unified_filter_model.dart';
import 'package:stays_app/app/data/models/unified_property_response.dart';
import 'package:stays_app/app/data/models/wire_enums.dart';
import 'package:stays_app/app/data/providers/properties_provider.dart';
import 'package:stays_app/app/data/providers/swipes_provider.dart';

import 'support/wire.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(useTestConfig);

  final properties = fixture('properties');
  final swipes = fixture('swipes');

  group('Property parsing', () {
    test('a short stay reads nightly_rate as the nightly price', () {
      final page = UnifiedPropertyResponse.fromJson(properties['list_page']);
      final stay = page.items.first;
      expect(stay.pricePerNight, 3500);
      expect(stay.hasPrice, isTrue);
      expect(stay.displayPrice, '₹3500');
      expect(stay.priceUnit, ' / night');
      expect(stay.purpose, PropertyPurpose.shortStay);
      expect(stay.propertyType, PropertyType.villa);
      expect(stay.status, PropertyStatus.available);
      expect(stay.distanceKm, 2.4);
    });

    test('a rent listing has no nightly price and none is made up', () {
      final page = UnifiedPropertyResponse.fromJson(properties['mixed_page']);
      final rent = page.items.last;
      expect(rent.purpose, PropertyPurpose.rent);
      // base_price is 0 (a monthly anchor) and monthly_rent is 45000. Neither
      // becomes a nightly price.
      expect(rent.basePrice, 0);
      expect(rent.monthlyRent, 45000);
      expect(rent.pricePerNight, isNull);
      expect(rent.hasPrice, isFalse);
      expect(rent.displayPrice, 'Price on request');
      expect(rent.priceUnit, isEmpty);
    });

    test('amenities are objects with id, title, icon and category', () {
      final stay = Property.fromJson(items(properties['list_page']).first);
      final amenities = stay.amenities!;
      expect(amenities.map((a) => a.id), [11, 12]);
      expect(amenities.map((a) => a.title), ['Swimming Pool', 'Wi-Fi']);
      expect(amenities.first.icon, 'pool');
      expect(amenities.first.category, 'recreation');
      expect(amenities.last.icon, isNull);
      expect(amenities.last.category, isNull);
    });

    test('the detail response parses with its agent and floor plans split', () {
      final detail = Property.fromJson(obj(properties['detail']));
      expect(detail.id, 1);
      expect(detail.name, 'Sea View Villa 1');
      expect(detail.virtualTourUrl, 'https://tours.example.com/t/abc');
      expect(detail.hasVirtualTour, isTrue);
      expect(detail.maxGuests, 4);
      expect(detail.minimumStay, 2);
      // The floor_plan row moved to floor_plans, so images holds photos only.
      expect(detail.images!.map((i) => i.id), [11, 12]);
    });

    test('an unknown enum value reads as null and is not replaced', () {
      final json = items(properties['list_page']).first
        ..['property_type'] = 'castle'
        ..['purpose'] = 'timeshare'
        ..['status'] = 'haunted';
      final property = Property.fromJson(json);
      expect(property.propertyType, isNull);
      expect(property.purpose, isNull);
      expect(property.status, isNull);
      expect(property.propertyTypeDisplay, 'Property');
    });

    test('a listing without a city reads an empty city', () {
      final json = items(properties['list_page']).first..['city'] = null;
      expect(Property.fromJson(json).city, isEmpty);
    });
  });

  group('Property persistence', () {
    test('the app keeps no owner contact number', () {
      final json = items(properties['list_page']).first;
      // The backend sends the agent or company number to a non-owner.
      expect(json['owner_contact'], '+911800000360');
      final written = jsonEncode(Property.fromJson(json).toJson());
      expect(written, isNot(contains('owner_contact')));
      expect(written, isNot(contains('+911800000360')));
    });

    test('a property survives a write and read cycle', () {
      final stay = Property.fromJson(items(properties['list_page']).first);
      final back = Property.fromJson(
        jsonDecode(jsonEncode(stay.toJson())) as Map<String, dynamic>,
      );
      expect(back.id, stay.id);
      expect(back.pricePerNight, stay.pricePerNight);
      expect(back.propertyType, PropertyType.villa);
      expect(back.amenities!.map((a) => a.title), ['Swimming Pool', 'Wi-Fi']);
    });
  });

  group('GET /properties on the wire', () {
    late RecordingAdapter adapter;
    late PropertiesProvider provider;

    setUp(() {
      adapter = RecordingAdapter((_) => FakeReply(properties['list_page']));
      provider = PropertiesProvider(dio: fakeDio(adapter));
    });

    test('a list filter is sent as repeated keys', () async {
      final filters = UnifiedFilterModel(
        propertyTypes: const [PropertyType.villa, PropertyType.house],
        minPrice: 1000,
        sortBy: SortBy.priceLow,
      );
      await provider.explore(
        lat: 15.5,
        lng: 73.7,
        radiusKm: 100,
        filters: filters.toQueryParameters(),
      );
      final query = queryOf(adapter.last);
      expect(query['property_type'], ['villa', 'house']);
      expect(adapter.last.uri.query, isNot(contains('%2C')));
      expect(query['sort_by'], ['price_low']);
      expect(query['price_min'], ['1000.0']);
    });

    test('radius is a whole number', () async {
      await provider.explore(lat: 15.5, lng: 73.7, radiusKm: 100);
      expect(queryOf(adapter.last)['radius'], ['100']);
      await provider.explore(lat: 15.5, lng: 73.7, radiusKm: 250);
      expect(queryOf(adapter.last)['radius'], ['100']);
    });

    test('only declared query keys are sent', () async {
      await provider.explore(
        lat: 15.5,
        lng: 73.7,
        cursor: 'abc',
        limit: 30,
        radiusKm: 100,
        filters: UnifiedFilterModel(
          propertyTypes: const [PropertyType.villa],
          minPrice: 1,
          maxPrice: 9,
          minBedrooms: 1,
          maxBedrooms: 3,
          minBathrooms: 1,
          maxBathrooms: 2,
          sortBy: SortBy.newest,
          city: 'Goa',
          radiusKm: 50,
        ).toQueryParameters(),
      );
      expectQueryDeclared(adapter.last, 'GET /api/v1/properties');
    });

    test('the filter model has no key the backend ignores', () {
      final keys = UnifiedFilterModel(
        minPrice: 1,
        propertyTypes: const [PropertyType.villa],
        sortBy: SortBy.popular,
        city: 'Goa',
        radiusKm: 5,
      ).toQueryParameters().keys;
      for (final dropped in const [
        'rating_min',
        'instant_book',
        'self_check_in',
        'pets_allowed',
        'smoking_allowed',
      ]) {
        expect(keys, isNot(contains(dropped)));
      }
    });

    test('a page reads its cursor and flags', () async {
      final page = await provider.explore(lat: 15.5, lng: 73.7);
      expect(page.items.map((p) => p.id), [1, 2]);
      expect(page.hasMore, isTrue);
      expect(page.nextCursor, isNotEmpty);
      expect(page.hasNextPage, isTrue);
      expect(page.limit, 30);
      expect(page.total, isNull);
    });

    test('the last page has no next page', () async {
      adapter.reply = (_) => FakeReply(properties['last_page']);
      final page = await provider.explore(lat: 15.5, lng: 73.7);
      expect(page.hasNextPage, isFalse);
      expect(page.nextCursor, isNull);
    });

    test('Cache-Control no-store is reported to the caller', () async {
      adapter.reply = (_) => FakeReply(
        properties['list_page'],
        headers: {'cache-control': 'private, no-store'},
      );
      expect((await provider.explore(lat: 1, lng: 2)).noStore, isTrue);
      adapter.reply = (_) => FakeReply(properties['list_page']);
      expect((await provider.explore(lat: 1, lng: 2)).noStore, isFalse);
    });
  });

  group('GET /properties/{id} and recommendations on the wire', () {
    test('detail parses and reports no-store', () async {
      final adapter = RecordingAdapter(
        (_) => FakeReply(
          properties['detail'],
          headers: {'cache-control': 'no-store'},
        ),
      );
      final result = await PropertiesProvider(
        dio: fakeDio(adapter),
      ).getDetails(1);
      expect(adapter.last.path, '/api/v1/properties/1');
      expect(result.property.name, 'Sea View Villa 1');
      expect(result.noStore, isTrue);
    });

    test('recommendations are a CursorPage', () async {
      final adapter = RecordingAdapter(
        (_) => FakeReply(properties['recommendations']),
      );
      final page = await PropertiesProvider(
        dio: fakeDio(adapter),
      ).recommendations();
      expect(page.items.single.id, 6);
      expectQueryDeclared(
        adapter.last,
        'GET /api/v1/properties/recommendations',
      );
    });
  });

  group('swipes', () {
    test('history page parses with liked set', () async {
      final adapter = RecordingAdapter(
        (_) => FakeReply(swipes['history_page']),
      );
      final page = await SwipesProvider(
        dio: fakeDio(adapter),
      ).list(isLiked: true, cursor: 'abc');
      expect(page.items.every((p) => p.liked == true), isTrue);
      expect(page.items.every((p) => p.isFavorite), isTrue);
      expect(page.hasNextPage, isTrue);
      expectQueryDeclared(adapter.last, 'GET /api/v1/swipes');
      expect(queryOf(adapter.last)['is_liked'], ['true']);
    });

    test('POST /swipes sends the SwipeCreate keys only', () async {
      final adapter = RecordingAdapter(
        (_) => FakeReply(swipes['created'], status: 201),
      );
      await SwipesProvider(
        dio: fakeDio(adapter),
      ).swipe(propertyId: 1, isLiked: true);
      expect(adapter.last.method, 'POST');
      expectBodyMatches('SwipeCreate', obj(adapter.last.data));
    });

    test('POST /swipes/batch-remove sends the declared keys only', () async {
      final adapter = RecordingAdapter(
        (_) => FakeReply(swipes['batch_removed']),
      );
      await SwipesProvider(dio: fakeDio(adapter)).batchRemove([1, 2]);
      expectBodyMatches('BatchRemoveRequest', obj(adapter.last.data));
    });
  });
}
