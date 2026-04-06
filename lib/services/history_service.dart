import 'package:shared_preferences/shared_preferences.dart';
import '../models/restaurant.dart';

class HistoryService {
  static const String _key = 'lunch_history';

  static Future<void> saveToHistory(Restaurant restaurant) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> rawHistory = prefs.getStringList(_key) ?? [];
    
    // แปลงเป็น List ของ IDs เพื่อเช็คซ้ำ หรือเช็คจาก JSON ตรงๆ
    // วิธีง่ายที่สุด: ลบรายการเดิมที่มี ID ตรงกันออกก่อน (กันซ้ำ)
    rawHistory.removeWhere((item) {
      try {
        final r = Restaurant.fromJson(item);
        return r.id == restaurant.id;
      } catch (_) {
        return false;
      }
    });

    // แทรกรายการล่าสุดไว้บนสุด
    rawHistory.insert(0, restaurant.toJson());
    
    // บันทึกสูงสุด 20 รายการ
    if (rawHistory.length > 20) {
      rawHistory = rawHistory.sublist(0, 20);
    }
    
    await prefs.setStringList(_key, rawHistory);
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
