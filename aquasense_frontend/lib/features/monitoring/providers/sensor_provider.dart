import 'package:flutter/material.dart';
import '../models/sensor_model.dart';

class SensorProvider extends ChangeNotifier {
  // Initialize with some default values (these will be updated when we fetch real data)
  SensorModel _sensorData = SensorModel(
    temperature: 28.5,
    phLevel: 7.2,
    turbidity: 15.0,
    waterLevel: 50.0,
  );

  // Getter for allowing the UI to read the current sensor data
  SensorModel get sensorData => _sensorData;

  // Method to update the sensor data and notify listeners (UI) to rebuild
  void updateSensorData(SensorModel newData) {
    _sensorData = newData;
    notifyListeners(); // This tells the UI to rebuild with the new data
  }
}