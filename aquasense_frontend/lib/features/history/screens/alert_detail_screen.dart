import 'package:aquasense_frontend/features/history/models/alert_model.dart';
import 'package:aquasense_frontend/features/history/widgets/alert_metric_gauge_card.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../widgets/alert_explanation_card.dart';
import '../widgets/alert_actions_card.dart';
import '../../../shared/widgets/secondary_app_bar.dart';
import 'package:provider/provider.dart';
import '../providers/history_provider.dart';

class AlertDetailScreen extends StatefulWidget {
  final AlertModel alert;

  const AlertDetailScreen({super.key, required this.alert});

  @override
  State<AlertDetailScreen> createState() => _AlertDetailScreenState();
}

class _AlertDetailScreenState extends State<AlertDetailScreen> {
  bool _isLoading = false;

  Future<void> _markAsResolved() async {
    setState(() => _isLoading = true);

    final success = await context.read<HistoryProvider>().markAlertAsResolved(widget.alert.id!);

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (success) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Alert successfully resolved!'), backgroundColor: Colors.green),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to update status.'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateString = DateFormat('EEEE, dd MMMM yyyy').format(widget.alert.createdAt);
    final timeString = DateFormat('hh:mm a').format(widget.alert.createdAt);

    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      appBar: SecondaryAppBar(
        title: 'Alert Detail',
        customBadge: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(color: const Color(0xFFC62828), borderRadius: BorderRadius.circular(12)),
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
              widget.alert.title,
              textAlign: TextAlign.center,
              style: GoogleFonts.epilogue(fontSize: 28, fontWeight: FontWeight.bold, color: const Color(0xFF003355), height: 1.2),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today_rounded, size: 14, color: Color(0xFF003355)),
                      const SizedBox(width: 6),
                      Text(dateString, style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFF455A64))),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.access_time_rounded, size: 14, color: Color(0xFFC62828)),
                      const SizedBox(width: 6),
                      Text(timeString, style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFF455A64))),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            
            AlertMetricGaugeCard(alert: widget.alert),
            const SizedBox(height: 16),
            AlertExplanationCard(alert: widget.alert),
            const SizedBox(height: 16),
            AlertActionsCard(sensorType: widget.alert.sensorType),
            
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFFF7F9FC),
          boxShadow: [BoxShadow(color: Colors.white.withValues(alpha: 0.9), blurRadius: 20, spreadRadius: 10, offset: const Offset(0, -20))],
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: double.infinity,
                height: 56,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFF003355)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                  ),
                  onPressed: _isLoading ? null : _markAsResolved,
                  icon: _isLoading 
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.done_all, color: Color(0xFF003355)),
                  label: Text(
                    _isLoading ? 'Processing...' : 'Mark as Resolved', 
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF003355))
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}