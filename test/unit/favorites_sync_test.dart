import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stays_app/core/providers/favorites_provider.dart';

/// Unit tests for the canonical favorites id-set.
///
/// Covers the [FavoritesNotifier] write-through contract (replaceAll /
/// addAll / addFavorite / removeFavorite / clear) and the Explore / Listing
/// read path ([isFavorite]) with no Supabase, repository, or network.
void main() {
  late ProviderContainer container;
  late FavoritesNotifier notifier;

  setUp(() {
    container = ProviderContainer();
    notifier = container.read(favoritesProvider.notifier);
  });

  tearDown(() {
    container.dispose();
  });

  Set<int> readIds() => container.read(favoritesProvider);

  group('FavoritesNotifier id-set semantics', () {
    test('starts empty: isFavorite is false for any id', () {
      expect(readIds(), isEmpty);
      expect(notifier.isFavorite(1), isFalse);
    });

    test('addFavorite marks the id; duplicate add is idempotent', () {
      notifier.addFavorite(42);

      expect(notifier.isFavorite(42), isTrue);
      expect(readIds(), contains(42));

      notifier.addFavorite(42);

      expect(notifier.isFavorite(42), isTrue);
      expect(readIds().where((id) => id == 42), hasLength(1));
    });

    test('removeFavorite drops the id; unknown id is a no-op', () {
      notifier.addFavorite(1);
      notifier.addFavorite(2);

      notifier.removeFavorite(1);

      expect(notifier.isFavorite(1), isFalse);
      expect(notifier.isFavorite(2), isTrue);

      notifier.removeFavorite(999);

      expect(notifier.isFavorite(2), isTrue);
      expect(readIds(), hasLength(1));
    });

    test('replaceAll swaps the whole set (loadWishlist mirror)', () {
      notifier.addFavorite(1);
      notifier.addFavorite(2);

      notifier.replaceAll([2, 3]);

      expect(notifier.isFavorite(1), isFalse);
      expect(notifier.isFavorite(2), isTrue);
      expect(notifier.isFavorite(3), isTrue);
      expect(readIds(), hasLength(2));
    });

    test('replaceAll with empty clears everything', () {
      notifier.addFavorite(7);

      notifier.replaceAll([]);

      expect(readIds(), isEmpty);
      expect(notifier.isFavorite(7), isFalse);
    });

    test(
      'addAll unions ids without dropping earlier ones (loadMore mirror)',
      () {
        notifier.replaceAll([1, 2]);

        notifier.addAll([2, 3]);

        expect(notifier.isFavorite(1), isTrue);
        expect(notifier.isFavorite(2), isTrue);
        expect(notifier.isFavorite(3), isTrue);
        expect(readIds(), hasLength(3));
      },
    );

    test('clear empties the set (clearWishlist mirror)', () {
      notifier.replaceAll([1, 2, 3]);

      notifier.clear();

      expect(readIds(), isEmpty);
      expect(notifier.isFavorite(1), isFalse);
      expect(notifier.isFavorite(2), isFalse);
      expect(notifier.isFavorite(3), isFalse);
    });

    test('state updates notify listeners', () {
      var observedLength = -1;
      container.listen<Set<int>>(favoritesProvider, (_, next) {
        observedLength = next.length;
      });

      notifier.addFavorite(5);
      expect(observedLength, 1);

      notifier.removeFavorite(5);
      expect(observedLength, 0);
    });
  });
}
