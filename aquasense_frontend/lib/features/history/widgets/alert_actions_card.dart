import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AlertActionsCard extends StatelessWidget {
  const AlertActionsCard({super.key});

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
                decoration: const BoxDecoration(color: Color(0xFFE0F7FA), shape: BoxShape.circle),
                child: const Icon(Icons.check_circle_outline, color: Color(0xFF00BCD4), size: 20),
              ),
              const SizedBox(width: 12),
              Text('Recommended Actions', style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFF003355))),
            ],
          ),
          const SizedBox(height: 20),
          _buildActionItem(icon: Icons.check_circle_outline, text: 'Check for upstream pollution or debris'),
          const SizedBox(height: 12),
          _buildActionItem(
            icon: Icons.water, 
            text: 'Activate Water Pump for circulation', 
            isHighlighted: true,
          ),
          const SizedBox(height: 12),
          _buildActionItem(icon: Icons.science_outlined, text: 'Consider adding lime or pH buffer manually if persistent'),
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
        border: Border.all(
          color: isHighlighted ? const Color(0xFF007B83) : Colors.grey.shade300,
          width: 1,
        ),
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