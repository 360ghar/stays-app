import 'package:flutter_test/flutter_test.dart';
import 'package:stays_app/app/data/models/property_model.dart';
import 'package:stays_app/features/explore/providers/explore_providers.dart';

Property _stay({
  required int id,
  required String city,
  double? distanceKm,
  String name = 'Stay',
}) {
  return Property(
    id: id,
    name: '$name $id',
    propertyType: 'hotel',
    city: city,
    country: 'India',
    pricePerNight: 1000,
    distanceKm: distanceKm,
  );
}

void main() {
  group('normalizeCity', () {
    test('lowercases and trims', () {
      expect(normalizeCity('  New Delhi '), 'new delhi');
    });
  });

  group('greetingFor', () {
    test('morning before 12', () {
      expect(greetingFor(DateTime(2026, 1, 1, 9)), 'Good morning');
    });

    test('afternoon before 17', () {
      expect(greetingFor(DateTime(2026, 1, 1, 14)), 'Good afternoon');
    });

    test('evening from 17', () {
      expect(greetingFor(DateTime(2026, 1, 1, 20)), 'Good evening');
    });
  });

  group('nearestOf', () {
    test('picks smallest distance', () {
      final props = [
        _stay(id: 1, city: 'Goa', distanceKm: 12),
        _stay(id: 2, city: 'Goa', distanceKm: 3),
        _stay(id: 3, city: 'Goa', distanceKm: 8),
      ];
      expect(nearestOf(props)?.id, 2);
    });

    test('returns null when no distances', () {
      expect(nearestOf([_stay(id: 1, city: 'Goa')]), isNull);
      expect(nearestOf([]), isNull);
    });
  });

  group('partitionExplore', () {
    test('splits in-city vs nearby and sorts by distance', () {
      final props = [
        _stay(id: 1, city: 'Goa', distanceKm: 9),
        _stay(id: 2, city: 'Mumbai', distanceKm: 50),
        _stay(id: 3, city: 'goa ', distanceKm: 2),
        _stay(id: 4, city: 'Pune', distanceKm: 30),
      ];
      final parts = partitionExplore(props, 'Goa');
      expect(parts.inCity.map((p) => p.id), [3, 1]);
      expect(parts.nearby.map((p) => p.id), [4, 2]);
    });
  });

  group('ExploreUiState', () {
    test('featured is nearest across both lists', () {
      const state = ExploreUiState();
      expect(state.featured, isNull);
      final populated = state.copyWith(
        popular: [_stay(id: 1, city: 'Goa', distanceKm: 5)],
        nearby: [_stay(id: 2, city: 'Pune', distanceKm: 2)],
      );
      expect(populated.featured?.id, 2);
      expect(populated.popularExcludingFeatured.map((p) => p.id), [1]);
      expect(populated.nearbyExcludingFeatured, isEmpty);
    });
  });
}
