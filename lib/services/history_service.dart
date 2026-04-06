import 'package:shared_preferences/shared_preferences.dart';
import '../models/restaurant.dart';

class HistoryService {
  static const String _key = 'lunch_history';

  static Future<void> saveToHistory(Restaurant restaurant) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> history = prefs.getStringList(_key) ?? [];
    
    // บันทึกเฉพาะ 20 รายการล่าสุด
    history.insert(0, restaurant.toJson());
    if (history.length > 20) {
      history = history.sublist(0, 20);
    }
    
    await prefs.setStringList(_key, history);
  }

  static Future<List<Restaurant>> getHistory() async {
    final prefs = await SharedPreferences.getInstance();
    List<String> history = prefs.getStringList(_key) ?? [];
    return history.map((e) => Restaurant.fromJson(e)).toList();
  }

  static Future<void> removeFromHistory(String restaurantId) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> history = prefs.getStringList(_key) ?? [];
    history.removeWhere((e) {
      final r = Restaurant.fromJson(e);
      return r.id == restaurantId;
    });
    await prefs.setStringList(_key, history);
  }

  static Future<void> clearHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
