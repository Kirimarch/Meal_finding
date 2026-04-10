import 'package:flutter_riverpod/flutter_riverpod.dart';

class SearchFilterState {
  final String category;
  final double radius;
  final double minRating;
  final bool openNow;
  final bool useCustomLocation;
  final String province;
  final String district;
  final String subDistrict;

  const SearchFilterState({
    this.category = 'restaurant',
    this.radius = 1000.0,
    this.minRating = 0.0,
    this.openNow = false,
    this.useCustomLocation = false,
    this.province = '',
    this.district = '',
    this.subDistrict = '',
  });

  SearchFilterState copyWith({
    String? category,
    double? radius,
    double? minRating,
    bool? openNow,
    bool? useCustomLocation,
    String? province,
    String? district,
    String? subDistrict,
  }) {
    return SearchFilterState(
      category: category ?? this.category,
      radius: radius ?? this.radius,
      minRating: minRating ?? this.minRating,
      openNow: openNow ?? this.openNow,
      useCustomLocation: useCustomLocation ?? this.useCustomLocation,
      province: province ?? this.province,
      district: district ?? this.district,
      subDistrict: subDistrict ?? this.subDistrict,
    );
  }
}

class SearchFilterNotifier extends Notifier<SearchFilterState> {
  @override
  SearchFilterState build() => const SearchFilterState();

  void setCategory(String value) => state = state.copyWith(category: value);

  void setRadius(double value) => state = state.copyWith(radius: value);

  void setMinRating(double value) => state = state.copyWith(minRating: value);

  void setOpenNow(bool value) => state = state.copyWith(openNow: value);

  void setUseCustomLocation(bool value) => state = state.copyWith(
        useCustomLocation: value,
        province: '',
        district: '',
        subDistrict: '',
      );

  void setProvince(String value) => state = state.copyWith(
        province: value,
        district: '',
        subDistrict: '',
      );

  void setDistrict(String value) => state = state.copyWith(
        district: value,
        subDistrict: '',
      );

  void setSubDistrict(String value) => state = state.copyWith(subDistrict: value);
}

final searchFilterProvider =
    NotifierProvider<SearchFilterNotifier, SearchFilterState>(
        SearchFilterNotifier.new);

final filterExpandedProvider = StateProvider<bool>((ref) => false);
