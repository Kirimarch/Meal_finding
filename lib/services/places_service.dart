import 'dart:convert';
import 'dart:math';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import '../models/restaurant.dart';
import 'history_service.dart';

class PlacesService {
  static String get _apiKey => dotenv.env['GOOGLE_PLACES_API_KEY'] ?? '';

  static String getPhotoUrl(String photoName, {int maxWidth = 800}) {
    return 'https://places.googleapis.com/v1/$photoName/media?key=$_apiKey&maxWidthPx=$maxWidth';
  }

  static Future<Restaurant?> getRandomNearbyRestaurant({
    double radius = 1500.0,
    List<String>? categories,
    double minRating = 0.0,
    bool openNow = false,
    String? province,
    String? district,
    String? subDistrict,
  }) async {
    try {
      final String endpoint;
      final Map<String, dynamic> requestBody;
      final String fieldMask = 'places.displayName,places.rating,places.formattedAddress,places.googleMapsUri,places.photos,places.editorialSummary,places.priceLevel,places.name,places.currentOpeningHours';
      final category = (categories?.isNotEmpty == true) ? categories!.first : 'restaurant';

      if (province != null && province.isNotEmpty) {
        endpoint = 'https://places.googleapis.com/v1/places:searchText';
        
        String queryType = 'ร้านอาหาร';
        if (category == 'cafe') queryType = 'คาเฟ่ หรือ ของหวาน';
        if (category == 'fast_food_restaurant') queryType = 'ฟาสต์ฟู้ด';
        if (category == 'japanese_restaurant') queryType = 'อาหารญี่ปุ่น';
        if (category == 'thai_restaurant') queryType = 'อาหารไทย';
        if (category == 'korean_restaurant') queryType = 'อาหารเกาหลี';
        if (category == 'chinese_restaurant') queryType = 'อาหารจีน';
        if (category == 'italian_restaurant') queryType = 'อาหารอิตาเลียน';
        if (category == 'seafood_restaurant') queryType = 'อาหารทะเล';
        if (category == 'steak_house') queryType = 'สเต็ก';
        if (category == 'pizza_restaurant') queryType = 'พิซซ่า';
        if (category == 'vegetarian_restaurant') queryType = 'อาหารมังสวิรัติ';

        String query = queryType;
        if (subDistrict != null && subDistrict.isNotEmpty) {
          String subPrefix = (province == 'กรุงเทพมหานคร') ? 'แขวง' : 'ตำบล';
          query += ' $subPrefix$subDistrict';
        }
        if (district != null && district.isNotEmpty) {
          if (province == 'กรุงเทพมหานคร') {
            // Bangkok districts already start with 'เขต' in our data
            query += ' $district';
          } else {
            query += ' อำเภอ$district';
          }
        }
        query += ' จังหวัด$province';

        requestBody = {
          "textQuery": query,
          "pageSize": 20,
        };
      } else {
        Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        );
        endpoint = 'https://places.googleapis.com/v1/places:searchNearby';
        requestBody = {
          "includedTypes": [category],
          "maxResultCount": 20,
          "locationRestriction": {
            "circle": {
              "center": {
                "latitude": position.latitude,
                "longitude": position.longitude,
              },
              "radius": radius
            }
          }
        };
      }

      final response = await http.post(
        Uri.parse(endpoint),
        headers: {
          'Content-Type': 'application/json',
          'X-Goog-Api-Key': _apiKey,
          'X-Goog-FieldMask': fieldMask,
        },
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        List allPlaces = data['places'] ?? [];

        if (allPlaces.isEmpty) return null;

        // --- ระบบป้องกันร้านซ้ำใน 20 โรลล่าสุด ---
        final history = await HistoryService.getHistory();
        final recentIds = history.map((e) => e.id).toSet();

        // กรองเอาเฉพาะร้านที่ยังไม่มีในประวัติ และตรงตามเงื่อนไขดาว/เวลาเปิด
        List freshPlaces = allPlaces.where((p) {
          if (recentIds.contains(p['name'])) return false;
          if (minRating > 0 && (p['rating'] ?? 0.0) < minRating) return false;
          if (openNow && (p['currentOpeningHours'] == null || p['currentOpeningHours']['openNow'] != true)) return false;
          return true;
        }).toList();

        // ถ้าทุกคนในลิสต์ 20 ร้านนี้เคยไปหมดแล้ว (หายากมาก) ให้ใช้ลิสต์เดิมทั้งหมดเพื่อป้องกันแอปค้าง
        List finalPool = freshPlaces.isEmpty ? allPlaces : freshPlaces;

        final random = Random();
        final selectedJson = finalPool[random.nextInt(finalPool.length)];
        final selected = Restaurant.fromApiJson(selectedJson);
        
        // บันทึกลงประวัติ
        await HistoryService.saveToHistory(selected);
        
        return selected;
      } else {
        throw 'Error ${response.statusCode}: ${response.body}';
      }
    } catch (e) {
      rethrow;
    }
  }
}
