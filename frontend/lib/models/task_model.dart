class TaskModel {
  final String taskId;
  final String title;
  final String description;
  final List<String> domains;
  final int effortHours;
  final String postedBy;
  final DateTime? expiryDate;
  final DateTime createdAt;

  TaskModel({
    required this.taskId,
    required this.title,
    required this.description,
    required this.domains,
    required this.effortHours,
    required this.postedBy,
    this.expiryDate,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  factory TaskModel.fromJson(Map<String, dynamic> json) {
    return TaskModel(
      taskId: json['task_id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      domains: json['domains'] != null ? List<String>.from(json['domains']) : [],
      effortHours: json['effort_hours'] ?? 0,
      postedBy: json['posted_by'] ?? '',
      expiryDate: json['expiry_date'] != null ? DateTime.parse(json['expiry_date']) : null,
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'task_id': taskId,
      'title': title,
      'description': description,
      'domains': domains,
      'effort_hours': effortHours,
      'posted_by': postedBy,
      'expiry_date': expiryDate?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
    };
  }

  TaskModel copyWith({
    String? taskId,
    String? title,
    String? description,
    List<String>? domains,
    int? effortHours,
    String? postedBy,
    DateTime? expiryDate,
    DateTime? createdAt,
  }) {
    return TaskModel(
      taskId: taskId ?? this.taskId,
      title: title ?? this.title,
      description: description ?? this.description,
      domains: domains ?? this.domains,
      effortHours: effortHours ?? this.effortHours,
      postedBy: postedBy ?? this.postedBy,
      expiryDate: expiryDate ?? this.expiryDate,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
