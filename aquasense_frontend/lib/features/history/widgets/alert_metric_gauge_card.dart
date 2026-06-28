import 'package:aquasense_frontend/features/history/models/alert_model.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../settings/providers/settings_provider.dart';

class AlertMetricGaugeCard extends StatelessWidget {
  final AlertModel alert;

  const AlertMetricGaugeCard({super.key, required this.alert});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();

    final type = alert.sensorType;
    final value = alert.value ?? 0.0;

    String title = 'CURRENT $type';
    String normalRange = '';
    String minLabel = '';
    String midLabel = 'OPTIMAL';
    String maxLabel = '';

    double minBound = 0;
    double maxBound = 100;
    List<Color> barColors = [];

    IconData? minIcon;
    IconData? maxIcon;

    if (type == 'PH') {
      normalRange =
          '${settings.phMin.toStringAsFixed(1)} - ${settings.phMax.toStringAsFixed(1)}';
      minLabel = 'ACIDIC';
      maxLabel = 'ALKALINE';
      minIcon = Icons.science_outlined;
      maxIcon = Icons.water_drop_outlined;
      minBound = 0;
      maxBound = 14;
      barColors = [
        const Color(0xFFC62828),
        const Color(0xFF007B83),
        const Color(0xFF8D4B20),
      ];
    } else if (type == 'TEMPERATURE') {
      normalRange = '28.0 - ${settings.tempMax.toStringAsFixed(1)} °C';
      minLabel = 'COLD';
      maxLabel = 'HOT';
      minIcon = Icons.ac_unit;
      maxIcon = Icons.local_fire_department;
      minBound = 10;
      maxBound = 50;
      barColors = [
        const Color(0xFF0288D1),
        const Color(0xFF007B83),
        const Color(0xFFC62828),
      ];
    } else if (type == 'TURBIDITY') {
      normalRange = '< ${settings.turbidityMax.toInt()} ADC';
      minLabel = 'DIRTY';
      maxLabel = 'CLEAR';
      minIcon = Icons.blur_on;
      maxIcon = Icons.water;
      minBound = 0;
      maxBound = 4095;
      barColors = [
        const Color(0xFFC62828),
        const Color(0xFFF57F17),
        const Color(0xFF007B83),
      ];
    } else if (type == 'FEED_LEVEL') {
      title = 'FEED REMAINING';
      normalRange = '> 20 %';
      minLabel = 'EMPTY';
      maxLabel = 'FULL';
      midLabel = 'HALF';
      minIcon = Icons.hourglass_empty;
      maxIcon = Icons.inventory;
      minBound = 0;
      maxBound = 100;
      barColors = [
        const Color(0xFFC62828),
        const Color(0xFFFBC02D),
        const Color(0xFF4CAF50),
      ];
    }

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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.black54,
                      letterSpacing: 0.5
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    value.toStringAsFixed(
                      type == 'TURBIDITY' || type == 'FEED_LEVEL' ? 0 : 1,
                    ),
                    style: GoogleFonts.epilogue(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFFC62828),
                      height: 1.0,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'NORMAL RANGE',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.black54,
                      letterSpacing: 0.5
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    normalRange,
                    style: GoogleFonts.epilogue(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF003355),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 40),

          LayoutBuilder(
            builder: (context, constraints) {
              double percent = (value - minBound) / (maxBound - minBound);
              percent = percent.clamp(0.0, 1.0);
              double leftPosition = (percent * constraints.maxWidth) - 16;
              if (leftPosition < 0) leftPosition = 0;
              if (leftPosition > constraints.maxWidth - 32) {
                leftPosition = constraints.maxWidth - 32;
              }

              return Stack(
                clipBehavior: Clip.none,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: SizedBox(
                      height: 12,
                      child: Row(
                        children: [
                          Expanded(
                            flex: 3,
                            child: Container(
                              color: barColors.isNotEmpty
                                  ? barColors[0]
                                  : Colors.grey,
                            ),
                          ),
                          Expanded(
                            flex: 4,
                            child: Container(
                              color: barColors.isNotEmpty
                                  ? barColors[1]
                                  : Colors.grey,
                            ),
                          ),
                          Expanded(
                            flex: 3,
                            child: Container(
                              color: barColors.isNotEmpty
                                  ? barColors[2]
                                  : Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    left: leftPosition,
                    top: -30,
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFC62828),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            value.toStringAsFixed(1),
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
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
              );
            },
          ),
          const SizedBox(height: 12),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  if (minIcon != null)
                    Icon(minIcon, size: 14, color: Colors.black54),
                  if (minIcon != null) const SizedBox(width: 4),
                  Text(
                    minLabel,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
              Text(
                midLabel,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              Row(
                children: [
                  Text(
                    maxLabel,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  if (maxIcon != null) const SizedBox(width: 4),
                  if (maxIcon != null)
                    Icon(maxIcon, size: 14, color: Colors.black54),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
