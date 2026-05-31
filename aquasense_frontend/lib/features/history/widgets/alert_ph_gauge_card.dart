import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AlertPhGaugeCard extends StatelessWidget {
  const AlertPhGaugeCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('CURRENT PH', style: GoogleFonts.plusJakartaSans(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.black54)),
                  Text('5.5', style: GoogleFonts.epilogue(fontSize: 48, fontWeight: FontWeight.bold, color: const Color(0xFFC62828), height: 1.0)),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('NORMAL RANGE', style: GoogleFonts.plusJakartaSans(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.black54)),
                  const SizedBox(height: 4),
                  Text('6.5 - 8.5', style: GoogleFonts.epilogue(fontSize: 20, fontWeight: FontWeight.bold, color: const Color(0xFF003355))),
                ],
              ),
            ],
          ),
          const SizedBox(height: 32),
          
          // Bagian Custom Gauge Bar
          Stack(
            clipBehavior: Clip.none,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: SizedBox(
                  height: 12,
                  child: Row(
                    children: [
                      Expanded(flex: 3, child: Container(color: const Color(0xFFC62828))), 
                      Expanded(flex: 4, child: Container(color: const Color(0xFF007B83))), 
                      Expanded(flex: 2, child: Container(color: const Color(0xFF8D4B20))), 
                    ],
                  ),
                ),
              ),
              
              Positioned(
                left: 30,
                top: -24,
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFC62828),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text('5.5', style: GoogleFonts.plusJakartaSans(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white)),
                    ),
                    Container(
                      width: 2,
                      height: 16,
                      color: const Color(0xFFC62828),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('ACIDIC', style: GoogleFonts.plusJakartaSans(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.black87)),
              Text('OPTIMAL', style: GoogleFonts.plusJakartaSans(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.black87)),
              Text('ALKALINE', style: GoogleFonts.plusJakartaSans(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.black87)),
            ],
          )
        ],
      ),
    );
  }
}