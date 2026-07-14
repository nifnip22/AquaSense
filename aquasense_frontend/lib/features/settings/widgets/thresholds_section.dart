import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';

class ThresholdsSection extends StatelessWidget {
  const ThresholdsSection({super.key});

  void _showEditDialog({
    required BuildContext context,
    required String title,
    required String suffix,
    required String currentValue,
    required double step,
    required int fractionDigits,
    required Function(String) onSave,
  }) {
    final TextEditingController controller = TextEditingController(
      text: currentValue,
    );

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          title: Text(
            title,
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(
              fontWeight: FontWeight.bold,
              fontSize: 18,
              color: const Color(0xFF003355),
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton.filledTonal(
                    onPressed: () {
                      double val = double.tryParse(controller.text) ?? 0.0;
                      controller.text = (val - step).toStringAsFixed(fractionDigits);
                    },
                    icon: const Icon(Icons.remove),
                    style: IconButton.styleFrom(
                      backgroundColor: const Color(0xFFF0F4F8),
                      foregroundColor: const Color(0xFF003355),
                      padding: const EdgeInsets.all(16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: controller,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                      textAlign: TextAlign.center,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: const Color(0xFFF0F4F8),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      style: GoogleFonts.epilogue(fontSize: 22, fontWeight: FontWeight.bold, color: const Color(0xFF003355)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  IconButton.filled(
                    onPressed: () {
                      double val = double.tryParse(controller.text) ?? 0.0;
                      controller.text = (val + step).toStringAsFixed(fractionDigits);
                    },
                    icon: const Icon(Icons.add),
                    style: IconButton.styleFrom(
                      backgroundColor: const Color(0xFFE1F5FE),
                      foregroundColor: const Color(0xFF0288D1),
                      padding: const EdgeInsets.all(16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0F4F8),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Unit: $suffix',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade600,
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
              onPressed: () {
                onSave(controller.text);
                Navigator.pop(context);
              },
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF0288D1),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'Save',
                style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold),
              ),
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
    final TextEditingController minController = TextEditingController(
      text: currentMin,
    );
    final TextEditingController maxController = TextEditingController(
      text: currentMax,
    );

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          title: Text(
            'Set pH Range',
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(
              fontWeight: FontWeight.bold,
              fontSize: 18,
              color: const Color(0xFF003355),
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'pH Minimum',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  IconButton.filledTonal(
                    onPressed: () {
                      double val = double.tryParse(minController.text) ?? 0.0;
                      minController.text = (val - 0.1).toStringAsFixed(1);
                    },
                    icon: const Icon(Icons.remove),
                    style: IconButton.styleFrom(
                      backgroundColor: const Color(0xFFF0F4F8),
                      foregroundColor: const Color(0xFF003355),
                      padding: const EdgeInsets.all(12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: minController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      textAlign: TextAlign.center,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: const Color(0xFFF0F4F8),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      style: GoogleFonts.epilogue(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF003355),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    onPressed: () {
                      double val = double.tryParse(minController.text) ?? 0.0;
                      minController.text = (val + 0.1).toStringAsFixed(1);
                    },
                    icon: const Icon(Icons.add),
                    style: IconButton.styleFrom(
                      backgroundColor: const Color(0xFFE1F5FE),
                      foregroundColor: const Color(0xFF0288D1),
                      padding: const EdgeInsets.all(12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Text(
                'pH Maximum',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  IconButton.filledTonal(
                    onPressed: () {
                      double val = double.tryParse(maxController.text) ?? 0.0;
                      maxController.text = (val - 0.1).toStringAsFixed(1);
                    },
                    icon: const Icon(Icons.remove),
                    style: IconButton.styleFrom(
                      backgroundColor: const Color(0xFFF0F4F8),
                      foregroundColor: const Color(0xFF003355),
                      padding: const EdgeInsets.all(12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: maxController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      textAlign: TextAlign.center,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: const Color(0xFFF0F4F8),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      style: GoogleFonts.epilogue(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF003355),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    onPressed: () {
                      double val = double.tryParse(maxController.text) ?? 0.0;
                      maxController.text = (val + 0.1).toStringAsFixed(1);
                    },
                    icon: const Icon(Icons.add),
                    style: IconButton.styleFrom(
                      backgroundColor: const Color(0xFFE1F5FE),
                      foregroundColor: const Color(0xFF0288D1),
                      padding: const EdgeInsets.all(12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
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
              onPressed: () {
                final minVal = double.tryParse(minController.text);
                final maxVal = double.tryParse(maxController.text);
                if (minVal != null && maxVal != null && minVal < maxVal) {
                  onSave(minVal, maxVal);
                  Navigator.pop(context);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Minimum value must be less than maximum!',
                      ),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF0288D1),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'Save',
                style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold),
              ),
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
        Text(
          'Alert Thresholds',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF003355),
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
          ),
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
                },
              ),
              const SizedBox(height: 12),
              _buildInputField(
                label: 'TEMPERATURE MAX',
                value: '${settings.tempMax}°C',
                onTap: () {
                  _showEditDialog(
                    context: context,
                    title: 'Temperature Maximum',
                    suffix: '°C',
                    currentValue: settings.tempMax.toString(),
                    step: 0.5,
                    fractionDigits: 1,
                    onSave: (newValue) {
                      final parsedValue = double.tryParse(newValue);
                      if (parsedValue != null) {
                        context.read<SettingsProvider>().updateDeviceSetting(
                          'temp_max',
                          parsedValue,
                        );
                      }
                    },
                  );
                },
              ),
              const SizedBox(height: 12),
              _buildInputField(
                label: 'TURBIDITY MAX',
                value: '${settings.turbidityMax.toInt()} ADC',
                onTap: () {
                  _showEditDialog(
                    context: context,
                    title: 'Turbidity Maximum',
                    suffix: 'ADC',
                    currentValue: settings.turbidityMax.toStringAsFixed(0),
                    step: 50.0,
                    fractionDigits: 0,
                    onSave: (newValue) {
                      final parsedValue = double.tryParse(newValue);
                      if (parsedValue != null) {
                        context.read<SettingsProvider>().updateDeviceSetting(
                          'turbidity_max',
                          parsedValue,
                        );
                      }
                    },
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInputField({
    required String label,
    required String value,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFF7F9FC),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.black54,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 15,
                    color: const Color(0xFF1E293B),
                  ),
                ),
              ],
            ),
            const Icon(Icons.edit, color: Color(0xFF003355), size: 18),
          ],
        ),
      ),
    );
  }
}
