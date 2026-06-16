import 'dart:async';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/sensor_model.dart';

class SensorProvider extends ChangeNotifier {
  final _supabase = Supabase.instance.client;

  SensorModel _currentData = SensorModel(
    temperature: 0.0,
    tempStatus: 'waiting...',
    phLevel: 0.0,
    phStatus: 'waiting...',
    turbidityRaw: 0,
    turbidityStatus: 'waiting...',
    feedLevelPct: 0.0,
    feedStatus: 'waiting...',
  );

  SensorModel get currentData => _currentData;

  final List<FlSpot> _tempHistory = [];
  final List<FlSpot> _phHistory = [];
  final List<FlSpot> _feedLevelHistory = [];

  double _timeIndex = 0;

  List<FlSpot> get tempHistory => _tempHistory;
  List<FlSpot> get phHistory => _phHistory;
  List<FlSpot> get feedLevelHistory => _feedLevelHistory;

  Timer? _fetchTimer;
  Timer? _statusTimer;

  bool _isDispensing = false;
  bool get isDispensing => _isDispensing;

  bool _isDeviceOnline = false;
  bool get isDeviceOnline => _isDeviceOnline;

  SensorProvider() {
    _startRealDataFetch();
  }

  // === FETCH DATA FROM DATABASE FUNCTION ===
  void _startRealDataFetch() {
    _fetchLatestData();

    _fetchTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      _fetchLatestData();
    });

    _statusTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      _evaluateDeviceStatus();
    });
  }

  void _evaluateDeviceStatus() {
    if (_currentData.recordedAt == null) {
      if (_isDeviceOnline) {
        _isDeviceOnline = false;
        notifyListeners();
      }
      return;
    }

    final difference = DateTime.now().difference(_currentData.recordedAt!);
    final isCurrentlyOnline = difference.inMinutes < 3;

    if (_isDeviceOnline != isCurrentlyOnline) {
      _isDeviceOnline = isCurrentlyOnline;
      notifyListeners();
    }
  }

  Future<void> _fetchLatestData() async {
    try {
      final response = await _supabase
          .from('latest_readings')
          .select()
          .limit(1);

      if (response.isNotEmpty) {
        final data = response.first;
        _currentData = SensorModel.fromJson(data);

        _evaluateDeviceStatus();

        _tempHistory.add(FlSpot(_timeIndex, _currentData.temperature));
        _phHistory.add(FlSpot(_timeIndex, _currentData.phLevel));
        _feedLevelHistory.add(FlSpot(_timeIndex, _currentData.feedLevelPct));

        if (_tempHistory.length > 10) _tempHistory.removeAt(0);
        if (_phHistory.length > 10) _phHistory.removeAt(0);
        if (_feedLevelHistory.length > 10) _feedLevelHistory.removeAt(0);

        _timeIndex++;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Gagal menarik data asli: $e');
    }
  }

  String get turbidityStatusText {
    return _currentData.turbidityStatus ?? 'Unknown';
  }

  Future<bool> dispenseFeedManual(int durationSec) async {
    if (_isDispensing) return false;

    _isDispensing = true;
    notifyListeners();

    try {
      await _supabase.from('feeding_logs').insert({
        'trigger_type': 'manual',
        'duration_sec': durationSec,
        'notes': 'Triggered instantly from mobile app',
      });

      await Future.delayed(const Duration(seconds: 10));
      return true;
    } catch (e) {
      debugPrint('Gagal memicu pemberian pakan manual: $e');
      return false;
    } finally {
      _isDispensing = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _fetchTimer?.cancel();
    _statusTimer?.cancel();
    super.dispose();
  }
}
