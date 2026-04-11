import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ScanningView extends StatefulWidget {
  const ScanningView({super.key});

  @override
  State<ScanningView> createState() => _ScanningViewState();
}

class _ScanningViewState extends State<ScanningView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000), // Longer duration for smoother ripple
    )..repeat();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      key: const ValueKey('scanning'),
      children: [
        const SizedBox(height: 60),
        SizedBox(
          width: 250,
          height: 250,
          child: AnimatedBuilder(
            animation: _pulseController,
            builder: (context, child) {
              return Stack(
                alignment: Alignment.center,
                children: [
                  // Ripples
                  ...List.generate(3, (index) {
                    final delay = index * 0.33;
                    final progress = (_pulseController.value - delay) % 1.0;
                    final opacity = (1.0 - progress).clamp(0.0, 1.0);
                    final size = 100 + (progress * 150);

                    return Container(
                      width: size,
                      height: size,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color(0xFFEB1555).withOpacity(opacity * 0.5),
                          width: 2,
                        ),
                      ),
                    );
                  }),
                  
                  // Central Glow
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFFEB1555).withOpacity(0.1),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFEB1555).withOpacity(0.3),
                          blurRadius: 20,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                  ),

                  // Static/Subtle Pulse Core
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFFEB1555), width: 2),
                    ),
                    child: const Icon(Icons.radar_rounded,
                        size: 40, color: Color(0xFFEB1555)),
                  ),
                ],
              );
            },
          ),
        ),
        const SizedBox(height: 40),
        Text(
          'กำลังสแกนหาของอร่อย...',
          style: GoogleFonts.outfit(
              fontSize: 20, color: Colors.white, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        const Text(
          'กำลังกรองร้านซ้ำจากประวัติ...',
          style: TextStyle(color: Colors.white38, fontSize: 13),
        ),
      ],
    );
  }
}
