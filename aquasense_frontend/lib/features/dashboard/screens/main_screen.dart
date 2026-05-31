import 'package:aquasense_frontend/features/feeding/screens/schedule_screen.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../monitoring/screens/monitor_screen.dart';
import '../../monitoring/screens/statistic_screen.dart';
import '../../history/screens/history_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  // List of pages corresponding to each tab in the bottom navigation bar
  final List<Widget> _pages = [
    const MonitorScreen(),
    const StatisticScreen(),
    const ScheduleScreen(),
    const HistoryScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      body: _pages[_currentIndex],
      bottomNavigationBar: Container(
        padding: const EdgeInsets.only(top: 12, bottom: 24, left: 16, right: 16),
        decoration: BoxDecoration(
          color: const Color(0xFFF7F9FC), // Warna latar belakang putih kebiruan
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(32),
            topRight: Radius.circular(32),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildCustomNavItem(icon: Icons.dashboard, label: 'Monitor', index: 0),
            _buildCustomNavItem(icon: Icons.bar_chart, label: 'Statistic', index: 1),
            _buildCustomNavItem(icon: Icons.calendar_today, label: 'Schedule', index: 2),
            _buildCustomNavItem(icon: Icons.history, label: 'History', index: 3),
          ],
        ),
      ),
    );
  }

  // Jangan lupa import google_fonts di bagian paling atas file jika belum ada
  // import 'package:google_fonts/google_fonts.dart';

  Widget _buildCustomNavItem({required IconData icon, required String label, required int index}) {
    final bool isSelected = _currentIndex == index;

    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          setState(() {
            _currentIndex = index;
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF003355) : Colors.transparent,
            borderRadius: BorderRadius.circular(30),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: isSelected ? const Color(0xFF81D4FA) : const Color(0xFF455A64),
                size: 24,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                  color: isSelected ? const Color(0xFF81D4FA) : const Color(0xFF455A64),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}