import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/mixer_schedule_model.dart';

class MixerProvider extends ChangeNotifier {
  final _supabase = Supabase.instance.client;

  bool _isMixerOn = false;
  int _remainingSec = 0;
  bool _isCooldownActive = false;
  bool _isLoading = false;
  List<MixerScheduleModel> _mixerSchedules = [];

  bool get isMixerOn => _isMixerOn;
  bool get isOn => _isMixerOn; 
  int get remainingSec => _remainingSec;
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
        _remainingSec = response['remaining_sec'] ?? 0;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Failed to fetch mixer status: $e');
    }
  }

  Future<bool> toggleMixer(int durationMin) async {
    if (_isCooldownActive) return false;

    final targetStatus = !_isMixerOn;
    
    try {
      final updateData = {
        'is_on': targetStatus,
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (targetStatus) {
        final durationSec = durationMin * 60;
        updateData['duration_sec'] = durationSec;
        updateData['remaining_sec'] = durationSec;
      } else {
        updateData['remaining_sec'] = 0;
      }

      await _supabase.from('mixer_status').update(updateData).eq('id', 1);
      
      _isMixerOn = targetStatus;
      _remainingSec = targetStatus ? (durationMin * 60) : 0;
      
      if (!targetStatus) {
        _isCooldownActive = true;
        notifyListeners();

        await Future.delayed(const Duration(seconds: 5));
        _isCooldownActive = false;
      }
      
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Failed to toggle mixer: $e');
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
      debugPrint('Failed to fetch mixer schedules: $e');
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
      debugPrint('Failed to add mixer schedule: $e');
      return false;
    }
  }

  Future<void> deleteMixerSchedule(int id) async {
    try {
      _mixerSchedules.removeWhere((s) => s.id == id);
      notifyListeners();
      await _supabase.from('mixer_schedules').delete().eq('id', id);
    } catch (e) {
      debugPrint('Failed to delete mixer schedule: $e');
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
      debugPrint('Failed to update mixer schedule status: $e');
      fetchMixerSchedules();
    }
  }
}