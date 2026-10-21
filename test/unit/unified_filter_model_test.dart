import 'package:flutter_test/flutter_test.dart';

import 'package:stays_app/app/data/models/property_model.dart';
import 'package:stays_app/app/data/models/unified_filter_model.dart';
import 'package:stays_app/app/data/models/wire_enums.dart';

Property _stay({double? price, PropertyType? type = PropertyType.villa}) {
  return Property(
    id: 1,
    name: 'Stay',
    propertyType: type,
    city: 'Goa',
    country: 'India',
    pricePerNight: price,
  );
}

void main() {
  test('an empty filter sends nothing', () {
    expect(UnifiedFilterModel.empty.isEmpty, isTrue);
    expect(UnifiedFilterModel.empty.toQueryParameters(), isEmpty);
  });

  test('a list filter stays a list of wire values', () {
    final query = UnifiedFilterModel(
      propertyTypes: const [PropertyType.builderFloor, PropertyType.pg],
    ).toQueryParameters();
    expect(query['property_type'], ['builder_floor', 'pg']);
  });

  test('sort_by is a backend SortBy value', () {
    expect(
      UnifiedFilterModel(
        sortBy: SortBy.priceHigh,
      ).toQueryParameters()['sort_by'],
      'price_high',
    );
  });

  test('radius is a whole number between 1 and 100', () {
    expect(UnifiedFilterModel(radiusKm: 25).toQueryParameters()['radius'], 25);
    expect(
      UnifiedFilterModel(radiusKm: 500).toQueryParameters()['radius'],
      100,
    );
    expect(UnifiedFilterModel(radiusKm: 0).toQueryParameters()['radius'], 1);
    expect(
      UnifiedFilterModel(radiusKm: 25).toQueryParameters()['radius'],
      isA<int>(),
    );
  });

  test('a price filter drops a listing without a nightly rate', () {
    final filter = UnifiedFilterModel(minPrice: 1000, maxPrice: 5000);
    expect(filter.matchesProperty(_stay(price: 2500)), isTrue);
    expect(filter.matchesProperty(_stay(price: 500)), isFalse);
    expect(filter.matchesProperty(_stay(price: 9000)), isFalse);
    expect(filter.matchesProperty(_stay()), isFalse);
    expect(UnifiedFilterModel.empty.matchesProperty(_stay()), isTrue);
  });

  test('a type filter compares enum values', () {
    final filter = UnifiedFilterModel(
      propertyTypes: const [PropertyType.villa],
    );
    expect(filter.matchesProperty(_stay()), isTrue);
    expect(filter.matchesProperty(_stay(type: PropertyType.house)), isFalse);
    expect(filter.matchesProperty(_stay(type: null)), isFalse);
  });

  test('equal filters are equal', () {
    expect(
      UnifiedFilterModel(
        propertyTypes: const [PropertyType.villa],
        sortBy: SortBy.newest,
        radiusKm: 10,
      ),
      UnifiedFilterModel(
        propertyTypes: const [PropertyType.villa],
        sortBy: SortBy.newest,
        radiusKm: 10,
      ),
    );
  });
}
