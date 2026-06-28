class AlertModel {
  final int? id;
  final DateTime createdAt;
  final String type;
  final String title;
  final String description;
  final bool isResolved;
  final String sensorType; 
  final double? value; 
  final String? unit; 

  AlertModel({
    this.id,
    required this.createdAt,
    required this.type,
    required this.title,
    required this.description,
    this.isResolved = false,
    required this.sensorType,
    this.value,
    this.unit,
  });

  factory AlertModel.fromJson(Map<String, dynamic> json) {
    String rawSensorType = json['sensor_type']?.toString().toUpperCase() ?? 'SYSTEM';
    String generatedTitle = "$rawSensorType ALERT";

    String alertType = 'SYSTEM';
    if (json['severity'] == 'danger') {
      alertType = 'ALERT';
    } else if (json['severity'] == 'warning') {
      alertType = 'WARNING';
    }

    return AlertModel(
      id: json['id'],
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : DateTime.now(),
      type: alertType,
      title: generatedTitle,
      description: json['message'] ?? 'No description provided.',
      isResolved: json['resolved'] ?? false,
      sensorType: rawSensorType,
      value: json['value'] != null ? double.tryParse(json['value'].toString()) : null,
      unit: json['unit']?.toString() ?? '',
    );
  }
}