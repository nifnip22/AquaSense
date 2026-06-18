import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/sensor_provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:aquasense_frontend/shared/widgets/custom_app_bar.dart';

class MonitorScreen extends StatelessWidget {
  const MonitorScreen({super.key});

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
                  value: '${data.temperature}°C',
                  label: 'WATER TEMP',
                ),
                _buildMetricCard(
                  icon: Icons.water_drop,
                  value: '${data.phLevel}',
                  label: 'PH LEVEL',
                ),
                _buildMetricCard(
                  icon: Icons.waves,
                  value: sensorState.turbidityStatusText
                      .replaceAll('_', ' ')
                      .toUpperCase(),
                  label: 'TURBIDITY',
                ),
                _buildMetricCard(
                  icon: Icons.inventory_2,
                  value: '${data.feedLevelPct.toInt()}%',
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
                  // Jika sedang dispensing, ubah warna menjadi abu-abu
                  backgroundColor: sensorState.isDispensing 
                      ? Colors.grey.shade400 
                      : const Color(0xFF003355),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(28),
                  ),
                ),
                // LOGIKA ANTI-SPAM: Jika isDispensing TRUE, onPressed menjadi null (disabled)
                onPressed: sensorState.isDispensing
                    ? null 
                    : () async {
                        // Tampilkan indikasi awal ke pengguna
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text('Mengirim perintah ke dispenser pakan...'),
                            duration: const Duration(seconds: 2),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );

                        final sukses = await sensorState.dispenseFeedManual(5);
                        
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(sukses 
                                  ? 'Pakan berhasil dikeluarkan! Memulai masa cooldown alat...' 
                                  : 'Gagal menghubungi server.'),
                              backgroundColor: sukses ? const Color(0xFF0288D1) : Colors.red,
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        }
                      },
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Teks berubah dinamis sesuai status gembok
                    Text(
                      sensorState.isDispensing ? 'COOLING DOWN (10s)...' : 'DISPENSE FEED', 
                      style: const TextStyle(fontWeight: FontWeight.bold)
                    ),
                    sensorState.isDispensing
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          )
                        : const Icon(Icons.restaurant),
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
                          Text(
                            'Water Pump',
                            style: TextStyle(color: Colors.black87),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          'Standby',
                          style: TextStyle(fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 24),
                  const Row(
                    children: [
                      Icon(Icons.access_time, size: 16, color: Colors.black54),
                      SizedBox(width: 8),
                      Text(
                        'Last fed: 16:30 WITA',
                        style: TextStyle(color: Colors.black54),
                      ),
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
  Widget _buildMetricCard({
    required IconData icon,
    required String value,
    required String label,
  }) {
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
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: GoogleFonts.epilogue(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF003355),
              ),
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
