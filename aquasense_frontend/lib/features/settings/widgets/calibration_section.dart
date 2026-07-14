import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';

class CalibrationSection extends StatelessWidget {
  const CalibrationSection({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Sensor Calibration',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF003355),
          ),
        ),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              _buildTile(
                icon: Icons.science_outlined,
                title: 'Calibrate pH Sensor',
                currentValue: settings.phOffset.toString(),
                onTap: () => _showCalibrationDialog(
                  context: context,
                  title: 'pH Offset',
                  currentValue: settings.phOffset,
                  onSave: (val) => settings.saveCalibration(
                    newPhOffset: val,
                    newTurbidityOffset: settings.turbiditySensitivity,
                  ),
                ),
              ),
              const Divider(height: 1, indent: 64, endIndent: 20),
              _buildTile(
                icon: Icons.water_drop_outlined,
                title: 'Turbidity Sensitivity',
                currentValue: settings.turbiditySensitivity.toString(),
                onTap: () => _showCalibrationDialog(
                  context: context,
                  title: 'Turbidity Offset',
                  currentValue: settings.turbiditySensitivity,
                  onSave: (val) => settings.saveCalibration(
                    newPhOffset: settings.phOffset,
                    newTurbidityOffset: val,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTile({
    required IconData icon,
    required String title,
    required String currentValue,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: const BoxDecoration(
          color: Color(0xFFF0F4F8),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: const Color(0xFF003355), size: 20),
      ),
      title: Text(
        title,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 14,
          color: const Color(0xFF1E293B),
        ),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            currentValue,
            style: GoogleFonts.epilogue(
              fontWeight: FontWeight.bold,
              color: const Color(0xFF0288D1),
            ),
          ),
          const SizedBox(width: 8),
          const Icon(Icons.chevron_right, color: Colors.black54),
        ],
      ),
      onTap: onTap,
    );
  }

  Future<void> _showCalibrationDialog({
    required BuildContext context,
    required String title,
    required double currentValue,
    required Future<void> Function(double) onSave,
  }) async {
    final controller = TextEditingController(text: currentValue.toString());

    final newValue = await showDialog<double>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            title,
            style: GoogleFonts.plusJakartaSans(
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          content: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton.filledTonal(
                onPressed: () {
                  double val = double.tryParse(controller.text) ?? 0.0;
                  controller.text = (val - 0.1).toStringAsFixed(1);
                },
                icon: const Icon(Icons.remove),
                style: IconButton.styleFrom(
                  backgroundColor: const Color(0xFFF0F4F8), 
                  foregroundColor: const Color(0xFF003355),
                  padding: const EdgeInsets.all(16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextField(
                  controller: controller,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                  textAlign: TextAlign.center,
                  style: GoogleFonts.epilogue(
                    fontWeight: FontWeight.bold, 
                    fontSize: 24,
                    color: const Color(0xFF003355)
                  ),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: const Color(0xFFF0F4F8),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              IconButton.filled(
                onPressed: () {
                  double val = double.tryParse(controller.text) ?? 0.0;
                  controller.text = (val + 0.1).toStringAsFixed(1);
                },
                icon: const Icon(Icons.add),
                style: IconButton.styleFrom(
                  backgroundColor: const Color(0xFFE1F5FE),
                  foregroundColor: const Color(0xFF0288D1),
                  padding: const EdgeInsets.all(16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cancel',
                style: GoogleFonts.plusJakartaSans(color: Colors.grey),
              ),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF0288D1),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () {
                final parsedValue = double.tryParse(controller.text);
                if (parsedValue != null) {
                  Navigator.pop(context, parsedValue);
                }
              },
              child: Text(
                'Save',
                style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );

    if (newValue != null && newValue != currentValue) {
      try {
        await onSave(newValue);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Calibration saved successfully!'),
              backgroundColor: Color(0xFF0288D1),
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to save calibration: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }
}
