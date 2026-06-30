import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../shared/widgets/secondary_app_bar.dart';
import '../widgets/device_info_card.dart';
// import '../widgets/calibration_section.dart';
import '../widgets/thresholds_section.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  void _showResetDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: [
            const Icon(Icons.settings_backup_restore, color: Color(0xFF007B83)),
            const SizedBox(width: 8),
            Text('Reset Settings', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 20)),
          ],
        ),
        content: Text(
          'Are you sure you want to return all sensor range and feed duration safe limits to their default values?',
          style: GoogleFonts.plusJakartaSans(fontSize: 14, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, color: Colors.grey.shade600)),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF007B83),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Mereset pengaturan...'), duration: Duration(seconds: 1)),
              );
              
              await context.read<SettingsProvider>().resetToDefaultSettings();
              
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Pengaturan berhasil dikembalikan ke default!'), backgroundColor: Color(0xFF007B83)),
                );
              }
            },
            child: Text('Yes, Reset', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

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
            // const CalibrationSection(),
            // const SizedBox(height: 32),
            Consumer<SettingsProvider>(
              builder: (context, settings, child) {
                return Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(32),
                    boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4))],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: const BoxDecoration(color: Color(0xFFFFF3E0), shape: BoxShape.circle),
                            child: const Icon(Icons.restaurant, color: Color(0xFFFF9800), size: 20),
                          ),
                          const SizedBox(width: 12),
                          Text('Manual Feed Duration', style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.bold, color: const Color(0xFF003355))),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text('Set the motor rotation duration (1-15 seconds) when giving manual feed.', style: GoogleFonts.plusJakartaSans(fontSize: 12, color: Colors.grey.shade600)),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Text('${settings.manualFeedDuration}s', style: GoogleFonts.epilogue(fontSize: 28, fontWeight: FontWeight.bold, color: const Color(0xFFFF9800))),
                          Expanded(
                            child: Slider(
                              value: settings.manualFeedDuration.toDouble(),
                              min: 1,
                              max: 15,
                              divisions: 14,
                              activeColor: const Color(0xFFFF9800),
                              inactiveColor: const Color(0xFFFFF3E0),
                              onChanged: (val) {
                                settings.updateManualFeedDuration(val.toInt());
                              },
                            ),
                          ),
                        ],
                      )
                    ],
                  ),
                );
              }
            ),
            const SizedBox(height: 16),
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
                onPressed: () => _showResetDialog(context),
                icon: const Icon(Icons.restart_alt, color: Color(0xFF007B83)),
                label: const Text('Restart Settings to Default', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF007B83))),
              ),
            ),
            const SizedBox(height: 48),

            // Footer / Team Management
            const Icon(Icons.group_outlined, color: Colors.black45, size: 24),
            const SizedBox(height: 8),
            Text(
              'AQUASENSE TEAM MANAGEMENT',
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