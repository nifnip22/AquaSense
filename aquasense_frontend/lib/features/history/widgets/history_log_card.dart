import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class HistoryLogCard extends StatelessWidget {
  final String title;
  final IconData iconData;
  final Color iconColor;
  final Color iconBgColor;
  final Color borderColor;
  final String? subtitleText;
  final Widget? customSubtitle;
  final bool showArrow;

  const HistoryLogCard({
    super.key,
    required this.title,
    required this.iconData,
    required this.iconColor,
    required this.iconBgColor,
    required this.borderColor,
    this.subtitleText,
    this.customSubtitle,
    this.showArrow = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: borderColor, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Icon Container
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: iconBgColor,
              shape: BoxShape.circle,
            ),
            child: Icon(iconData, color: iconColor, size: 24),
          ),
          const SizedBox(width: 16),
          
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1E293B),
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 8),
                if (customSubtitle != null)
                  customSubtitle!
                else if (subtitleText != null)
                  Row(
                    children: [
                      Icon(Icons.access_time, size: 14, color: Colors.grey.shade600),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          subtitleText!,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            color: Colors.grey.shade700,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),

          if (showArrow) ...[
            const SizedBox(width: 12),
            Icon(Icons.chevron_right, color: Colors.grey.shade400, size: 28),
          ]
        ],
      ),
    );
  }
}