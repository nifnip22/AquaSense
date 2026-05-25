class SensorModel {
  final double temperature;
  final double phLevel;
  final double turbidity;
  final double waterLevel;

  SensorModel({
    required this.temperature,
    required this.phLevel,
    required this.turbidity,
    required this.waterLevel,
  });

  /*This factory function will be very helpful for converting data when the application starts 
   *receiving JSON format from the API or Supabase later on.
  */ 
  factory SensorModel.fromJson(Map<String, dynamic> json) {
    return SensorModel(
      temperature: json['temperature']?.toDouble() ?? 0.0,
      phLevel: json['ph_level']?.toDouble() ?? 0.0,
      turbidity: json['turbidity']?.toDouble() ?? 0.0,
      waterLevel: json['water_level']?.toDouble() ?? 0.0,
    );
  }
}