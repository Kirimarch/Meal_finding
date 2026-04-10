import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/search_filter_provider.dart';
import '../providers/search_provider.dart';
import '../services/history_service.dart';
import '../services/favorites_service.dart';
import '../widgets/category_filter_bar.dart';
import '../widgets/filter_panel.dart';
import '../widgets/result_card.dart';
import '../widgets/scanning_view.dart';
import '../widgets/initial_view.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  Future<void> _showHistory(BuildContext context, WidgetRef ref) async {
    final initialHistory = await HistoryService.getHistory();
    if (!context.mounted) return;

    var history = initialHistory;
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1A1A),
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(30))),
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 30),
            child: Column(
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(2)),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'ประวัติการสุ่มล่าสุด',
                      style: GoogleFonts.outfit(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white),
                    ),
                    if (history.isNotEmpty)
                      TextButton(
                        onPressed: () async {
                          await HistoryService.clearHistory();
                          setSheetState(() {
                            history = [];
                          });
                        },
                        child: const Text('ลบทั้งหมด',
                            style: TextStyle(color: Colors.redAccent)),
                      ),
                  ],
                ),
                const SizedBox(height: 5),
                const Text(
                  'ปัดซ้ายเพื่อลบรายชื่อ | สุ่มไม่ซ้ำ 20 รายการ',
                  style: TextStyle(color: Colors.white38, fontSize: 13),
                ),
                const Divider(height: 30, color: Colors.white12),
                Expanded(
                  child: history.isEmpty
                      ? Center(
                          child: Text('ยังไม่มีประวัติ',
                              style: GoogleFonts.outfit(color: Colors.white24)))
                      : ListView.builder(
                          itemCount: history.length,
                          itemBuilder: (context, index) {
                            final restaurant = history[index];
                            return Dismissible(
                              key: ValueKey(restaurant.id),
                              direction: DismissDirection.endToStart,
                              background: Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                alignment: Alignment.centerRight,
                                padding: const EdgeInsets.only(right: 20),
                                decoration: BoxDecoration(
                                  color: Colors.red.withOpacity(0.7),
                                  borderRadius: BorderRadius.circular(15),
                                ),
                                child: const Icon(Icons.delete_outline,
                                    color: Colors.white),
                              ),
                              onDismissed: (_) {
                                setSheetState(() {
                                  history = List.from(history)..removeAt(index);
                                });
                                HistoryService.removeFromHistory(restaurant.id);
                              },
                              child: Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.05),
                                    borderRadius: BorderRadius.circular(15)),
                                child: ListTile(
                                  leading: const CircleAvatar(
                                      backgroundColor: Colors.white10,
                                      child: Icon(Icons.history,
                                          color: Colors.amber, size: 20)),
                                  title: Text(restaurant.name,
                                      style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w600)),
                                  subtitle: Text(restaurant.address,
                                      style: const TextStyle(
                                          color: Colors.white38, fontSize: 12),
                                      maxLines: 1),
                                  onTap: () {
                                    Navigator.pop(context);
                                    ref
                                        .read(searchProvider.notifier)
                                        .selectRestaurant(restaurant);
                                  },
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _showFavorites(BuildContext context, WidgetRef ref) async {
    final initialFavorites = await FavoriteService.getFavorites();
    if (!context.mounted) return;

    var favorites = initialFavorites;
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1A1A),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(30))),
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) {
          return Container(
            height: MediaQuery.of(context).size.height * 0.7,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 30),
            child: Column(
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(2)),
                ),
                const SizedBox(height: 20),
                Text(
                  'ร้านโปรดของคุณ ❤️',
                  style: GoogleFonts.outfit(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white),
                ),
                const SizedBox(height: 5),
                const Text(
                  'ร้านที่คุณบันทึกไว้จะแสดงที่นี่',
                  style: TextStyle(color: Colors.white38, fontSize: 13),
                ),
                const Divider(height: 30, color: Colors.white12),
                Expanded(
                  child: favorites.isEmpty
                      ? Center(
                          child: Text('ยังไม่มีร้านโปรดเลย',
                              style: GoogleFonts.outfit(color: Colors.white24)))
                      : ListView.builder(
                          itemCount: favorites.length,
                          itemBuilder: (context, index) {
                            final restaurant = favorites[index];
                            return Dismissible(
                              key: ValueKey('fav_${restaurant.id}'),
                              direction: DismissDirection.endToStart,
                              background: Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                alignment: Alignment.centerRight,
                                padding: const EdgeInsets.only(right: 20),
                                decoration: BoxDecoration(
                                  color: Colors.red.withOpacity(0.7),
                                  borderRadius: BorderRadius.circular(15),
                                ),
                                child: const Icon(Icons.favorite_border,
                                    color: Colors.white),
                              ),
                              onDismissed: (_) {
                                setSheetState(() {
                                  favorites = List.from(favorites)..removeAt(index);
                                });
                                FavoriteService.removeFromFavorites(restaurant.id);
                              },
                              child: Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.05),
                                    borderRadius: BorderRadius.circular(15)),
                                child: ListTile(
                                  leading: const CircleAvatar(
                                      backgroundColor: Colors.white10,
                                      child: Icon(Icons.favorite,
                                          color: Colors.pinkAccent, size: 20)),
                                  title: Text(restaurant.name,
                                      style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w600)),
                                  subtitle: Text(restaurant.address,
                                      style: const TextStyle(
                                          color: Colors.white38, fontSize: 12),
                                      maxLines: 1),
                                  onTap: () {
                                    Navigator.pop(context);
                                    ref
                                        .read(searchProvider.notifier)
                                        .selectRestaurant(restaurant);
                                  },
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }


  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final searchState = ref.watch(searchProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'MEAL FINDER',
          style: GoogleFonts.outfit(
              fontWeight: FontWeight.w900,
              letterSpacing: 1.5,
              color: Colors.white),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.favorite_rounded, color: Colors.pinkAccent),
            onPressed: () => _showFavorites(context, ref),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: IconButton(
              icon: const Icon(Icons.history_toggle_off_rounded,
                  color: Colors.white70),
              onPressed: () => _showHistory(context, ref),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          const SizedBox(height: 10),
          const CategoryFilterBar(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 100),
              child: Column(
                children: [
                  const FilterPanel(),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 600),
                      switchInCurve: Curves.easeOutBack,
                      child: searchState.isScanning
                          ? const ScanningView()
                          : searchState.restaurant != null
                              ? ResultCard(
                                  restaurant: searchState.restaurant!,
                                  userPosition: searchState.userPosition,
                                  onReshuffle: () => ref.read(searchProvider.notifier).startSearch(ref.read(searchFilterProvider)),
                                )
                              : InitialView(message: searchState.message),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        width: double.infinity,
        height: 65,
        child: FloatingActionButton.extended(
          onPressed: searchState.isScanning
              ? null
              : () {
                  final filters = ref.read(searchFilterProvider);
                  ref.read(searchProvider.notifier).startSearch(filters);
                },
          backgroundColor: const Color(0xFFEB1555),
          elevation: 8,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          label: Text(
            searchState.isScanning ? 'กำลังค้นหาร้านอร่อย...' : 'เริ่มสุ่มเลย!',
            style: GoogleFonts.outfit(
                fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 1),
          ),
        ),
      ),
    );
  }
}
