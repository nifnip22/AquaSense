import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../shared/widgets/secondary_app_bar.dart';
import '../widgets/device_info_card.dart';
import '../widgets/calibration_section.dart';
import '../widgets/thresholds_section.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      appBar: const SecondaryAppBar(title: 'Settings'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            const DeviceInfoCard(),
            const SizedBox(height: 32),
            const CalibrationSection(),
            const SizedBox(height: 32),
            const ThresholdsSection(),
            const SizedBox(height: 40),
            
            // Action Buttons
            SizedBox(
              width: double.infinity,
              height: 56,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFF007B83), width: 1.5),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                ),
                onPressed: () {},
                icon: const Icon(Icons.restart_alt, color: Color(0xFF007B83)),
                label: const Text('Restart ESP32 Device', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF007B83))),
              ),
            ),
            const SizedBox(height: 16),
            TextButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.warning_amber_rounded, color: Color(0xFFC62828), size: 20),
              label: Text('Factory Reset', style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.bold, color: const Color(0xFFC62828))),
            ),
            const SizedBox(height: 48),

            // Footer / Team Management
            const Icon(Icons.group_outlined, color: Colors.black45, size: 24),
            const SizedBox(height: 8),
            Text(
              'TEAM MANAGEMENT (KELOMPOK 1)',
              style: GoogleFonts.plusJakartaSans(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.black45, letterSpacing: 1.0),
            ),
            const SizedBox(height: 4),
            Text(
              'System Administrators:\nRengga, Fachrel, Hanif, Ilham',
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(fontSize: 12, color: Colors.black45, height: 1.5),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}