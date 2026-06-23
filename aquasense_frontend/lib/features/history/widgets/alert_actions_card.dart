import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AlertActionsCard extends StatelessWidget {
  final String sensorType;
  
  const AlertActionsCard({super.key, required this.sensorType});

  List<Map<String, dynamic>> get _actions {
    switch (sensorType) {
      case 'TEMPERATURE':
        return [
          {'icon': Icons.thermostat, 'text': 'Check the temperature sensor to see if it is completely submerged in water.', 'highlight': true},
          {'icon': Icons.water_drop, 'text': 'Add new/cool water manually to neutralize the temperature.', 'highlight': false},
          {'icon': Icons.wb_sunny, 'text': 'Make sure the pool is protected from direct sunlight.', 'highlight': false},
        ];
      case 'TURBIDITY':
        return [
          {'icon': Icons.cleaning_services, 'text': 'Clean the tip of the water turbidity sensor probe.', 'highlight': true},
          {'icon': Icons.water, 'text': 'Drain and replace some of the pool water manually', 'highlight': false},
          {'icon': Icons.delete_sweep, 'text': 'Check for accumulation of leftover feed at the bottom of the pond', 'highlight': false},
        ];
      case 'PH':
      case 'FEED_LEVEL':
        return [
          {'icon': Icons.inventory_2, 'text': 'Refill the pellets into the feed dispenser container', 'highlight': true},
          {'icon': Icons.cleaning_services, 'text': 'Check and clean the output funnel if there are any clogged pellets.', 'highlight': false},
          {'icon': Icons.sensors, 'text': 'Clean the proximity sensor (ultrasonic) in the container cover.', 'highlight': false},
        ];
      default:
        return [
          {'icon': Icons.check_circle_outline, 'text': 'Check for any excess pollution or dirt.', 'highlight': false},
          {'icon': Icons.water, 'text': 'Perform a partial water change', 'highlight': true},
          {'icon': Icons.science_outlined, 'text': 'Add dolomitic lime or pH buffer manually', 'highlight': false},
        ];
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
          BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(color: Color(0xFFE0F7FA), shape: BoxShape.circle),
                child: const Icon(Icons.check_circle_outline, color: Color(0xFF00BCD4), size: 20),
              ),
              const SizedBox(width: 12),
              Text('Recommended Actions', style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFF003355))),
            ],
          ),
          const SizedBox(height: 20),
          
          ..._actions.asMap().entries.map((entry) {
            final int index = entry.key;
            final action = entry.value;
            return Padding(
              padding: EdgeInsets.only(bottom: index == _actions.length - 1 ? 0 : 12.0),
              child: _buildActionItem(
                icon: action['icon'] as IconData, 
                text: action['text'] as String, 
                isHighlighted: action['highlight'] as bool
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildActionItem({required IconData icon, required String text, bool isHighlighted = false}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isHighlighted ? const Color(0xFFE0F2F1) : const Color(0xFFF7F9FC),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: isHighlighted ? const Color(0xFF007B83) : Colors.grey.shade300, width: 1),
      ),
      child: Row(
        children: [
          Icon(icon, color: isHighlighted ? const Color(0xFF007B83) : Colors.black54, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: isHighlighted ? FontWeight.bold : FontWeight.w500,
                color: isHighlighted ? const Color(0xFF007B83) : Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }
}