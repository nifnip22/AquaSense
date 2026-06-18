import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/schedule_model.dart';

class ScheduleProvider extends ChangeNotifier {
  final _supabase = Supabase.instance.client;
  
  List<ScheduleModel> _schedules = [];
  bool _isLoading = false;

  List<ScheduleModel> get schedules => _schedules;
  bool get isLoading => _isLoading;

  ScheduleProvider() {
    fetchSchedules();
  }

  Future<void> fetchSchedules() async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _supabase
          .from('feeding_schedules')
          .select()
          .order('schedule_time', ascending: true);

      _schedules = response.map((json) => ScheduleModel.fromJson(json)).toList();
    } catch (e) {
      debugPrint('Gagal mengambil jadwal: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> addSchedule(TimeOfDay time, int durationSec) async {
    try {
      final newSchedule = ScheduleModel(time: time, durationSec: durationSec);
      await _supabase.from('feeding_schedules').insert(newSchedule.toJson());
      await fetchSchedules();
      return true;
    } catch (e) {
      debugPrint('Gagal menambah jadwal: $e');
      return false;
    }
  }

  Future<void> toggleScheduleStatus(int scheduleId, bool currentStatus) async {
    try {
      final index = _schedules.indexWhere((s) => s.id == scheduleId);
      if (index != -1) {
        final old = _schedules[index];
        _schedules[index] = ScheduleModel(
          id: old.id,
          time: old.time,
          durationSec: old.durationSec,
          isActive: !currentStatus,
        );
        notifyListeners();
      }

      await _supabase
          .from('feeding_schedules')
          .update({'is_active': !currentStatus})
          .eq('id', scheduleId);

    } catch (e) {
      debugPrint('Gagal mengubah status jadwal: $e');
      fetchSchedules();
    }
  }

  Future<void> deleteSchedule(int scheduleId) async {
    try {
      _schedules.removeWhere((s) => s.id == scheduleId);
      notifyListeners();
      await _supabase.from('feeding_schedules').delete().eq('id', scheduleId);
    } catch (e) {
      debugPrint('Gagal menghapus jadwal: $e');
      fetchSchedules();
    }
  }
}