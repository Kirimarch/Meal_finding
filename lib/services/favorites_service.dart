import 'package:shared_preferences/shared_preferences.dart';
import '../models/restaurant.dart';

class FavoriteService {
  static const String _key = 'lunch_favorites';

  static Future<void> toggleFavorite(Restaurant restaurant) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> favorites = prefs.getStringList(_key) ?? [];

    final index = favorites.indexWhere((e) {
      try {
        return Restaurant.fromJson(e).id == restaurant.id;
      } catch (_) {
        return false;
      }
    });

    if (index >= 0) {
      favorites.removeAt(index);
    } else {
      favorites.insert(0, restaurant.toJson());
    }

    await prefs.setStringList(_key, favorites);
  }

  static Future<bool> isFavorite(String restaurantId) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> favorites = prefs.getStringList(_key) ?? [];
    return favorites.any((e) {
      try {
        return Restaurant.fromJson(e).id == restaurantId;
      } catch (_) {
        return false;
      }
    });
  }

  static Future<List<Restaurant>> getFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    List<String> favorites = prefs.getStringList(_key) ?? [];
    final List<Restaurant> result = [];
    for (final e in favorites) {
      try {
        result.add(Restaurant.fromJson(e));
      } catch (_) {
        // skip entry ที่เสียหาย
      }
    }
    return result;
  }

  static Future<void> removeFromFavorites(String restaurantId) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> favorites = prefs.getStringList(_key) ?? [];
    favorites.removeWhere((e) {
      try {
        return Restaurant.fromJson(e).id == restaurantId;
      } catch (_) {
        return true; // ลบ entry ที่เสียหายออกด้วย
      }
    });
    await prefs.setStringList(_key, favorites);
  }
}
