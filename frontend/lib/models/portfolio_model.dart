import 'submission_model.dart';
import 'task_model.dart';

class PortfolioEntryModel {
  final String portfolioId;
  final String userId;
  final SubmissionModel submission;
  final TaskModel task;
  final DateTime addedAt;

  PortfolioEntryModel({
    required this.portfolioId,
    required this.userId,
    required this.submission,
    required this.task,
    DateTime? addedAt,
  }) : addedAt = addedAt ?? DateTime.now();

  factory PortfolioEntryModel.fromJson(Map<String, dynamic> json) {
    final submissionData = json['submissions'] as Map<String, dynamic>?;
    final taskData = submissionData?['tasks'] as Map<String, dynamic>?;

    return PortfolioEntryModel(
      portfolioId: json['portfolio_id'] ?? '',
      userId: json['user_id'] ?? '',
      submission: submissionData != null
          ? SubmissionModel.fromJson(submissionData)
          : SubmissionModel(submissionId: '', taskId: '', userId: json['user_id'] ?? ''),
      task: taskData != null
          ? TaskModel.fromJson(taskData)
          : TaskModel(taskId: '', title: '', description: '', domains: [], effortHours: 0, postedBy: ''),
      addedAt: json['added_at'] != null ? DateTime.parse(json['added_at']) : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'portfolio_id': portfolioId,
      'user_id': userId,
      'submission_id': submission.submissionId,
      'added_at': addedAt.toIso8601String(),
    };
  }
}
