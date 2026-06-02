import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/sensor_model.dart';

class SensorProvider extends ChangeNotifier {
  final _supabase = Supabase.instance.client;

  SensorModel _currentData = SensorModel(
    temperature: 28.5,
    phLevel: 7.2,
    turbidity: 15.0, 
    feedLevel: 85.0,
  );

  SensorModel get currentData => _currentData;

  final List<FlSpot> _tempHistory = [
    const FlSpot(0, 27.5), const FlSpot(1, 27.8), const FlSpot(2, 28.2), 
    const FlSpot(3, 28.1), const FlSpot(4, 28.8), const FlSpot(5, 29.0), const FlSpot(6, 28.5)
  ];
  
  final List<FlSpot> _phHistory = [
    const FlSpot(0, 7.1), const FlSpot(1, 7.12), const FlSpot(2, 7.15), 
    const FlSpot(3, 7.14), const FlSpot(4, 7.18), const FlSpot(5, 7.2), const FlSpot(6, 7.2)
  ];

  double _timeIndex = 7; 

  List<FlSpot> get tempHistory => _tempHistory;
  List<FlSpot> get phHistory => _phHistory;

  bool _isTempAlertActive = false; 
  bool _isPhAlertActive = false;   

  Timer? _dummyDataTimer;
  final Random _random = Random();

  SensorProvider() {
    _startDummyDataStream();
  }

  void _startDummyDataStream() {
    _dummyDataTimer = Timer.periodic(const Duration(seconds: 10), (timer) async { 
      double tempChange = (_random.nextDouble() * 1.0) - 0.5;
      double phChange = (_random.nextDouble() * 0.1) - 0.05;
      double turbidityChange = (_random.nextDouble() * 2.0) - 1.0;
      
      _currentData = SensorModel(
        temperature: double.parse((_currentData.temperature + tempChange).toStringAsFixed(1)),
        phLevel: double.parse((_currentData.phLevel + phChange).toStringAsFixed(2)),
        turbidity: (_currentData.turbidity + turbidityChange).clamp(0.0, 100.0), 
        feedLevel: _currentData.feedLevel, 
      );

      _tempHistory.add(FlSpot(_timeIndex, _currentData.temperature));
      _phHistory.add(FlSpot(_timeIndex, _currentData.phLevel));

      if (_tempHistory.length > 10) _tempHistory.removeAt(0);
      if (_phHistory.length > 10) _phHistory.removeAt(0);

      _timeIndex++; 
      notifyListeners();

      _checkThresholds(_currentData);

      try {
        await _supabase.from('sensor_logs').insert({
          'temperature': _currentData.temperature,
          'ph_level': _currentData.phLevel,
          'turbidity': _currentData.turbidity,
          'feed_level': _currentData.feedLevel,
        });
        print('Data berhasil dikirim ke Supabase!');
      } catch (e) {
        print('Gagal mengirim data: $e');
      }
    });
  }

  // === CHECK THRESHOLDS FUNCTION ===
  void _checkThresholds(SensorModel data) async {
    if (data.temperature >= 30.0 && !_isTempAlertActive) {
      _isTempAlertActive = true;
      await _sendAlertToSupabase(
        type: 'ALERT',
        title: 'High Temperature Warning',
        description: 'Water temperature reached critical level at ${data.temperature}°C.',
      );
    } else if (data.temperature < 29.5) {
      _isTempAlertActive = false; 
    }

    if (data.phLevel <= 6.5 && !_isPhAlertActive) {
      _isPhAlertActive = true;
      await _sendAlertToSupabase(
        type: 'ALERT',
        title: 'Low pH Level Detected',
        description: 'Acidity has dropped to ${data.phLevel}. Please check water quality.',
      );
    } else if (data.phLevel > 6.8) {
      _isPhAlertActive = false;
    }
  }

  // === FUNCTION FOR SENDING ALERTS TO SUPABASE ===
  Future<void> _sendAlertToSupabase({required String type, required String title, required String description}) async {
    try {
      await _supabase.from('alert_history').insert({
        'type': type,
        'title': title,
        'description': description,
      });
      debugPrint('🚨 ALERT DIKIRIM KE SUPABASE: $title');
    } catch (e) {
      debugPrint('❌ Gagal mengirim alert: $e');
    }
  }

  String get turbidityStatusText {
    if (_currentData.turbidity <= 25.0) {
      return 'Normal';
    } else if (_currentData.turbidity <= 50.0) {
      return 'Cloudy';
    } else {
      return 'Dirty';
    }
  }

  @override
  void dispose() {
    _dummyDataTimer?.cancel();
    super.dispose();
  }
}