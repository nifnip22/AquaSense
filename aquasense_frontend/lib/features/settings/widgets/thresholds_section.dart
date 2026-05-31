import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ThresholdsSection extends StatelessWidget {
  const ThresholdsSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Alert Thresholds', style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.bold, color: const Color(0xFF003355))),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
          child: Column(
            children: [
              _buildInputField(label: 'PH RANGE', value: '6.5 - 8.5'),
              const SizedBox(height: 12),
              _buildInputField(label: 'TEMPERATURE MAX', value: '32°C'),
              const SizedBox(height: 12),
              _buildInputField(label: 'TURBIDITY MAX', value: '200 NTU'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInputField({required String label, required String value}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(color: const Color(0xFFF7F9FC), borderRadius: BorderRadius.circular(16)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: GoogleFonts.plusJakartaSans(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.black54, letterSpacing: 0.5)),
              const SizedBox(height: 4),
              Text(value, style: GoogleFonts.plusJakartaSans(fontSize: 15, color: const Color(0xFF1E293B))),
            ],
          ),
          const Icon(Icons.edit, color: Color(0xFF003355), size: 18),
        ],
      ),
    );
  }
}