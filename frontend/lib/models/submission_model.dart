class SubmissionModel {
  final String submissionId;
  final String taskId;
  final String? fileUrl;
  final String? feedback;
  final int? grade;
  final DateTime submittedAt;

  SubmissionModel({
    required this.submissionId,
    required this.taskId,
    this.fileUrl,
    this.feedback,
    this.grade,
    DateTime? submittedAt,
  }) : submittedAt = submittedAt ?? DateTime.now();

  factory SubmissionModel.fromJson(Map<String, dynamic> json) {
    return SubmissionModel(
      submissionId: json['submission_id'] ?? '',
      taskId: json['task_id'] ?? '',
      fileUrl: json['file_url'],
      feedback: json['feedback'],
      grade: json['grade'],
      submittedAt: json['submitted_at'] != null ? DateTime.parse(json['submitted_at']) : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'submission_id': submissionId,
      'task_id': taskId,
      'file_url': fileUrl,
      'feedback': feedback,
      'grade': grade,
      'submitted_at': submittedAt.toIso8601String(),
    };
  }

  SubmissionModel copyWith({
    String? submissionId,
    String? taskId,
    String? fileUrl,
    String? feedback,
    int? grade,
    DateTime? submittedAt,
  }) {
    return SubmissionModel(
      submissionId: submissionId ?? this.submissionId,
      taskId: taskId ?? this.taskId,
      fileUrl: fileUrl ?? this.fileUrl,
      feedback: feedback ?? this.feedback,
      grade: grade ?? this.grade,
      submittedAt: submittedAt ?? this.submittedAt,
    );
  }
}
