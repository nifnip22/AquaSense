import 'package:flutter/material.dart';

class ScheduleModel {
  final int? id;
  final TimeOfDay time;
  final int durationSec;
  final bool isActive;

  ScheduleModel({
    this.id,
    required this.time,
    required this.durationSec,
    this.isActive = true,
  });

  factory ScheduleModel.fromJson(Map<String, dynamic> json) {
    final timeParts = json['schedule_time'].toString().split(':');
    final hour = int.parse(timeParts[0]);
    final minute = int.parse(timeParts[1]);

    return ScheduleModel(
      id: json['id'],
      time: TimeOfDay(hour: hour, minute: minute),
      durationSec: json['duration_sec'] ?? 5,
      isActive: json['is_active'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    final hourStr = time.hour.toString().padLeft(2, '0');
    final minuteStr = time.minute.toString().padLeft(2, '0');
    final timeSqlFormat = '$hourStr:$minuteStr:00';

    return {
      'schedule_time': timeSqlFormat,
      'duration_sec': durationSec,
      'is_active': isActive,
    };
  }
}