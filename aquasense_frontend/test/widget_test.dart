import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:aquasense_frontend/main.dart';
import 'package:aquasense_frontend/features/monitoring/providers/sensor_provider.dart';

void main() {
  testWidgets('App renders correctly', (WidgetTester tester) async {
    // Membungkus aplikasi dengan Provider saat pengujian agar tidak crash
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => SensorProvider()),
        ],
        child: const AquaSenseApp(),
      ),
    );
    
    // Memastikan widget utama berhasil dimuat
    expect(find.byType(AquaSenseApp), findsOneWidget);
  });
}