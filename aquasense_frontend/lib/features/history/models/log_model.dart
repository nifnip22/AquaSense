class LogModel {
  final int id;
  final String title;
  final String message;
  final String type; // 'feeding', 'alert', 'system'
  final DateTime createdAt;

  LogModel({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.createdAt,
  });

  factory LogModel.fromJson(Map<String, dynamic> json) {
    return LogModel(
      id: json['id'] ?? 0,
      title: json['title'] ?? 'Notification',
      message: json['message'] ?? '',
      type: json['type']?.toString().toLowerCase() ?? 'system',
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at'].toString()).toLocal() 
          : DateTime.now(),
    );
  }
}