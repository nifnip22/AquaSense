import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';

class FeedLevelCard extends StatelessWidget {
  final double currentLevel;
  final List<FlSpot> feedHistory;

  const FeedLevelCard({
    super.key,
    required this.currentLevel,
    required this.feedHistory,
  });

  @override
  Widget build(BuildContext context) {
    final isLow = currentLevel < 20.0;
    final mainColor = isLow ? const Color(0xFFD32F2F) : const Color(0xFFFF9800);
    final badgeBgColor = isLow
        ? const Color(0xFFFFEBEE)
        : const Color(0xFFFFF3E0);
    final badgeTextColor = isLow
        ? const Color(0xFFC62828)
        : const Color(0xFFE65100);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: mainColor.withValues(alpha: 0.3), width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.inventory_2, color: mainColor, size: 20),
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
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: badgeBgColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  isLow ? 'LOW STOCK' : 'STOCKED',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: badgeTextColor,
                  ),
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
                minY: 0,
                maxY: 100,
                minX: 0,
                maxX: 7,
                gridData: const FlGridData(show: false),
                titlesData: const FlTitlesData(show: false),
                borderData: FlBorderData(show: false),

                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipColor: (LineBarSpot touchedSpot) => badgeBgColor,
                    getTooltipItems: (List<LineBarSpot> touchedSpots) {
                      return touchedSpots.map((LineBarSpot touchedSpot) {
                        return LineTooltipItem(
                          '${touchedSpot.y.toInt()}%',
                          GoogleFonts.plusJakartaSans(
                            color: mainColor, 
                            fontWeight: FontWeight.w900,
                            fontSize: 16,
                          ),
                        );
                      }).toList();
                    },
                  ),
                  getTouchedSpotIndicator: (LineChartBarData barData, List<int> spotIndexes) {
                    return spotIndexes.map((spotIndex) {
                      return TouchedSpotIndicatorData(
                        FlLine(color: mainColor.withValues(alpha: 0.3), strokeWidth: 2, dashArray: [4, 4]),
                        FlDotData(
                          show: true,
                          getDotPainter: (spot, percent, barData, index) {
                            return FlDotCirclePainter(
                              radius: 4,
                              color: badgeBgColor,
                              strokeWidth: 2,
                              strokeColor: mainColor,
                            );
                          },
                        ),
                      );
                    }).toList();
                  },
                ),
                lineBarsData: [
                  LineChartBarData(
                    spots: feedHistory.isEmpty 
                        ? const [FlSpot(0, 0), FlSpot(7, 0)] 
                        : feedHistory,
                    isCurved: false,
                    isStepLineChart: true,
                    color: mainColor.withValues(alpha: 0.4),
                    barWidth: 2,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) {
                        return FlDotCirclePainter(
                          radius: 3,
                          color: Colors.white,
                          strokeWidth: 2,
                          strokeColor: mainColor,
                        );
                      },
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      color: mainColor.withValues(alpha: 0.1),
                    ),
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
                        value: currentLevel / 100,
                        strokeWidth: 8,
                        backgroundColor: Colors.white,
                        valueColor: AlwaysStoppedAnimation<Color>(mainColor),
                      ),
                    ),
                    Text(
                      '${currentLevel.toInt()}%',
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
                  isLow ? 'ASAP' : '2 days',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isLow
                        ? const Color(0xFFD32F2F)
                        : const Color(0xFF003355),
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
