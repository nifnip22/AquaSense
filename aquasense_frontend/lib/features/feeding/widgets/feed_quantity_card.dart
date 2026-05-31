import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class FeedQuantityCard extends StatefulWidget {
  final double initialDuration;

  const FeedQuantityCard({super.key, this.initialDuration = 3.0});

  @override
  State<FeedQuantityCard> createState() => _FeedQuantityCardState();
}

class _FeedQuantityCardState extends State<FeedQuantityCard> {
  late double _durationSeconds;

  @override
  void initState() {
    super.initState();
    _durationSeconds = widget.initialDuration;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
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
              const Icon(Icons.hourglass_bottom, color: Color(0xFF003355), size: 20),
              const SizedBox(width: 8),
              Text(
                'Feed Quantity',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF003355),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text('Duration', style: GoogleFonts.plusJakartaSans(fontSize: 12, color: Colors.black54)),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${_durationSeconds.toInt()} Seconds',
                style: GoogleFonts.epilogue(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF003355),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF00BCD4),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${(_durationSeconds * 10).toInt()}% DOSAGE',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: const Color(0xFF003355),
              inactiveTrackColor: Colors.grey.shade200,
              thumbColor: const Color(0xFF003355),
              overlayColor: const Color(0xFF003355).withValues(alpha: 0.1),
              trackHeight: 6.0,
            ),
            child: Slider(
              value: _durationSeconds,
              min: 1,
              max: 10,
              divisions: 9,
              onChanged: (val) {
                setState(() => _durationSeconds = val);
              },
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Controls the servo motor duration for precision feed dispensing across the pen diameter.',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              color: Colors.black54,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}