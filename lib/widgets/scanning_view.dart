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
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
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
        ScaleTransition(
          scale: Tween<double>(begin: 1.0, end: 1.2).animate(_pulseController),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: const Color(0xFFEB1555).withOpacity(0.3),
                    width: 1,
                  ),
                ),
              ),
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFFEB1555).withOpacity(0.1),
                  border: Border.all(color: const Color(0xFFEB1555), width: 2),
                ),
                child: const Icon(Icons.radar_rounded,
                    size: 50, color: Color(0xFFEB1555)),
              ),
            ],
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
