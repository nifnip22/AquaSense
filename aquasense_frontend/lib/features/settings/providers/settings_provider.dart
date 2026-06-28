import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SettingsProvider extends ChangeNotifier {
  final _supabase = Supabase.instance.client;
  final String _deviceId = 'ESP32-DEVKIT-01';

  // Default values
  bool _isEcoModeActive = false;
  double _phMin = 6.5;
  double _phMax = 8.5;
  double _tempMax = 32.0;
  double _turbidityMax = 2000.0;

  double _phOffset = 0.0;
  double _turbiditySensitivity = 0.0;
  double _waterLevelOffset = 0.0;

  // Getter
  bool get isEcoModeActive => _isEcoModeActive;
  
  double get phMin => _phMin;
  double get phMax => _phMax;
  double get tempMax => _tempMax;
  double get turbidityMax => _turbidityMax;
  
  double get phOffset => _phOffset;
  double get turbiditySensitivity => _turbiditySensitivity;
  double get waterLevelOffset => _waterLevelOffset;

  SettingsProvider() {
    _loadLocalSettings();
    _loadDeviceSettings();
  }

  // Take care of loading settings from SharedPreferences when the provider is initialized
  Future<void> _loadLocalSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _isEcoModeActive = prefs.getBool('eco_mode') ?? false;
    notifyListeners();
  }

  Future<void> toggleEcoMode(bool value) async {
    _isEcoModeActive = value;
    notifyListeners();
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('eco_mode', value);
  }

  // Function to toggle eco mode and save the setting
  Future<void> _loadDeviceSettings() async {
    try {
      final response = await _supabase
          .from('device_settings')
          .select()
          .eq('id', _deviceId)
          .single();
      
      _phMin = (response['ph_min'] ?? 6.5).toDouble();
      _phMax = (response['ph_max'] ?? 8.5).toDouble();
      _tempMax = (response['temp_max'] ?? 32.0).toDouble();
      _turbidityMax = (response['turbidity_max'] ?? 2000.0).toDouble();
      
      _phOffset = (response['ph_offset'] ?? 0.0).toDouble();
      _turbiditySensitivity = (response['turbidity_offset'] ?? 0.0).toDouble();
      _waterLevelOffset = (response['water_level_offset'] ?? 0.0).toDouble();
      
      notifyListeners();
    } catch (e) {
      debugPrint('Belum ada data di Supabase atau gagal memuat: $e');
    }
  }

  Future<void> updateDeviceSetting(String column, double value) async {
    try {
      await _supabase.from('device_settings').upsert({
        'id': _deviceId,
        column: value,
        'updated_at': DateTime.now().toIso8601String(),
      });
      
      await _loadDeviceSettings();
    } catch (e) {
      debugPrint('Gagal update $column: $e');
    }
  }

  // Function to update pH range and save the settings
  Future<void> updatePhRange(double min, double max) async {
    try {
      await _supabase.from('device_settings').upsert({
        'id': _deviceId,
        'ph_min': min,
        'ph_max': max,
        'updated_at': DateTime.now().toIso8601String(),
      });
      
      await _loadDeviceSettings();
    } catch (e) {
      debugPrint('Gagal update pH Range: $e');
    }
  }
}