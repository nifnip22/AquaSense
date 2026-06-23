import 'package:aquasense_frontend/features/history/models/alert_model.dart';
import 'package:aquasense_frontend/shared/services/notification_service.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class HistoryProvider extends ChangeNotifier {
  final _supabase = Supabase.instance.client;

  List<AlertModel> _alerts = [];
  bool _isLoading = false;

  List<AlertModel> get alerts => _alerts;
  bool get isLoading => _isLoading;

  HistoryProvider() {
    NotificationService().init();
    _listenToNewAlerts();
    fetchLogs();
  }

  Future<void> fetchLogs() async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _supabase
          .from('combined_history_logs')
          .select()
          .order('created_at', ascending: false)
          .limit(100);

      _alerts = response.map((json) => AlertModel.fromJson(json)).toList();
    } catch (e) {
      debugPrint('Gagal menarik data log riwayat: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void _listenToNewAlerts() {
    _supabase.channel('public:alerts').onPostgresChanges(
      event: PostgresChangeEvent.insert,
      schema: 'public',
      table: 'alerts',
      callback: (payload) {
        final newRecord = payload.newRecord;
        final sensorType = newRecord['sensor_type']?.toString().toUpperCase() ?? 'SISTEM';
        final message = newRecord['message']?.toString() ?? 'Silakan cek aplikasi AquaSense untuk detail peringatan.';
        
        NotificationService().showNotification(
          id: DateTime.now().millisecondsSinceEpoch ~/ 1000, 
          title: 'Peringatan: $sensorType',
          body: message,
        );

        fetchLogs();
      },
    ).subscribe();
  }
}