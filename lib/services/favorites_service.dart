import 'package:shared_preferences/shared_preferences.dart';
import '../models/restaurant.dart';

class FavoriteService {
  static const String _key = 'lunch_favorites';

  static Future<void> toggleFavorite(Restaurant restaurant) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> favorites = prefs.getStringList(_key) ?? [];
    
    final index = favorites.indexWhere((e) => Restaurant.fromJson(e).id == restaurant.id);
    
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
    return favorites.any((e) => Restaurant.fromJson(e).id == restaurantId);
  }

  static Future<List<Restaurant>> getFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    List<String> favorites = prefs.getStringList(_key) ?? [];
    return favorites.map((e) => Restaurant.fromJson(e)).toList();
  }

  static Future<void> removeFromFavorites(String restaurantId) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> favorites = prefs.getStringList(_key) ?? [];
    favorites.removeWhere((e) => Restaurant.fromJson(e).id == restaurantId);
    await prefs.setStringList(_key, favorites);
  }
}
