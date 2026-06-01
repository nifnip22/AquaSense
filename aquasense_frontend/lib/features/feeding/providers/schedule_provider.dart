import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ScheduleProvider extends ChangeNotifier {
  // Default values
  bool _isMorningActive = true;
  bool _isAfternoonActive = true;
  bool _isNightActive = false;
  double _feedDuration = 3.0;

  // Getter
  bool get isMorningActive => _isMorningActive;
  bool get isAfternoonActive => _isAfternoonActive;
  bool get isNightActive => _isNightActive;
  double get feedDuration => _feedDuration;

  ScheduleProvider() {
    _loadScheduleData();
  }

  // Function to load schedule data from local storage when the app is opened
  Future<void> _loadScheduleData() async {
    final prefs = await SharedPreferences.getInstance();
    
    _isMorningActive = prefs.getBool('morning_active') ?? true;
    _isAfternoonActive = prefs.getBool('afternoon_active') ?? true;
    _isNightActive = prefs.getBool('night_active') ?? false;
    _feedDuration = prefs.getDouble('feed_duration') ?? 3.0;
    
    notifyListeners();
  }

  // Function to toggle morning schedule
  Future<void> toggleMorning(bool value) async {
    _isMorningActive = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('morning_active', value);
  }

  // Function to toggle afternoon schedule
  Future<void> toggleAfternoon(bool value) async {
    _isAfternoonActive = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('afternoon_active', value);
  }

  // Function to toggle night schedule
  Future<void> toggleNight(bool value) async {
    _isNightActive = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('night_active', value);
  }

  // Function to save feeding duration (called when the slider is released)
  Future<void> saveFeedDuration(double value) async {
    _feedDuration = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('feed_duration', value);
  }
}