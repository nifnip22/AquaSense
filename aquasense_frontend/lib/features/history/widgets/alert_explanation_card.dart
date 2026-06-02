import 'package:aquasense_frontend/features/history/models/alert_model.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AlertExplanationCard extends StatelessWidget {
  final AlertModel alert;

  const AlertExplanationCard({super.key, required this.alert});

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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  color: Color(0xFFE1F5FE),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.analytics_outlined,
                  color: Color(0xFF003355),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'What this means',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF003355),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            alert.description,
            style: GoogleFonts.plusJakartaSans(fontSize: 14, color: Colors.black87, height: 1.5),
          ),

          if (alert.type == 'ALERT') ...[
            const SizedBox(height: 8),
            Text(
              'Action required immediately to prevent biological stress.',
              style: GoogleFonts.plusJakartaSans(fontSize: 14, color: const Color(0xFFC62828), fontWeight: FontWeight.bold),
            ),
          ],
        ],
      ),
    );
  }
}
