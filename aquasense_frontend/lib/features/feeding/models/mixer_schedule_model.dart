import 'package:flutter/material.dart';

class MixerScheduleModel {
  final int? id;
  final TimeOfDay time;
  final int durationMin;
  final bool isActive;

  MixerScheduleModel({
    this.id,
    required this.time,
    required this.durationMin,
    this.isActive = true,
  });

  factory MixerScheduleModel.fromJson(Map<String, dynamic> json) {
    final timeParts = json['schedule_time'].toString().split(':');
    return MixerScheduleModel(
      id: json['id'],
      time: TimeOfDay(hour: int.parse(timeParts[0]), minute: int.parse(timeParts[1])),
      durationMin: json['duration_min'] ?? 15,
      isActive: json['is_active'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    final hourStr = time.hour.toString().padLeft(2, '0');
    final minuteStr = time.minute.toString().padLeft(2, '0');
    return {
      'schedule_time': '$hourStr:$minuteStr:00',
      'duration_min': durationMin,
      'is_active': isActive,
    };
  }
}