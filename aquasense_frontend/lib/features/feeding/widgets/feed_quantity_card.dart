import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class FeedQuantityCard extends StatelessWidget {
  final int currentDuration;
  final ValueChanged<double> onChanged;

  const FeedQuantityCard({
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
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.timer, color: Color(0xFF003355)),
              const SizedBox(width: 8),
              Text(
                'Default Feed Duration',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF003355),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Set how long the dispenser motor will run when adding a new schedule.',
            style: GoogleFonts.plusJakartaSans(fontSize: 12, color: Colors.black54),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Text(
                '${currentDuration}s',
                style: GoogleFonts.epilogue(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF0288D1),
                ),
              ),
              Expanded(
                child: Slider(
                  value: currentDuration.toDouble(),
                  min: 1,
                  max: 20,
                  divisions: 19,
                  activeColor: const Color(0xFF0288D1),
                  inactiveColor: Colors.grey.shade200,
                  label: '${currentDuration}s',
                  onChanged: onChanged,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}