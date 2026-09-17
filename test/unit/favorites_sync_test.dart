import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:stays_app/app/controllers/favorites_controller.dart';

/// Pure unit test for the canonical favorites id-set.
///
/// Covers the [WishlistController] write-through contract (replaceAll /
/// addAll / addFavorite / removeFavorite / clear) and the Explore / Listing /
/// mixin read path ([isFavorite]) with no Supabase, repository, or network.
void main() {
  Get.testMode = true;

  late FavoritesController controller;

  setUp(() {
    controller = FavoritesController();
  });

  group('FavoritesController id-set semantics', () {
    test('starts empty: isFavorite is false for any id', () {
      expect(controller.favoriteIds, isEmpty);
      expect(controller.isFavorite(1), isFalse);
    });

    test('addFavorite marks the id; duplicate add is idempotent', () {
      controller.addFavorite(42);

      expect(controller.isFavorite(42), isTrue);
      expect(controller.favoriteIds, contains(42));

      controller.addFavorite(42);

      expect(controller.isFavorite(42), isTrue);
      expect(controller.favoriteIds.where((id) => id == 42), hasLength(1));
    });

    test('removeFavorite drops the id; unknown id is a no-op', () {
      controller.addFavorite(1);
      controller.addFavorite(2);

      controller.removeFavorite(1);

      expect(controller.isFavorite(1), isFalse);
      expect(controller.isFavorite(2), isTrue);

      controller.removeFavorite(999);

      expect(controller.isFavorite(2), isTrue);
      expect(controller.favoriteIds, hasLength(1));
    });

    test('replaceAll swaps the whole set (loadWishlist mirror)', () {
      controller.addFavorite(1);
      controller.addFavorite(2);

      controller.replaceAll([2, 3]);

      expect(controller.isFavorite(1), isFalse);
      expect(controller.isFavorite(2), isTrue);
      expect(controller.isFavorite(3), isTrue);
      expect(controller.favoriteIds, hasLength(2));
    });

    test('replaceAll with empty clears everything', () {
      controller.addFavorite(7);

      controller.replaceAll([]);

      expect(controller.favoriteIds, isEmpty);
      expect(controller.isFavorite(7), isFalse);
    });

    test(
      'addAll unions ids without dropping earlier ones (loadMore mirror)',
      () {
        controller.replaceAll([1, 2]);

        controller.addAll([2, 3]);

        expect(controller.isFavorite(1), isTrue);
        expect(controller.isFavorite(2), isTrue);
        expect(controller.isFavorite(3), isTrue);
        expect(controller.favoriteIds, hasLength(3));
      },
    );

    test('clear empties the set (clearWishlist mirror)', () {
      controller.replaceAll([1, 2, 3]);

      controller.clear();

      expect(controller.favoriteIds, isEmpty);
      expect(controller.isFavorite(1), isFalse);
      expect(controller.isFavorite(2), isFalse);
      expect(controller.isFavorite(3), isFalse);
    });

    test('favoriteIds is reactive: Obx-style listener sees writes', () {
      var observedLength = -1;
      final worker = ever(controller.favoriteIds, (_) {
        observedLength = controller.favoriteIds.length;
      });

      controller.addFavorite(5);
      expect(observedLength, 1);

      controller.removeFavorite(5);
      expect(observedLength, 0);

      worker.dispose();
    });
  });
}
