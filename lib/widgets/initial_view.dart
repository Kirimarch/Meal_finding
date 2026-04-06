import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class InitialView extends StatelessWidget {
  final String message;

  const InitialView({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return Column(
      key: const ValueKey('initial'),
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const SizedBox(height: 40),
        Icon(Icons.explore_rounded,
            size: 100, color: Colors.white.withOpacity(0.05)),
        const SizedBox(height: 20),
        Text(
          message,
          textAlign: TextAlign.center,
          style: GoogleFonts.outfit(
              fontSize: 18, color: Colors.white24, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }
}
