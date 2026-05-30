import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';

class MetricChartCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color iconColor;
  final String badgeText;
  final Color badgeColor;
  final Color badgeTextColor;
  final String subTitle;
  final List<FlSpot> chartData;
  final Color lineColor;
  final List<Color> gradientColors;
  final String statsBox1Title;
  final String statsBox1Value;
  final String statsBox2Title;
  final String statsBox2Value;
  final bool isStatsValue2Text;

  const MetricChartCard({
    super.key,
    required this.title,
    required this.icon,
    required this.iconColor,
    required this.badgeText,
    required this.badgeColor,
    required this.badgeTextColor,
    required this.subTitle,
    required this.chartData,
    required this.lineColor,
    required this.gradientColors,
    required this.statsBox1Title,
    required this.statsBox1Value,
    required this.statsBox2Title,
    required this.statsBox2Value,
    this.isStatsValue2Text = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: lineColor, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(icon, color: iconColor, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    title,
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
                  color: badgeColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  badgeText,
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
            subTitle,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              color: Colors.black54,
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 120,
            child: LineChart(
              LineChartData(
                gridData: const FlGridData(show: false),
                titlesData: const FlTitlesData(show: false),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: chartData,
                    isCurved: true,
                    color: lineColor,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        colors: gradientColors,
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: _buildStatsBox(statsBox1Title, statsBox1Value, false),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatsBox(
                  statsBox2Title,
                  statsBox2Value,
                  isStatsValue2Text,
                  valueColor: isStatsValue2Text
                      ? Colors.teal
                      : const Color(0xFF003355),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatsBox(
    String title,
    String value,
    bool isTextValue, {
    Color? valueColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F4F8),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: Colors.black54,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: isTextValue
                ? GoogleFonts.plusJakartaSans(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: valueColor ?? const Color(0xFF003355),
                  )
                : GoogleFonts.epilogue(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF003355),
                  ),
          ),
        ],
      ),
    );
  }
}
