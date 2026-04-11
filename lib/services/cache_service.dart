import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/restaurant.dart';

class CacheService {
  static const String _keyLastRestaurant = 'last_restaurant';

  static Future<void> saveLastRestaurant(Restaurant restaurant) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyLastRestaurant, json.encode(restaurant.toMap()));
  }

  static Future<Restaurant?> getLastRestaurant() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_keyLastRestaurant);
    if (data != null) {
      try {
        return Restaurant.fromMap(json.decode(data));
      } catch (e) {
        return null;
      }
    }
    return null;
  }
}
