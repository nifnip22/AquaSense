import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'features/monitoring/providers/sensor_provider.dart';

void main() {
  runApp(
    /*Using MultiProvider to set up our providers for state management. 
     *Currently, we only have SensorProvider, but this structure allows us to easily add more providers in the future as our app grows.
    */ 
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => SensorProvider()),
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
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const Scaffold(
        body: Center(
          child: Text('Fondasi AquaSense Siap!'),
        ),
      ),
    );
  }
}