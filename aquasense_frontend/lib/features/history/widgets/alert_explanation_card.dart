import 'package:aquasense_frontend/features/history/models/alert_model.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AlertExplanationCard extends StatelessWidget {
  final AlertModel alert;

  const AlertExplanationCard({super.key, required this.alert});

  String _getUrgencyMessage(String sensorType) {
    switch (sensorType) {
      case 'TEMPERATURE':
        return 'Extreme temperatures can damage metabolism and trigger mass fish deaths!';
      case 'PH':
        return 'An unbalanced pH can damage the gills and trigger acute ammonia poisoning!';
      case 'TURBIDITY':
        return 'High turbidity inhibits fish breathing and triggers pathogenic bacteria!';
      case 'FEED_LEVEL':
        return 'Running out of feed will stop the automatic schedule and inhibit fish growth!';
      default:
        return 'Immediate action is required to prevent monitoring system failure!';
    }
  }

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
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFFEBEE).withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFFFCDD2), width: 1),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.warning_amber_rounded, color: Color(0xFFC62828), size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _getUrgencyMessage(alert.sensorType),
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13, 
                        color: const Color(0xFFC62828), 
                        fontWeight: FontWeight.w600,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
