import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class DeviceInfoCard extends StatelessWidget {
  const DeviceInfoCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: const BoxDecoration(color: Color(0xFF003355), shape: BoxShape.circle),
                child: const Icon(Icons.router, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Device ID: AS-BPN-001', style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.bold, color: const Color(0xFF003355))),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(color: const Color(0xFF007B83), borderRadius: BorderRadius.circular(12)),
                          child: Row(
                            children: [
                              Container(width: 4, height: 4, decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle)),
                              const SizedBox(width: 4),
                              Text('ONLINE', style: GoogleFonts.plusJakartaSans(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.white)),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(Icons.signal_cellular_alt, size: 14, color: Colors.black54),
                        const SizedBox(width: 4),
                        Text('Signal Strength: Strong (GSM)', style: GoogleFonts.plusJakartaSans(fontSize: 11, color: Colors.black54)),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Padding(padding: EdgeInsets.symmetric(vertical: 16), child: Divider()),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Firmware Version', style: GoogleFonts.plusJakartaSans(fontSize: 13, color: Colors.black54)),
              Row(
                children: [
                  Text('v1.0.4', style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.bold, color: const Color(0xFF003355))),
                  const SizedBox(width: 4),
                  Text('(Up to date)', style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.bold, color: const Color(0xFF007B83))),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}