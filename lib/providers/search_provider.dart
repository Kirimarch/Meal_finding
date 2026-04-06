import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/restaurant.dart';
import '../services/places_service.dart';
import 'search_filter_provider.dart';

class SearchState {
  final bool isScanning;
  final Restaurant? restaurant;
  final String message;

  const SearchState({
    this.isScanning = false,
    this.restaurant,
    this.message = 'พร้อมสุ่มเมนูเด็ดแล้ว!',
  });

  SearchState copyWith({
    bool? isScanning,
    Restaurant? restaurant,
    bool clearRestaurant = false,
    String? message,
  }) {
    return SearchState(
      isScanning: isScanning ?? this.isScanning,
      restaurant: clearRestaurant ? null : (restaurant ?? this.restaurant),
      message: message ?? this.message,
    );
  }
}

class SearchNotifier extends Notifier<SearchState> {
  @override
  SearchState build() => const SearchState();

  Future<void> startSearch(SearchFilterState filters) async {
    state = state.copyWith(
      isScanning: true,
      clearRestaurant: true,
      message: 'กำลังสแกนหาของอร่อย...',
    );

    try {
      final restaurant = await PlacesService.getRandomNearbyRestaurant(
        radius: filters.radius,
        categories: [filters.category],
        minRating: filters.minRating,
        openNow: filters.openNow,
        province: filters.useCustomLocation ? filters.province : null,
        district: filters.useCustomLocation ? filters.district : null,
        subDistrict: filters.useCustomLocation ? filters.subDistrict : null,
      );

      await Future.delayed(const Duration(milliseconds: 1500));

      state = SearchState(
        isScanning: false,
        restaurant: restaurant,
        message: restaurant == null
            ? 'ไม่พบร้านใหม่ๆ เลย ลองเพิ่มระยะดูไหม?'
            : state.message,
      );
    } catch (_) {
      state = const SearchState(
        isScanning: false,
        message: 'เกิดข้อผิดพลาดในการโหลดข้อมูล',
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
