import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../shared/widgets/custom_app_bar.dart';
import '../widgets/schedule_toggle_card.dart';
import '../widgets/feed_quantity_card.dart';
import '../widgets/intelligence_settings_card.dart';

class ScheduleScreen extends StatefulWidget {
  const ScheduleScreen({super.key});

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  // Schedule state variables that would typically be loaded from a backend or local storage
  bool _isMorningActive = true;
  bool _isAfternoonActive = true;
  bool _isNightActive = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: const CustomAppBar(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Section
            Text(
              'Smart Schedule',
              style: GoogleFonts.epilogue(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF003355),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Optimize the biological health of your river farm with precision timing.',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                color: Colors.black54,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 32),

            Row(
              children: [
                const Icon(Icons.restaurant, color: Color(0xFF003355), size: 20),
                const SizedBox(width: 8),
                Text(
                  'Feeding Schedule',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF003355),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            ScheduleToggleCard(
              time: '08:00 AM',
              label: 'MORNING FEED',
              isActive: _isMorningActive,
              onChanged: (val) => setState(() => _isMorningActive = val),
            ),
            const SizedBox(height: 12),
            ScheduleToggleCard(
              time: '04:00 PM',
              label: 'AFTERNOON FEED',
              isActive: _isAfternoonActive,
              onChanged: (val) => setState(() => _isAfternoonActive = val),
            ),
            const SizedBox(height: 12),
            ScheduleToggleCard(
              time: '10:00 PM',
              label: 'NIGHT FEED',
              isActive: _isNightActive,
              onChanged: (val) => setState(() => _isNightActive = val),
            ),
            const SizedBox(height: 16),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF003355),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                ),
                onPressed: () {},
                icon: const Icon(Icons.add),
                label: const Text('ADD NEW SCHEDULE', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.5)),
              ),
            ),
            const SizedBox(height: 32),

            const FeedQuantityCard(),
            const SizedBox(height: 24),
            
            const IntelligenceSettingsCard(),
            
            /* -- IMAGE FEATURE TEMPORARY COMMAND --
            const SizedBox(height: 24),
            _buildZoneImageCard(),
            */
            
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}