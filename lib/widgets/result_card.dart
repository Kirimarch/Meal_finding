import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/restaurant.dart';
import '../services/places_service.dart';
import '../services/favorites_service.dart';

import 'package:geolocator/geolocator.dart';

class ResultCard extends StatefulWidget {
  final Restaurant restaurant;
  final Position? userPosition;

  const ResultCard({super.key, required this.restaurant, this.userPosition});

  @override
  State<ResultCard> createState() => _ResultCardState();
}

class _ResultCardState extends State<ResultCard> {
  bool _isFavorite = false;

  @override
  void initState() {
    super.initState();
    _checkFavorite();
  }

  @override
  void didUpdateWidget(ResultCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.restaurant.id != widget.restaurant.id) {
      _checkFavorite();
    }
  }

  Future<void> _checkFavorite() async {
    final isFav = await FavoriteService.isFavorite(widget.restaurant.id);
    if (mounted) {
      setState(() {
        _isFavorite = isFav;
      });
    }
  }

  Future<void> _toggleFavorite() async {
    await FavoriteService.toggleFavorite(widget.restaurant);
    setState(() {
      _isFavorite = !_isFavorite;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isFavorite
                ? 'เพิ่มลงในรายการโปรดแล้ว! ❤️'
                : 'เอาออกจากรายการโปรดแล้ว',
          ),
          duration: const Duration(seconds: 1),
          behavior: SnackBarBehavior.floating,
          backgroundColor: _isFavorite ? Colors.pinkAccent : Colors.grey[800],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }

  Future<void> _viewOnMap() async {
    final url = Uri.parse(widget.restaurant.googleMapsUri);
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _launchNavigation() async {
    final restaurant = widget.restaurant;

    // ถ้ามีพิกัด ให้ลองใช้ Directions API เพื่อนำทางทันที
    if (restaurant.lat != null && restaurant.lng != null) {
      final lat = restaurant.lat;
      final lng = restaurant.lng;

      // ลองใช้ Google Navigation Intent (สำหรับ Android)
      final googleMapsIntentUri = Uri.parse('google.navigation:q=$lat,$lng');
      // แผนสำรอง: ใช้ Google Maps Directions URL
      final googleMapsWebUri = Uri.parse(
        'https://www.google.com/maps/dir/?api=1&destination=$lat,$lng',
      );

      try {
        if (await canLaunchUrl(googleMapsIntentUri)) {
          await launchUrl(googleMapsIntentUri);
          return;
        } else if (await canLaunchUrl(googleMapsWebUri)) {
          await launchUrl(
            googleMapsWebUri,
            mode: LaunchMode.externalApplication,
          );
          return;
        }
      } catch (e) {
        debugPrint('Error launching navigation: $e');
      }
    }

    // แผนสำรองสุดท้าย: ใช้ลิงก์เดิมที่ได้จาก API
    final url = Uri.parse(restaurant.googleMapsUri);
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  String get _distanceStr {
    if (widget.userPosition == null ||
        widget.restaurant.lat == null ||
        widget.restaurant.lng == null) {
      return '';
    }
    final distanceInMeters = Geolocator.distanceBetween(
      widget.userPosition!.latitude,
      widget.userPosition!.longitude,
      widget.restaurant.lat!,
      widget.restaurant.lng!,
    );
    if (distanceInMeters < 1000) {
      return '${distanceInMeters.toStringAsFixed(0)} ม.';
    } else {
      return '${(distanceInMeters / 1000).toStringAsFixed(1)} กม.';
    }
  }

  @override
  Widget build(BuildContext context) {
    final restaurant = widget.restaurant;
    final dist = _distanceStr;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.4),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ส่วนของรูปภาพ
          Stack(
            children: [
              SizedBox(
                height: 200,
                width: double.infinity,
                child: restaurant.photoReference != null
                    ? Image.network(
                        PlacesService.getPhotoUrl(restaurant.photoReference!),
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Container(
                            color: Colors.grey[900],
                            child: const Center(
                              child: CircularProgressIndicator(),
                            ),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) => Container(
                          color: Colors.grey[900],
                          child: const Icon(
                            Icons.image_not_supported,
                            size: 50,
                            color: Colors.white24,
                          ),
                        ),
                      )
                    : Container(
                        color: Colors.grey[900],
                        child: const Icon(
                          Icons.restaurant,
                          size: 50,
                          color: Colors.white24,
                        ),
                      ),
              ),
              // Gradient Overlay บนรูป
              Container(
                height: 200,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Colors.black.withOpacity(0.7)],
                  ),
                ),
              ),
              // ปุ่มกด Favorite
              Positioned(
                top: 15,
                left: 15,
                child: GestureDetector(
                  onTap: _toggleFavorite,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.4),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _isFavorite ? Icons.favorite : Icons.favorite_border,
                      color: _isFavorite ? Colors.pinkAccent : Colors.white,
                      size: 24,
                    ),
                  ),
                ),
              ),
            ],
          ),

          // ส่วนของเนื้อหา
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        restaurant.name,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          height: 1.2,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.star,
                                color: Colors.green,
                                size: 16,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${restaurant.rating}',
                                style: const TextStyle(
                                  color: Colors.green,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (dist.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Icon(
                                Icons.location_on,
                                color: Colors.white.withOpacity(0.5),
                                size: 14,
                              ),
                              const SizedBox(width: 2),
                              Text(
                                dist,
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.5),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ],
                        if (restaurant.priceLevel != null) ...[
                          const SizedBox(height: 6),
                          Text(
                            'ราคา: ${restaurant.priceLevel}',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.6),
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // คำบรรยายร้าน
                if (restaurant.summary != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: Text(
                      restaurant.summary!,
                      style: TextStyle(
                        fontSize: 15,
                        color: Colors.white.withOpacity(0.7),
                        fontStyle: FontStyle.italic,
                        height: 1.4,
                      ),
                    ),
                  ),

                Text(
                  restaurant.address,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.5),
                  ),
                ),
                const SizedBox(height: 24),

                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton.icon(
                    onPressed: _launchNavigation,
                    icon: const Icon(Icons.near_me),
                    label: const Text(
                      'นำทางไปชิมเลย!',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFEB1555),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: OutlinedButton.icon(
                    onPressed: _viewOnMap,
                    icon: const Icon(Icons.map_outlined),
                    label: const Text(
                      'เปิดดูในแผนที่',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white70,
                      side: const BorderSide(color: Colors.white24),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
