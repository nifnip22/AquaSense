import 'package:aquasense_frontend/features/history/models/alert_model.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../widgets/alert_ph_gauge_card.dart';
import '../widgets/alert_explanation_card.dart';
import '../widgets/alert_actions_card.dart';
import '../../../shared/widgets/secondary_app_bar.dart';

class AlertDetailScreen extends StatelessWidget {
  final AlertModel alert;

  const AlertDetailScreen({super.key, required this.alert});

  @override
  Widget build(BuildContext context) {
    final dateString = DateFormat('EEEE, dd MMMM yyyy').format(alert.createdAt);
    final timeString = DateFormat('hh:mm a').format(alert.createdAt);

    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      appBar: SecondaryAppBar(
        title: 'Alert Detail',
        customBadge: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFFC62828),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text('CRITICAL', style: GoogleFonts.plusJakartaSans(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white)),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: const Color(0xFFFFEBEE), borderRadius: BorderRadius.circular(24)),
              child: const Icon(Icons.warning_amber_rounded, color: Color(0xFFC62828), size: 48),
            ),
            const SizedBox(height: 16),
            Text(
              alert.title,
              textAlign: TextAlign.center,
              style: GoogleFonts.epilogue(fontSize: 28, fontWeight: FontWeight.bold, color: const Color(0xFF003355), height: 1.2),
            ),
            const SizedBox(height: 8),
            Text(
              '$dateString, $timeString', 
              style: GoogleFonts.plusJakartaSans(fontSize: 14, color: Colors.black54),
            ),
            const SizedBox(height: 32),
            const AlertPhGaugeCard(),
            const SizedBox(height: 16),
            AlertExplanationCard(alert: alert),
            const SizedBox(height: 16),
            const AlertActionsCard(),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFFF7F9FC),
          boxShadow: [
            BoxShadow(color: Colors.white.withValues(alpha: 0.9), blurRadius: 20, spreadRadius: 10, offset: const Offset(0, -20)),
          ],
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: double.infinity,
                height: 56,
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF007B83),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                  ),
                  onPressed: () {},
                  icon: const Icon(Icons.bolt),
                  label: const Text('Activate Water Pump Now', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFF003355)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                  ),
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.done_all, color: Color(0xFF003355)),
                  label: const Text('Mark as Resolved', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF003355))),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}