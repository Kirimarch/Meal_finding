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

  Restaurant({
    required this.id,
    required this.name,
    required this.address,
    required this.rating,
    required this.googleMapsUri,
    this.photoReference,
    this.summary,
    this.priceLevel,
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
      priceLevel: map['priceLevel'],
    );
  }

  // ใช้สำหรับตอนดึงจาก API
  factory Restaurant.fromApiJson(Map<String, dynamic> json) {
    String? photoName;
    if (json['photos'] != null && (json['photos'] as List).isNotEmpty) {
      photoName = json['photos'][0]['name'];
    }

    return Restaurant(
      id: json['name'] ?? '',
      name: json['displayName']?['text'] ?? 'ไม่ทราบชื่อ',
      address: json['formattedAddress'] ?? '',
      rating: (json['rating'] ?? 0.0).toDouble(),
      googleMapsUri: json['googleMapsUri'] ?? '',
      photoReference: photoName,
      summary: json['editorialSummary']?['text'],
      priceLevel: _parsePriceLevel(json['priceLevel']),
    );
  }

  static String? _parsePriceLevel(String? level) {
    if (level == null) return null;
    switch (level) {
      case 'PRICE_LEVEL_INEXPENSIVE': return '฿';
      case 'PRICE_LEVEL_MODERATE': return '฿฿';
      case 'PRICE_LEVEL_EXPENSIVE': return '฿฿฿';
      case 'PRICE_LEVEL_VERY_EXPENSIVE': return '฿฿฿฿';
      default: return null;
    }
  }

  String toJson() => json.encode(toMap());
  factory Restaurant.fromJson(String source) => Restaurant.fromMap(json.decode(source));
}
