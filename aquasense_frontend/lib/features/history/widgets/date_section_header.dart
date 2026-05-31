import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class DateSectionHeader extends StatelessWidget {
  final String dateText;

  const DateSectionHeader({super.key, required this.dateText});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          dateText,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF1E293B),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Divider(
            color: Colors.grey.shade300,
            thickness: 1,
          ),
        ),
      ],
    );
  }
}