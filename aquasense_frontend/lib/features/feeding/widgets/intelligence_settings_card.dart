import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class IntelligenceSettingsCard extends StatefulWidget {
  const IntelligenceSettingsCard({super.key});

  @override
  State<IntelligenceSettingsCard> createState() => _IntelligenceSettingsCardState();
}

class _IntelligenceSettingsCardState extends State<IntelligenceSettingsCard> {
  bool _isAdaptiveTemp = true;
  bool _isEcoMode = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(32),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.psychology, color: Color(0xFF003355), size: 24),
              const SizedBox(width: 8),
              Text(
                'Intelligence Settings',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF003355),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildSettingRow(
            title: 'Adaptive Temperature\nFeeding',
            desc: 'Automatically delays feeding if water temperature is too cold.',
            isActive: _isAdaptiveTemp,
            onChanged: (val) => setState(() => _isAdaptiveTemp = val),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Divider(color: Colors.white, thickness: 2),
          ),
          _buildSettingRow(
            title: 'Eco Power Mode',
            desc: 'Enters deep sleep when battery is low to preserve system life.',
            isActive: _isEcoMode,
            onChanged: (val) => setState(() => _isEcoMode = val),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingRow({required String title, required String desc, required bool isActive, required Function(bool) onChanged}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF003355),
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                desc,
                style: GoogleFonts.plusJakartaSans(fontSize: 12, color: Colors.black54),
              ),
            ],
          ),
        ),
        Switch(
          value: isActive,
          onChanged: onChanged,
          activeThumbColor: Colors.white,
          activeTrackColor: const Color(0xFF00BCD4),
          inactiveThumbColor: Colors.white,
          inactiveTrackColor: Colors.grey.shade400,
          trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
        ),
      ],
    );
  }
}