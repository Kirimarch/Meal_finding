import 'dart:convert';

class Restaurant {
  final String id;
  final String name;
  final String address;
  final double rating;
  final String googleMapsUri;
  final String? photoReference;
  final String? summary;
  final String? priceLevel;
  final double? lat;
  final double? lng;

  Restaurant({
    required this.id,
    required this.name,
    required this.address,
    required this.rating,
    required this.googleMapsUri,
    this.photoReference,
    this.summary,
    this.priceLevel,
    this.lat,
    this.lng,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'address': address,
      'rating': rating,
      'googleMapsUri': googleMapsUri,
      'photoReference': photoReference,
      'summary': summary,
      'priceLevel': priceLevel,
      'lat': lat,
      'lng': lng,
    };
  }

  factory Restaurant.fromMap(Map<String, dynamic> map) {
    return Restaurant(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      address: map['address'] ?? '',
      rating: (map['rating'] ?? 0.0).toDouble(),
      googleMapsUri: map['googleMapsUri'] ?? '',
      photoReference: map['photoReference'],
      summary: map['summary'],
      priceLevel: _parsePriceLevel(map['priceLevel']),
      lat: (map['lat'] as num?)?.toDouble(),
      lng: (map['lng'] as num?)?.toDouble(),
    );
  }

  // ใช้สำหรับตอนดึงจาก API
  factory Restaurant.fromApiJson(Map<String, dynamic> json) {
    String? photoName;
    if (json['photos'] != null && (json['photos'] as List).isNotEmpty) {
      photoName = json['photos'][0]['name'];
    }

    // พยายามดึงข้อมูลจาก priceRange ก่อน (ถ้ามีช่วงราคาจริงจาก API)
    String? priceDisplay;
    if (json['priceRange'] != null) {
      final pr = json['priceRange'];
      final start = pr['startPrice']?['units'];
      final end = pr['endPrice']?['units'];
      if (start != null && end != null) {
        priceDisplay = '$start - $end.-';
      } else if (start != null) {
        priceDisplay = '$start.- ขึ้นไป';
      }
    }
    
    // ถ้าไม่มี priceRange ให้ใช้ priceLevel ตามปกติ
    return Restaurant(
      id: json['name'] ?? '',
      name: json['displayName']?['text'] ?? 'ไม่ทราบชื่อ',
      address: json['formattedAddress'] ?? '',
      rating: (json['rating'] ?? 0.0).toDouble(),
      googleMapsUri: json['googleMapsUri'] ?? '',
      photoReference: photoName,
      summary: json['editorialSummary']?['text'],
      priceLevel: priceDisplay ?? _parsePriceLevel(json['priceLevel']),
      lat: (json['location']?['latitude'] as num?)?.toDouble(),
      lng: (json['location']?['longitude'] as num?)?.toDouble(),
    );
  }

  static String? _parsePriceLevel(dynamic level) {
    if (level == null) return null;
    String lvl = level.toString();
    
    // จัดการค่าเดิมหรือค่าจากระดับต่าง ๆ
    if (lvl == '1' || lvl == 'PRICE_LEVEL_INEXPENSIVE' || lvl == '฿') {
      return 'น้อยกว่า 150.-';
    } else if (lvl == '2' || lvl == 'PRICE_LEVEL_MODERATE' || lvl == '฿฿') {
      return '150 - 500.-';
    } else if (lvl == '3' || lvl == 'PRICE_LEVEL_EXPENSIVE' || lvl == '฿฿฿') {
      return '500 - 1,500.-';
    } else if (lvl == '4' || lvl == 'PRICE_LEVEL_VERY_EXPENSIVE' || lvl == '฿฿฿฿') {
      return '1,500.- ขึ้นไป';
    }
    
    return null;
  }

  String toJson() => json.encode(toMap());
  factory Restaurant.fromJson(String source) =>
      Restaurant.fromMap(json.decode(source));
}
