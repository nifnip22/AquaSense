import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';

class FeedLevelCard extends StatelessWidget {
  const FeedLevelCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: Colors.grey.shade300, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.inventory_2, color: Color(0xFF455A64), size: 20),
              const SizedBox(width: 8),
              Text(
                'Feed Level',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF003355),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Last 7 Days',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              color: Colors.black54,
            ),
          ),
          const SizedBox(height: 24),
          
          SizedBox(
            height: 80,
            child: LineChart(
              LineChartData(
                gridData: const FlGridData(show: false),
                titlesData: const FlTitlesData(show: false),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: const [
                      FlSpot(0, 100),
                      FlSpot(2, 100),
                      FlSpot(2, 85),
                      FlSpot(4, 85),
                      FlSpot(4, 60),
                      FlSpot(6, 60),
                      FlSpot(6, 45),
                      FlSpot(7, 45),
                    ],
                    isCurved: false,
                    isStepLineChart: true,
                    color: Colors.grey.shade400,
                    barWidth: 2,
                    dotData: const FlDotData(show: false),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 24),
            decoration: BoxDecoration(
              color: const Color(0xFFF0F4F8),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              children: [
                Text(
                  'CURRENT LEVEL',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Colors.black54,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 16),
                Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 80,
                      height: 80,
                      child: CircularProgressIndicator(
                        value: 0.75,
                        strokeWidth: 8,
                        backgroundColor: Colors.white,
                        valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF007B83)),
                      ),
                    ),
                    Text(
                      '75%',
                      style: GoogleFonts.epilogue(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF003355),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          
          // Refill information
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              color: const Color(0xFFF0F4F8),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'REFILL IN',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.black54,
                  ),
                ),
                Text(
                  '2 days',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF003355),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}