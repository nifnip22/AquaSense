import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:aquasense_frontend/shared/widgets/custom_app_bar.dart';
import '../providers/sensor_provider.dart';
import '../widgets/metric_chart_card.dart';
import '../widgets/time_filter.dart';
import '../widgets/feed_level_card.dart';

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
                  // In this block, it can update the data displayed in the charts based on the selected time filter. For example:
                  // if (index == 0) {
                  //   // Load data for last 24 hours
                  // } else if (index == 1) {
                  //   // Load data for last 7 days
                  // } else if (index == 2) {
                  //   // Load data for last 30 days
                  // }
                });
              },
            ),
            const SizedBox(height: 24),

            // Card 1: Water Temperature
            MetricChartCard(
              title: 'Water Temperature',
              icon: Icons.thermostat,
              iconColor: const Color(0xFF00BCD4),
              badgeText: 'Stable',
              badgeColor: const Color(0xFFE0F7FA),
              badgeTextColor: const Color(0xFF0097A7),
              subTitle: 'Live Monitoring',
              chartData: sensorState.tempHistory,
              statsBox1Title: 'CURRENT',
              statsBox1Value: '${data.temperature}°C',
              statsBox2Title: 'STATUS',
              statsBox2Value: 'Optimal',
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
              iconColor: const Color(0xFF003355),
              badgeText: 'Optimal',
              badgeColor: const Color(0xFFECEFF1),
              badgeTextColor: const Color(0xFF455A64),
              subTitle: 'Live Monitoring',
              chartData: sensorState.phHistory, 
              statsBox1Title: 'CURRENT',
              statsBox1Value: '${data.phLevel}',
              statsBox2Title: 'STABILITY',
              statsBox2Value: 'High',
              lineColor: const Color(0xFF003355),
              gradientColors: [
                const Color(0xFF003355).withValues(alpha: 0.3),
                const Color(0xFF003355).withValues(alpha: 0.0),
              ],
              isStatsValue2Text: true,
            ),
            const SizedBox(height: 16),

            // Card 3: Feed Level
            FeedLevelCard(currentLevel: data.feedLevel),
          ],
        ),
      ),
    );
  }
}