class SensorModel {
  final double temperature;
  final String? tempStatus;
  final double phLevel;
  final String? phStatus;
  final int turbidityRaw; 
  final String? turbidityStatus;
  final double feedLevelPct;
  final String? feedStatus;

  SensorModel({
    required this.temperature,
    this.tempStatus,
    required this.phLevel,
    this.phStatus,
    required this.turbidityRaw,
    this.turbidityStatus,
    required this.feedLevelPct,
    this.feedStatus,
  });

  /*This factory function will be very helpful for converting data when the application starts 
   *receiving JSON format from the API or Supabase later on.
  */ 
  factory SensorModel.fromJson(Map<String, dynamic> json) {
    return SensorModel(
      temperature: json['temperature']?.toDouble() ?? 0.0,
      tempStatus: json['temp_status']?.toString() ?? 'Unknown',
      phLevel: json['ph_level']?.toDouble() ?? 0.0,
      phStatus: json['ph_status']?.toString() ?? 'Unknown',
      turbidityRaw: json['turbidity_raw']?.toInt() ?? 0,
      turbidityStatus: json['turbidity_status']?.toString() ?? 'Unknown',
      feedLevelPct: json['feed_level_pct']?.toDouble() ?? 0.0,
      feedStatus: json['feed_status']?.toString() ?? 'Unknown',
    );
  }
}