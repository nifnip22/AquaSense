import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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
  @override
  Widget build(BuildContext context) {
    final sensorState = context.watch<SensorProvider>();
    final data = sensorState.currentData;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: const CustomAppBar(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TimeFilter(
              onFilterChanged: (index) {
                setState(() {
                  // Filter logika waktu nantinya diletakkan di sini
                });
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
              statsBox2Value: (data.tempStatus ?? 'Normal').toUpperCase(),
              lineColor: const Color(0xFF4DD0E1),
              gradientColors: [
                const Color(0xFF4DD0E1).withValues(alpha: 0.5),
                const Color(0xFF4DD0E1).withValues(alpha: 0.0),
              ],
            ),
            const SizedBox(height: 16),

            // Card 2: Feed Level Trend
            MetricChartCard(
              title: 'Feed Level Trend',
              icon: Icons.inventory_2,
              iconColor: const Color(0xFF003355),
              badgeText: 'Live',
              badgeColor: const Color(0xFFECEFF1),
              badgeTextColor: const Color(0xFF455A64),
              subTitle: 'Dispenser Capacity',
              chartData: sensorState.feedLevelHistory, 
              statsBox1Title: 'CURRENT',
              statsBox1Value: '${data.feedLevelPct.toInt()}%',
              statsBox2Title: 'STATUS',
              statsBox2Value: (data.feedStatus ?? 'Sufficient').toUpperCase(),
              lineColor: const Color(0xFF003355),
              gradientColors: [
                const Color(0xFF003355).withValues(alpha: 0.3),
                const Color(0xFF003355).withValues(alpha: 0.0),
              ],
              isStatsValue2Text: true,
            ),
          ],
        ),
      ),
    );
  }
}