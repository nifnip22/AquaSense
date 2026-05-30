import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/sensor_provider.dart';
import 'package:google_fonts/google_fonts.dart';

class MonitorScreen extends StatelessWidget {
  const MonitorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Read the current sensor data from the provider. Whenever sensorData changes, this widget will rebuild with the new values.
    final sensorData = context.watch<SensorProvider>().sensorData;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Row(
          children: [
            Text(
              'AquaSense',
              style: GoogleFonts.epilogue(
                fontWeight: FontWeight.bold,
                color: const Color(0xFF003355),
              ),
            ),
            const SizedBox(width: 12),
            // Badge Status Online
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFE0F2F1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.teal.shade300),
              ),
              child: Row(
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: Colors.teal,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Text(
                    'ONLINE',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.teal,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert, color: Colors.black54),
            onPressed: () {},
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _buildMetricCard(
                  icon: Icons.thermostat,
                  value: '${sensorData.temperature}°C',
                  label: 'WATER TEMP',
                ),
                _buildMetricCard(
                  icon: Icons.water_drop,
                  value: '${sensorData.phLevel}',
                  label: 'PH LEVEL',
                ),
                _buildMetricCard(
                  icon: Icons.waves,
                  value: 'Normal', // Static for now, can be dynamic based on turbidity value
                  label: 'TURBIDITY',
                ),
                _buildMetricCard(
                  icon: Icons.inventory_2,
                  value: '85%', // Static for now, can be dynamic based on feed level value
                  label: 'FEED LEVEL',
                ),
              ],
            ),
            const SizedBox(height: 32),
            
            // Control Center
            Row(
              children: [
                const Icon(Icons.tune, color: Color(0xFF003355)),
                const SizedBox(width: 8),
                Text(
                  'Control Center',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF003355),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Dispense Feed Button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF003355),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(28),
                  ),
                ),
                onPressed: () {
                  // Logika memicu aktuator blower nantinya
                },
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('DISPENSE FEED', style: TextStyle(fontWeight: FontWeight.bold)),
                    Icon(Icons.restaurant),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            
            // Water Pump Status
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.water, color: Colors.black54),
                          SizedBox(width: 8),
                          Text('Water Pump', style: TextStyle(color: Colors.black87)),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text('Standby', style: TextStyle(fontSize: 12)),
                      ),
                    ],
                  ),
                  const Divider(height: 24),
                  const Row(
                    children: [
                      Icon(Icons.access_time, size: 16, color: Colors.black54),
                      SizedBox(width: 8),
                      Text('Last fed: 16:30 WITA', style: TextStyle(color: Colors.black54)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper widget for building each metric card with consistent styling
  Widget _buildMetricCard({required IconData icon, required String value, required String label}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
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
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(
              color: Color(0xFFE1F5FE),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: const Color(0xFF0288D1)),
          ),
          const Spacer(),
          Text(
            value,
            style: GoogleFonts.epilogue(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF003355),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              fontWeight: FontWeight.w900,
              color: Colors.black54,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}