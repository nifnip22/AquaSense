import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AlertExplanationCard extends StatelessWidget {
  const AlertExplanationCard({super.key});

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
                child: const Icon(Icons.analytics_outlined, color: Color(0xFF003355), size: 20),
              ),
              const SizedBox(width: 12),
              Text('What this means', style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFF003355))),
            ],
          ),
          const SizedBox(height: 16),
          RichText(
            text: TextSpan(
              style: GoogleFonts.plusJakartaSans(fontSize: 14, color: Colors.black87, height: 1.5),
              children: const [
                TextSpan(text: 'The water is currently too acidic. This can cause respiratory stress in fish and may lead to mass mortality if not addressed within the next '),
                TextSpan(text: '2 hours.', style: TextStyle(color: Color(0xFFC62828), fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}