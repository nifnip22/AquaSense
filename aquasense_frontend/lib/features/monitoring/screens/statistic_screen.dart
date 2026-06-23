import 'package:aquasense_frontend/features/monitoring/widgets/feed_level_card.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:aquasense_frontend/shared/widgets/custom_app_bar.dart';
import '../providers/sensor_provider.dart';
import '../widgets/metric_chart_card.dart';
import '../widgets/time_filter.dart';

class StatisticScreen extends StatefulWidget {
  const StatisticScreen({super.key});

  @override
  State<StatisticScreen> createState() => _StatisticScreenState();
}

class _StatisticScreenState extends State<StatisticScreen> {
  Color _getStatusColor(String? status) {
    if (status == null) return Colors.grey;
    
    final s = status.toUpperCase();
    
    if (s.contains('NORMAL') || s.contains('OPTIMAL') || s.contains('GOOD')) {
      return const Color(0xFF00897B);
    } 
    else if (s.contains('HIGH') || s.contains('LOW') || s.contains('WARNING')) {
      return Colors.orange.shade700;
    } 
    else if (s.contains('ERROR') || s.contains('CRITICAL') || s.contains('DANGER')) {
      return const Color(0xFFD32F2F);
    }
    
    return Colors.black87;
  }

  @override
  Widget build(BuildContext context) {
    final sensorState = context.watch<SensorProvider>();
    final data = sensorState.currentData;

    final isDataLoading = sensorState.isChartLoading;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: const CustomAppBar(),
      body: isDataLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(
                    width: 40,
                    height: 40,
                    child: CircularProgressIndicator(
                      color: Color(0xFF003355),
                      strokeWidth: 3,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Menyiapkan data grafik...',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade600,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  TimeFilter(
                    selectedIndex: sensorState.timeFilterIndex,

                    onFilterChanged: (index) {
                      sensorState.updateTimeFilter(index);
                    },
                  ),
                  const SizedBox(height: 24),

                  // Card 1: Water Temperature
                  MetricChartCard(
                    title: 'Water Temperature',
                    icon: Icons.thermostat,
                    iconColor: const Color(0xFF00BCD4),
                    badgeText: 'Live',
                    badgeColor: const Color(0xFFE0F7FA),
                    badgeTextColor: const Color(0xFF0097A7),
                    subTitle: 'Current Water Temp',
                    chartData: sensorState.tempHistory,
                    statsBox1Title: 'CURRENT',
                    statsBox1Value: '${data.temperature}°C',
                    statsBox2Title: 'STATUS',
                    statsBox2Value: (data.tempStatus ?? 'Normal').replaceAll('_', ' ').toUpperCase(),
                    statsBox2ValueColor: _getStatusColor(data.tempStatus),
                    lineColor: const Color(0xFF4DD0E1),
                    gradientColors: [
                      const Color(0xFF4DD0E1).withValues(alpha: 0.5),
                      const Color(0xFF4DD0E1).withValues(alpha: 0.0),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Card 2: pH Level
                  MetricChartCard(
                    title: 'pH Level',
                    icon: Icons.water_drop,
                    iconColor: const Color(0xFF00897B),
                    badgeText: 'Live',
                    badgeColor: const Color(0xFFE0F2F1),
                    badgeTextColor: const Color(0xFF00695C),
                    subTitle: 'Live Monitoring',
                    chartData: sensorState.phHistory, 
                    statsBox1Title: 'CURRENT',
                    statsBox1Value: '${data.phLevel}',
                    statsBox2Title: 'STATUS',
                    statsBox2Value: (data.phStatus ?? 'Optimal').replaceAll('_', ' ').toUpperCase(),
                    statsBox2ValueColor: _getStatusColor(data.phStatus),
                    lineColor: const Color(0xFF4DB6AC),
                    gradientColors: [
                      const Color(0xFF4DB6AC).withValues(alpha: 0.3),
                      const Color(0xFF4DB6AC).withValues(alpha: 0.0),
                    ],
                    isStatsValue2Text: true,
                  ),
                  const SizedBox(height: 16),

                  // Card 3: Feed Level Gauge
                  FeedLevelCard(currentLevel: data.feedLevelPct),
                ],
              ),
            ),
    );
  }
}