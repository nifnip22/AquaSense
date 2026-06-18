class AlertModel {
  final int? id;
  final DateTime createdAt;
  final String type;
  final String title;
  final String description;
  final bool isResolved;

  AlertModel({
    this.id,
    required this.createdAt,
    required this.type,
    required this.title,
    required this.description,
    this.isResolved = false,
  });

  factory AlertModel.fromJson(Map<String, dynamic> json) {
    String sensorName = json['sensor_type']?.toString().toUpperCase() ?? 'SYSTEM';
    String generatedTitle = "$sensorName ALERT";

    String alertType = 'SYSTEM';
    if (json['severity'] == 'danger') {
      alertType = 'ALERT';
    } else if (json['severity'] == 'warning') {
      alertType = 'WARNING';
    }

    return AlertModel(
      id: json['id'],
      createdAt: DateTime.parse(json['created_at']),
      type: alertType,
      title: generatedTitle,
      description: json['message'] ?? 'No description provided.',
      isResolved: json['resolved'] ?? false,
    );
  }
}