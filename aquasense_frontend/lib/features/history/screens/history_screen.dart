import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../shared/widgets/custom_app_bar.dart';
import '../widgets/history_filter_chips.dart';
import '../widgets/date_section_header.dart';
import '../widgets/history_log_card.dart';
import 'alert_detail_screen.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

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
            // Filter Categories
            HistoryFilterChips(
              onFilterSelected: (filter) {
                // Handle filter selection (e.g., update state or fetch filtered data)
              },
            ),
            const SizedBox(height: 24),

            const DateSectionHeader(dateText: 'Today'),
            const SizedBox(height: 16),

            // Item 1: Automatic Feeding
            const HistoryLogCard(
              title: 'Automatic Feeding\nSuccessful',
              iconData: Icons.restaurant,
              iconColor: Color(0xFF003355), 
              iconBgColor: Color(0xFFD1EAFA), 
              borderColor: Color(0xFF00E5FF), 
              subtitleText: '08:00 AM • Duration: 3s',
            ),

            // Item 2: Warning Alert (with Custom Subtitle)
            GestureDetector(
              onTap: () {
                // Navigate to Alert Detail Screen
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const AlertDetailScreen()),
                );
              },
              child: HistoryLogCard(
                title: 'Warning: Critical pH\nLevel',
                iconData: Icons.error_outline,
                iconColor: Colors.white,
                iconBgColor: const Color(0xFFC62828), 
                borderColor: const Color(0xFFFFCDD2), 
                showArrow: true,
                customSubtitle: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFEBEE),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.water_drop, color: Color(0xFFC62828), size: 12),
                      const SizedBox(width: 4),
                      Text(
                        '02:30 PM • pH: 5.5 (Acidic)',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFFC62828),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Item 3: Manual Blower
            const HistoryLogCard(
              title: 'Manual Blower Activated',
              iconData: Icons.air,
              iconColor: Color(0xFF455A64),
              iconBgColor: Color(0xFFECEFF1),
              borderColor: Color(0xFFB0BEC5),
              subtitleText: '11:15 AM by User',
            ),

            const SizedBox(height: 16),

            const DateSectionHeader(dateText: 'Yesterday'),
            const SizedBox(height: 16),

            // Item 4: Eco Mode
            const HistoryLogCard(
              title: 'Entered Eco Power Mode',
              iconData: Icons.battery_saver,
              iconColor: Color(0xFF455A64),
              iconBgColor: Color(0xFFECEFF1),
              borderColor: Color(0xFF64B5F6),
              subtitleText: 'Yesterday • Battery: 15%',
            ),
            
            const SizedBox(height: 24),
            
            // Pagination Dots
            Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildDot(isActive: true),
                  _buildDot(isActive: false),
                  _buildDot(isActive: false),
                ],
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildDot({required bool isActive}) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      width: 6,
      height: 6,
      decoration: BoxDecoration(
        color: isActive ? Colors.grey.shade400 : Colors.grey.shade300,
        shape: BoxShape.circle,
      ),
    );
  }
}