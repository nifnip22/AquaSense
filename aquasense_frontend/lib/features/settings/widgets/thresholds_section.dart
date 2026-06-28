import 'package:aquasense_frontend/features/settings/providers/settings_provider.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

class ThresholdsSection extends StatelessWidget {
  const ThresholdsSection({super.key});

  void _showEditDialog({
    required BuildContext context,
    required String title,
    required String suffix,
    required String currentValue,
    required Function(String) onSave,
  }) {
    final TextEditingController controller = TextEditingController(text: currentValue);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Text(
            title,
            style: GoogleFonts.plusJakartaSans(
              fontWeight: FontWeight.bold,
              fontSize: 18,
              color: const Color(0xFF003355),
            ),
          ),
          content: TextField(
            controller: controller,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              suffixText: suffix,
              filled: true,
              fillColor: const Color(0xFFF0F4F8),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
            ),
            style: GoogleFonts.epilogue(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel', style: GoogleFonts.plusJakartaSans(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () {
                onSave(controller.text);
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF003355),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text('Save', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  void _showPhRangeDialog({
    required BuildContext context,
    required String currentMin,
    required String currentMax,
    required Function(double, double) onSave,
  }) {
    final TextEditingController minController = TextEditingController(text: currentMin);
    final TextEditingController maxController = TextEditingController(text: currentMax);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Text(
            'Set pH Range',
            style: GoogleFonts.plusJakartaSans(
              fontWeight: FontWeight.bold,
              fontSize: 18,
              color: const Color(0xFF003355),
            ),
          ),
          content: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Min',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: minController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      textAlign: TextAlign.center,
                      decoration: InputDecoration(
                        contentPadding: const EdgeInsets.symmetric(vertical: 16),
                        filled: true,
                        fillColor: const Color(0xFFF0F4F8),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      style: GoogleFonts.epilogue(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 12, right: 12, top: 32),
                child: Text('-', style: GoogleFonts.epilogue(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.grey)),
              ),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Max',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: maxController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: false),
                      textAlign: TextAlign.center,
                      decoration: InputDecoration(
                        contentPadding: const EdgeInsets.symmetric(vertical: 16),
                        filled: true,
                        fillColor: const Color(0xFFF0F4F8),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      style: GoogleFonts.epilogue(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel', style: GoogleFonts.plusJakartaSans(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () {
                final minVal = double.tryParse(minController.text);
                final maxVal = double.tryParse(maxController.text);
                if (minVal != null && maxVal != null) {
                  onSave(minVal, maxVal);
                  Navigator.pop(context);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF003355),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text('Save', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Alert Thresholds', style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.bold, color: const Color(0xFF003355))),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
          child: Column(
            children: [
              _buildInputField(
                label: 'PH RANGE', 
                value: '${settings.phMin} - ${settings.phMax}',
                onTap: () {
                  _showPhRangeDialog(
                    context: context,
                    currentMin: settings.phMin.toString(),
                    currentMax: settings.phMax.toString(),
                    onSave: (min, max) {
                      context.read<SettingsProvider>().updatePhRange(min, max);
                    },
                  );
                }
              ),
              const SizedBox(height: 12),
              _buildInputField(
                label: 'TEMPERATURE MAX', 
                value: '${settings.tempMax}°C',
                onTap: () {
                  _showEditDialog(
                    context: context,
                    title: 'Set Max Temperature',
                    suffix: '°C',
                    currentValue: settings.tempMax.toString(),
                    onSave: (newValue) {
                      final parsedValue = double.tryParse(newValue);
                      if (parsedValue != null) {
                        context.read<SettingsProvider>().updateDeviceSetting('temp_max', parsedValue);
                      }
                    },
                  );
                }
              ),
              const SizedBox(height: 12),
              _buildInputField(
                label: 'TURBIDITY MAX', 
                value: '${settings.turbidityMax} ADC',
                onTap: () {
                  _showEditDialog(
                    context: context,
                    title: 'Set Max Turbidity',
                    suffix: 'ADC',
                    currentValue: settings.turbidityMax.toString(),
                    onSave: (newValue) {
                      final parsedValue = double.tryParse(newValue);
                      if (parsedValue != null) {
                        context.read<SettingsProvider>().updateDeviceSetting('turbidity_max', parsedValue);
                      }
                    },
                  );
                }
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInputField({required String label, required String value, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(color: const Color(0xFFF7F9FC), borderRadius: BorderRadius.circular(16)),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: GoogleFonts.plusJakartaSans(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.black54, letterSpacing: 0.5)),
                const SizedBox(height: 4),
                Text(value, style: GoogleFonts.plusJakartaSans(fontSize: 15, color: const Color(0xFF1E293B))),
              ],
            ),
            const Icon(Icons.edit, color: Color(0xFF003355), size: 18),
          ],
        ),
      ),
    );
  }
}