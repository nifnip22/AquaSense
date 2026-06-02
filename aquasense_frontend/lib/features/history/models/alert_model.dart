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
    return AlertModel(
      id: json['id'],
      createdAt: DateTime.parse(json['created_at']),
      type: json['type'],
      title: json['title'],
      description: json['description'] ?? '',
      isResolved: json['is_resolved'] ?? false,
    );
  }
}