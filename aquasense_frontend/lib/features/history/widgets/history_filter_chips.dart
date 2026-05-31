import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class HistoryFilterChips extends StatefulWidget {
  final Function(String) onFilterSelected;

  const HistoryFilterChips({super.key, required this.onFilterSelected});

  @override
  State<HistoryFilterChips> createState() => _HistoryFilterChipsState();
}

class _HistoryFilterChipsState extends State<HistoryFilterChips> {
  int _selectedIndex = 0;
  final List<String> _filters = ['ALL', 'FEEDING', 'ALERTS', 'SYSTEM'];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: List.generate(_filters.length, (index) {
          final isSelected = _selectedIndex == index;
          return Padding(
            padding: const EdgeInsets.only(right: 12.0),
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _selectedIndex = index;
                });
                widget.onFilterSelected(_filters[index]);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFF003355) : Colors.transparent,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: isSelected ? const Color(0xFF003355) : Colors.grey.shade300,
                    width: 1.5,
                  ),
                ),
                child: Text(
                  _filters[index],
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
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