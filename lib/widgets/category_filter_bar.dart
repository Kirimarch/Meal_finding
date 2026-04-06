import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/search_filter_provider.dart';

class _MouseAndTouchScrollBehavior extends MaterialScrollBehavior {
  @override
  Set<PointerDeviceKind> get dragDevices => {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
      };
}

class CategoryFilterBar extends ConsumerWidget {
  const CategoryFilterBar({super.key});

  static const Map<String, String> _categories = {
    'ทั้งหมด': 'restaurant',
    'คาเฟ่ / ขนม': 'cafe',
    'ฟาสต์ฟู้ด': 'fast_food_restaurant',
    'ไทย': 'thai_restaurant',
    'ญี่ปุ่น': 'japanese_restaurant',
    'เกาหลี': 'korean_restaurant',
    'จีน': 'chinese_restaurant',
    'อิตาเลียน': 'italian_restaurant',
    'ซีฟู้ด': 'seafood_restaurant',
    'สเต็ก': 'steak_house',
    'พิซซ่า': 'pizza_restaurant',
    'มังสวิรัติ': 'vegetarian_restaurant',
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedCategory = ref.watch(searchFilterProvider).category;

    return SizedBox(
      height: 48,
      child: ScrollConfiguration(
        behavior: _MouseAndTouchScrollBehavior(),
        child: ListView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        children: _categories.entries.map((entry) {
          final isSelected = selectedCategory == entry.value;
          return Padding(
            padding: const EdgeInsets.only(right: 10),
            child: InkWell(
              onTap: () =>
                  ref.read(searchFilterProvider.notifier).setCategory(entry.value),
              borderRadius: BorderRadius.circular(15),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                padding: const EdgeInsets.symmetric(horizontal: 18),
                decoration: BoxDecoration(
                  color: isSelected
                      ? const Color(0xFFEB1555)
                      : Colors.white.withOpacity(0.04),
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: const Color(0xFFEB1555).withOpacity(0.3),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          )
                        ]
                      : [],
                ),
                alignment: Alignment.center,
                child: Text(
                  entry.key,
                  style: GoogleFonts.outfit(
                    color: isSelected ? Colors.white : Colors.white38,
                    fontWeight:
                        isSelected ? FontWeight.bold : FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
        ),
      ),
    );
  }
}
