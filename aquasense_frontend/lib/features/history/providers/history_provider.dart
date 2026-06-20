import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/log_model.dart';

class HistoryProvider extends ChangeNotifier {
  final _supabase = Supabase.instance.client;

  List<LogModel> _logs = [];
  bool _isLoading = false;

  List<LogModel> get logs => _logs;
  bool get isLoading => _isLoading;

  HistoryProvider() {
    fetchLogs();
  }

  Future<void> fetchLogs() async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _supabase
          .from('activity_logs')
          .select()
          .order('created_at', ascending: false)
          .limit(100);

      _logs = response.map((json) => LogModel.fromJson(json)).toList();
    } catch (e) {
      debugPrint('Gagal menarik data log riwayat: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}