class SensorModel {
  final double temperature;
  final String? tempStatus;
  final double phLevel;
  final String? phStatus;
  final int turbidityRaw; 
  final String? turbidityStatus;
  final double feedLevelPct;
  final String? feedStatus;
  final DateTime? recordedAt;

  SensorModel({
    required this.temperature,
    this.tempStatus,
    required this.phLevel,
    this.phStatus,
    required this.turbidityRaw,
    this.turbidityStatus,
    required this.feedLevelPct,
    this.feedStatus,
    this.recordedAt,
  });

  factory SensorModel.fromJson(Map<String, dynamic> json) {
    double safeDouble(dynamic value) {
      if (value == null) return 0.0;
      if (value is num) return value.toDouble();
      if (value is String) return double.tryParse(value) ?? 0.0;
      return 0.0;
    }

    return SensorModel(
      temperature: safeDouble(json['temperature']),
      tempStatus: json['temp_status']?.toString() ?? 'Unknown',
      phLevel: safeDouble(json['ph'] ?? json['pH']), 
      phStatus: json['ph_status']?.toString() ?? 'Unknown',
      turbidityRaw: (json['turbidity_raw'] as num?)?.toInt() ?? 0,
      turbidityStatus: json['turbidity_status']?.toString() ?? 'Unknown',
      feedLevelPct: safeDouble(json['feed_level_pct']),
      feedStatus: json['feed_status']?.toString() ?? 'Unknown',
      recordedAt: json['recorded_at'] != null 
          ? DateTime.tryParse(json['recorded_at'].toString())?.toLocal() 
          : null,
    );
  }
}