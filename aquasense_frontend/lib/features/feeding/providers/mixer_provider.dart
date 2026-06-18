import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/mixer_schedule_model.dart';

class MixerProvider extends ChangeNotifier {
  final _supabase = Supabase.instance.client;

  bool _isMixerOn = false;
  bool _isCooldownActive = false;
  bool _isLoading = false;
  List<MixerScheduleModel> _mixerSchedules = [];

  bool get isMixerOn => _isMixerOn;
  bool get isCooldownActive => _isCooldownActive;
  bool get isLoading => _isLoading;
  List<MixerScheduleModel> get mixerSchedules => _mixerSchedules;

  MixerProvider() {
    fetchMixerStatus();
    fetchMixerSchedules();
  }

  Future<void> fetchMixerStatus() async {
    try {
      final response = await _supabase.from('mixer_status').select().eq('id', 1).maybeSingle();
      if (response != null) {
        _isMixerOn = response['is_on'] ?? false;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Gagal mengambil status mixer: $e');
    }
  }

  Future<bool> toggleMixer() async {
    if (_isCooldownActive) return false;

    final targetStatus = !_isMixerOn;
    
    try {
      await _supabase.from('mixer_status').update({'is_on': targetStatus}).eq('id', 1);
      _isMixerOn = targetStatus;
      
      if (!targetStatus) {
        _isCooldownActive = true;
        notifyListeners();

        await Future.delayed(const Duration(seconds: 5));
        _isCooldownActive = false;
      }
      
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Gagal mengubah saklar mixer: $e');
      fetchMixerStatus();
      return false;
    }
  }

  Future<void> fetchMixerSchedules() async {
    _isLoading = true;
    try {
      final response = await _supabase.from('mixer_schedules').select().order('schedule_time', ascending: true);
      _mixerSchedules = response.map((json) => MixerScheduleModel.fromJson(json)).toList();
    } catch (e) {
      debugPrint('Gagal mengambil jadwal mixer: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> addMixerSchedule(TimeOfDay time, int durationMin) async {
    try {
      final newSchedule = MixerScheduleModel(time: time, durationMin: durationMin);
      await _supabase.from('mixer_schedules').insert(newSchedule.toJson());
      await fetchMixerSchedules();
      return true;
    } catch (e) {
      debugPrint('Gagal menambah jadwal mixer: $e');
      return false;
    }
  }

  Future<void> deleteMixerSchedule(int id) async {
    try {
      _mixerSchedules.removeWhere((s) => s.id == id);
      notifyListeners();
      await _supabase.from('mixer_schedules').delete().eq('id', id);
    } catch (e) {
      debugPrint('Gagal menghapus jadwal mixer: $e');
      fetchMixerSchedules();
    }
  }

  Future<void> toggleMixerScheduleStatus(int scheduleId, bool currentStatus) async {
    try {
      final index = _mixerSchedules.indexWhere((s) => s.id == scheduleId);
      if (index != -1) {
        final old = _mixerSchedules[index];
        _mixerSchedules[index] = MixerScheduleModel(
          id: old.id,
          time: old.time,
          durationMin: old.durationMin,
          isActive: !currentStatus,
        );
        notifyListeners();
      }

      await _supabase
          .from('mixer_schedules')
          .update({'is_active': !currentStatus})
          .eq('id', scheduleId);

    } catch (e) {
      debugPrint('Gagal mengubah status jadwal mixer: $e');
      fetchMixerSchedules();
    }
  }
}