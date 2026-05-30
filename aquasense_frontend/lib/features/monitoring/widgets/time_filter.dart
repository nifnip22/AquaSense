import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class TimeFilter extends StatefulWidget {
  // This callback will be called whenever the user selects a different time filter. The parent widget (StatisticScreen) 
  // can use this to update the displayed data accordingly.
  final Function(int) onFilterChanged;

  const TimeFilter({super.key, required this.onFilterChanged});

  @override
  State<TimeFilter> createState() => _TimeFilterState();
}

class _TimeFilterState extends State<TimeFilter> {
  int _selectedIndex = 0;
  final List<String> _filters = ['24h', '7 Days', '30 Days'];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F4F8),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: List.generate(_filters.length, (index) {
          final isSelected = _selectedIndex == index;
          return Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _selectedIndex = index;
                });
                
                widget.onFilterChanged(index); 
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFF003355) : Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                ),
                alignment: Alignment.center,
                child: Text(
                  _filters[index],
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                    color: isSelected ? Colors.white : const Color(0xFF455A64),
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}