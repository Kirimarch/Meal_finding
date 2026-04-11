import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/restaurant.dart';
import '../services/places_service.dart';
import '../services/cache_service.dart';
import '../thai_coords.dart';
import 'search_filter_provider.dart';

import 'package:geolocator/geolocator.dart';

class SearchState {
  final bool isScanning;
  final Restaurant? restaurant;
  final String message;
  final Position? userPosition;

  const SearchState({
    this.isScanning = false,
    this.restaurant,
    this.message = 'พร้อมสุ่มเมนูเด็ดแล้ว!',
    this.userPosition,
  });

  SearchState copyWith({
    bool? isScanning,
    Restaurant? restaurant,
    bool clearRestaurant = false,
    String? message,
    Position? userPosition,
  }) {
    return SearchState(
      isScanning: isScanning ?? this.isScanning,
      restaurant: clearRestaurant ? null : (restaurant ?? this.restaurant),
      message: message ?? this.message,
      userPosition: userPosition ?? this.userPosition,
    );
  }
}

class SearchNotifier extends Notifier<SearchState> {
  bool _initialized = false;
  Future<void>? _cacheLoadFuture;

  @override
  SearchState build() {
    // โหลดข้อมูลจาก Cache — เก็บ Future ไว้เพื่อให้ startSearch() await ได้
    _initialized = false;
    _cacheLoadFuture = _loadFromCache();
    return const SearchState();
  }

  Future<void> _loadFromCache() async {
    final cached = await CacheService.getLastRestaurant();
    if (cached != null) {
      state = state.copyWith(
        restaurant: cached,
        message: 'ยินดีต้อนรับกลับ! นี่คือร้านล่าสุดที่คุณพบ',
      );
    }
    _initialized = true;
  }

  Future<void> startSearch(SearchFilterState filters) async {
    // รอให้ cache load เสร็จก่อน เพื่อป้องกัน race condition
    if (!_initialized) {
      await _cacheLoadFuture;
    }

    state = state.copyWith(
      isScanning: true,
      clearRestaurant: true,
      message: 'กำลังสแกนหาของอร่อย...',
    );

    try {
      // Look up coordinates for locationBias
      double? biasLat;
      double? biasLng;
      double biasRadius = 8000.0;
      Position? currentPos;

      if (filters.useCustomLocation && filters.province.isNotEmpty) {
        if (filters.district.isNotEmpty) {
          final coords = districtCoords[filters.province]?[filters.district];
          if (coords != null) {
            biasLat = coords[0];
            biasLng = coords[1];
            biasRadius = filters.subDistrict.isNotEmpty ? 3000.0 : 8000.0;
          }
        }
        if (biasLat == null) {
          final coords = provinceCoords[filters.province];
          if (coords != null) {
            biasLat = coords[0];
            biasLng = coords[1];
            biasRadius = 30000.0;
          }
        }
        
        // If we found bias coordinates, create a dummy Position object for distance calc
        if (biasLat != null && biasLng != null) {
          currentPos = Position(
            latitude: biasLat,
            longitude: biasLng,
            timestamp: DateTime.now(),
            accuracy: 0,
            altitude: 0,
            heading: 0,
            speed: 0,
            speedAccuracy: 0,
            altitudeAccuracy: 0,
            headingAccuracy: 0,
          );
        }
      } else {
        // Not using custom location, get actual GPS
        currentPos = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        );
      }

      final restaurant = await PlacesService.getRandomNearbyRestaurant(
        radius: filters.radius,
        categories: [filters.category],
        minRating: filters.minRating,
        openNow: filters.openNow,
        province: filters.useCustomLocation ? filters.province : null,
        district: filters.useCustomLocation ? filters.district : null,
        subDistrict: filters.useCustomLocation ? filters.subDistrict : null,
        searchLat: biasLat,
        searchLng: biasLng,
        searchBiasRadius: biasRadius,
      );

      await Future.delayed(const Duration(milliseconds: 1500));

      if (restaurant != null) {
        await CacheService.saveLastRestaurant(restaurant);
      }

      state = SearchState(
        isScanning: false,
        restaurant: restaurant,
        userPosition: currentPos,
        message: restaurant == null
            ? 'ไม่พบร้านใหม่ๆ เลย ลองเพิ่มระยะดูไหม?'
            : 'เจอแล้ว! ภารกิจสำเร็จ',
      );
    } catch (e) {
      state = SearchState(
        isScanning: false,
        message: 'เกิดข้อผิดพลาด: $e',
      );
    }
  }

  void selectRestaurant(Restaurant r) {
    state = SearchState(
      isScanning: false,
      restaurant: r,
      message: state.message,
    );
  }
}

final searchProvider =
    NotifierProvider<SearchNotifier, SearchState>(SearchNotifier.new);
