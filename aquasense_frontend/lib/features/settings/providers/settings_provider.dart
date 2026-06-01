import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsProvider extends ChangeNotifier {
  // Default values
  bool _isEcoModeActive = false;
  double _phMin = 6.5;
  double _phMax = 8.5;

  // Getter
  bool get isEcoModeActive => _isEcoModeActive;
  double get phMin => _phMin;
  double get phMax => _phMax;

  SettingsProvider() {
    _loadSettings();
  }

  // Take care of loading settings from SharedPreferences when the provider is initialized
  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    
    _isEcoModeActive = prefs.getBool('eco_mode') ?? false;
    _phMin = prefs.getDouble('ph_min') ?? 6.5;
    _phMax = prefs.getDouble('ph_max') ?? 8.5;
    
    notifyListeners();
  }

  // Function to toggle eco mode and save the setting
  Future<void> toggleEcoMode(bool value) async {
    _isEcoModeActive = value;
    notifyListeners(); // Update UI
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('eco_mode', value);
  }

  // Function to update pH range and save the settings
  Future<void> updatePhRange(double min, double max) async {
    _phMin = min;
    _phMax = max;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('ph_min', min);
    await prefs.setDouble('ph_max', max);
  }
}