import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class CalibrationSection extends StatelessWidget {
  const CalibrationSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Sensor Calibration', style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.bold, color: const Color(0xFF003355))),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
          child: Column(
            children: [
              _buildTile(icon: Icons.science_outlined, title: 'Calibrate pH Sensor'),
              const Divider(height: 1, indent: 64, endIndent: 20),
              _buildTile(icon: Icons.water_drop_outlined, title: 'Turbidity Sensitivity'),
              const Divider(height: 1, indent: 64, endIndent: 20),
              _buildTile(icon: Icons.straighten, title: 'Water Level Offset'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTile({required IconData icon, required String title}) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: const BoxDecoration(color: Color(0xFFF0F4F8), shape: BoxShape.circle),
        child: Icon(icon, color: const Color(0xFF003355), size: 20),
      ),
      title: Text(title, style: GoogleFonts.plusJakartaSans(fontSize: 14, color: const Color(0xFF1E293B))),
      trailing: const Icon(Icons.chevron_right, color: Colors.black54),
      onTap: () {},
    );
  }
}