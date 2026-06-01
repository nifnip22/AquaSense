import 'package:aquasense_frontend/features/dashboard/screens/main_screen.dart';
import 'package:aquasense_frontend/features/feeding/providers/schedule_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'features/monitoring/providers/sensor_provider.dart';
import 'features/settings/providers/settings_provider.dart';

void main() async {
  // Make sure Flutter bindings are initialized before we do anything else, especially before we load environment variables or initialize Supabase.
  WidgetsFlutterBinding.ensureInitialized();

  // Load credentials from the .env file.
  await dotenv.load(fileName: ".env");

  // Initialize Supabase with the URL and anon key from the environment variables.
  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
  );

  runApp(
    /*Using MultiProvider to set up our providers for state management. 
     *Currently, we only have SensorProvider, but this structure allows us to easily add more providers in the future as our app grows.
    */ 
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => SensorProvider()),
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
        ChangeNotifierProvider(create: (_) => ScheduleProvider()),
      ],
      child: const AquaSenseApp(),
    ),
  );
}

class AquaSenseApp extends StatelessWidget {
  const AquaSenseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AquaSense',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
        textTheme: GoogleFonts.plusJakartaSansTextTheme(
          Theme.of(context).textTheme,
        ),
      ),
      home: const MainScreen(),
    );
  }
}