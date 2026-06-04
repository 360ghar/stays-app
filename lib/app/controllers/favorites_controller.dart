import 'package:get/get.dart';

class FavoritesController extends GetxController {
  FavoritesController();

  final RxSet<int> favoriteIds = <int>{}.obs;

  bool isFavorite(int propertyId) => favoriteIds.contains(propertyId);

  void replaceAll(Iterable<int> ids) {
    favoriteIds.assignAll(ids);
  }

  void addFavorite(int propertyId) {
    favoriteIds.add(propertyId);
  }

  void addAll(Iterable<int> ids) {
    favoriteIds.addAll(ids);
  }

  void removeFavorite(int propertyId) {
    favoriteIds.remove(propertyId);
  }

  void clear() {
    favoriteIds.clear();
  }
}
