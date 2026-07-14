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
  int _manualFeedDuration = 5;
  double _phOffset = 0.0;
  double _turbiditySensitivity = 0.0;
  double _waterLevelOffset = 0.0;

  // Getter
  bool get isEcoModeActive => _isEcoModeActive;
  double get phMin => _phMin;
  double get phMax => _phMax;
  double get tempMax => _tempMax;
  double get turbidityMax => _turbidityMax;
  int get manualFeedDuration => _manualFeedDuration;
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
          .maybeSingle();
      
      if (response != null) {
        _phMin = (response['ph_min'] ?? 6.5).toDouble();
        _phMax = (response['ph_max'] ?? 8.5).toDouble();
        _tempMax = (response['temp_max'] ?? 32.0).toDouble();
        _turbidityMax = (response['turbidity_max'] ?? 2000.0).toDouble();
        _phOffset = (response['ph_offset'] ?? 0.0).toDouble();
        _turbiditySensitivity = (response['turbidity_offset'] ?? 0.0).toDouble();
        _waterLevelOffset = (response['water_level_offset'] ?? 0.0).toDouble();
        _manualFeedDuration = (response['manual_feed_duration'] ?? 5).toInt();
        
        notifyListeners();
      } else {
        debugPrint('Info: The device_settings data for $_deviceId does not yet exist in the database.');
      }
    } catch (e) {
      debugPrint('There is no data in Supabase or it failed to load: $e');
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
      debugPrint('Failed to update $column: $e');
    }
  }

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
      debugPrint('Failed to update pH Range: $e');
    }
  }

  Future<void> updateManualFeedDuration(int seconds) async {
    _manualFeedDuration = seconds;
    notifyListeners();

    try {
      await _supabase.from('device_settings').upsert({
        'id': _deviceId,
        'manual_feed_duration': seconds,
        'updated_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      debugPrint('Failed to update manual feed duration: $e');
    }
  }

  Future<void> resetToDefaultSettings() async {
    final defaultPhMin = 6.5;
    final defaultPhMax = 8.5;
    final defaultTempMax = 32.0;
    final defaultTurbidityMax = 2000.0;
    final defaultManualFeed = 5;

    _phMin = defaultPhMin;
    _phMax = defaultPhMax;
    _tempMax = defaultTempMax;
    _turbidityMax = defaultTurbidityMax;
    _manualFeedDuration = defaultManualFeed;
    notifyListeners();

    try {
      await _supabase.from('device_settings').upsert({
        'id': _deviceId,
        'ph_min': defaultPhMin,
        'ph_max': defaultPhMax,
        'temp_max': defaultTempMax,
        'turbidity_max': defaultTurbidityMax,
        'manual_feed_duration': defaultManualFeed,
        'updated_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      debugPrint('Failed to reset settings: $e');
    }
  }

  Future<bool> saveCalibration({
    required double newPhOffset,
    required double newTurbidityOffset,
  }) async {
    try {
      final updateData = {
        'ph_offset': newPhOffset,
        'turbidity_offset': newTurbidityOffset,
        'updated_at': DateTime.now().toIso8601String(),
      };

      await _supabase
          .from('device_settings')
          .update(updateData)
          .eq('id', _deviceId);

      _phOffset = newPhOffset;
      _turbiditySensitivity = newTurbidityOffset;
      
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Failed to save calibration: $e');
      throw Exception('Failed to update calibration: $e');
    }
  }
}