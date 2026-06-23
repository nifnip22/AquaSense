import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class MixerDurationCard extends StatelessWidget {
  final int currentDuration;
  final ValueChanged<double> onChanged;

  const MixerDurationCard({
    super.key,
    required this.currentDuration,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.cyclone, color: Color(0xFF00897B), size: 24),
                  const SizedBox(width: 8),
                  Text(
                    'Stirring Duration',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF003355),
                    ),
                  ),
                ],
              ),
              Text(
                '$currentDuration Min',
                style: GoogleFonts.epilogue(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF00897B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SliderTheme(
            data: SliderThemeData(
              activeTrackColor: const Color(0xFF00897B),
              inactiveTrackColor: const Color(0xFFE0F2F1),
              thumbColor: Colors.white,
              trackHeight: 8,
              overlayColor: const Color(0xFF00897B).withValues(alpha: 0.2),
            ),
            child: Slider(
              value: currentDuration.toDouble(),
              min: 1, 
              max: 60, 
              divisions: 59,
              onChanged: onChanged,
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('1 Min', style: GoogleFonts.plusJakartaSans(fontSize: 12, color: Colors.black45)),
              Text('60 Min', style: GoogleFonts.plusJakartaSans(fontSize: 12, color: Colors.black45)),
            ],
          ),
        ],
      ),
    );
  }
}