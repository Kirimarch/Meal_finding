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
    double radius = 1000.0,
    List<String>? categories,
    double minRating = 0.0,
    bool openNow = false,
    String? province,
    String? district,
    String? subDistrict,
    double? searchLat,
    double? searchLng,
    double searchBiasRadius = 8000.0,
  }) async {
    try {
      final String endpoint;
      final Map<String, dynamic> requestBody;
      const String fieldMask =
          'places.displayName,places.rating,places.formattedAddress,places.googleMapsUri,places.photos,places.editorialSummary,places.priceLevel,places.priceRange,places.name,places.currentOpeningHours,places.location';
      final category = (categories?.isNotEmpty == true)
          ? categories!.first
          : 'restaurant';

      if (province != null && province.isNotEmpty) {
        endpoint = 'https://places.googleapis.com/v1/places:searchText';

        String queryType = 'ร้านอาหาร';
        if (category == 'cafe') queryType = 'ร้านคาเฟ่ หรือ ของหวาน';
        if (category == 'fast_food_restaurant') {
          queryType =
              'McDonald\'s KFC Pizza Hut The Pizza Company Burger King Subway Texas Chicken Taco Bell Dairy Queen A&W';
        }
        if (category == 'japanese_restaurant') queryType = 'ร้านอาหารญี่ปุ่น';
        if (category == 'thai_restaurant') queryType = 'ร้านอาหารไทย';
        if (category == 'korean_restaurant') queryType = 'ร้านอาหารเกาหลี';
        if (category == 'chinese_restaurant') queryType = 'ร้านอาหารจีน';
        if (category == 'italian_restaurant') queryType = 'ร้านอาหารอิตาเลียน';
        if (category == 'seafood_restaurant') queryType = 'ร้านอาหารทะเล';
        if (category == 'steak_house') queryType = 'ร้านสเต็ก';
        if (category == 'pizza_restaurant') queryType = 'ร้านพิซซ่า';
        if (category == 'vegetarian_restaurant')
          queryType = 'ร้านอาหารมังสวิรัติ';

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
          if (category != 'fast_food_restaurant') "includedType": category,
          "pageSize": 20,
          if (searchLat != null && searchLng != null)
            "locationBias": {
              "circle": {
                "center": {"latitude": searchLat, "longitude": searchLng},
                "radius": searchBiasRadius,
              },
            },
        };
      } else {
        bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
        if (!serviceEnabled) {
          throw 'กรุณาเปิด GPS ในมือถือของคุณ';
        }

        LocationPermission permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.denied) {
          permission = await Geolocator.requestPermission();
          if (permission == LocationPermission.denied) {
            throw 'กรุณาอนุญาตสิทธิ์การเข้าถึงตำแหน่ง';
          }
        }

        if (permission == LocationPermission.deniedForever) {
          throw 'สิทธิ์การเข้าถึงตำแหน่งถูกปฏิเสธถาวร กรุณาไปตั้งค่าในมือถือ';
        }

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
              "radius": radius,
            },
          },
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
        final historyList = await HistoryService.getHistory();
        final recentIds = historyList.map((e) => e.id).toSet();

        // กรองเอาเฉพาะร้านที่ยังไม่มีในประวัติ และตรงตามเงื่อนไขดาว/เวลาเปิด
        List freshPlaces = allPlaces.where((p) {
          final String placeId = p['name'] ?? '';
          if (recentIds.contains(placeId)) return false;
          if (minRating > 0 && (p['rating'] ?? 0.0) < minRating) return false;
          if (openNow &&
              (p['currentOpeningHours'] == null ||
                  p['currentOpeningHours']['openNow'] != true))
            return false;
          return true;
        }).toList();

        if (freshPlaces.isEmpty) return null;

        final random = Random();
        final selectedJson = freshPlaces[random.nextInt(freshPlaces.length)];
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
