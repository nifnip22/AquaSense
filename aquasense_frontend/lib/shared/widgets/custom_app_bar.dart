import 'package:aquasense_frontend/features/monitoring/providers/sensor_provider.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../features/settings/screens/settings_screen.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  // For additional customization in the future
  const CustomAppBar({super.key});

  @override
  Widget build(BuildContext context) {
    final isOnline = context.watch<SensorProvider>().isDeviceOnline;

    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      title: Row(
        children: [
          Text(
            'AquaSense',
            style: GoogleFonts.epilogue(
              fontWeight: FontWeight.bold,
              color: const Color(0xFF003355),
            ),
          ),
          const SizedBox(width: 12),
          // Badge Status Online
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: isOnline ? const Color(0xFFE0F2F1) : const Color(0xFFFFEBEE),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isOnline ? const Color(0xFF80CBC4) : const Color(0xFFEF9A9A),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: isOnline ? const Color(0xFF00897B) : const Color(0xFFD32F2F),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  isOnline ? 'ONLINE' : 'OFFLINE',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: isOnline ? const Color(0xFF00695C) : const Color(0xFFC62828),
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.more_vert, color: Colors.black54),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const SettingsScreen()),
            );
          },
        )
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}