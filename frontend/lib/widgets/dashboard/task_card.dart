import 'package:flutter/material.dart';

import '../../models/task_model.dart';
import '../../theme/app_theme.dart';

class TaskCard extends StatelessWidget {
  final TaskModel task;
  final VoidCallback? onTap;
  final bool? hasSubmission; // Student has submitted for this task
  final bool? isPendingReview; // Submission is pending review (no grade yet)
  final int? submissionGrade; // Grade if reviewed

  const TaskCard({
    super.key,
    required this.task,
    this.onTap,
    this.hasSubmission,
    this.isPendingReview,
    this.submissionGrade,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          task.title,
                          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          task.description,
                          style: theme.textTheme.bodyMedium,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${task.effortHours}h',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: task.domains.map((domain) {
                  return Chip(
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    label: Text(domain, style: theme.textTheme.bodySmall?.copyWith(color: AppTheme.textLight)),
                    backgroundColor: theme.colorScheme.secondary,
                    padding: EdgeInsets.zero,
                    visualDensity: VisualDensity.compact,
                  );
                }).toList(),
              ),
              if (task.expiryDate != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.access_time, size: 16, color: _getExpiryColor(task.expiryDate!, theme)),
                    const SizedBox(width: 4),
                    Text(
                      _getExpiryText(task.expiryDate!),
                      style: theme.textTheme.bodySmall?.copyWith(color: _getExpiryColor(task.expiryDate!, theme)),
                    ),
                  ],
                ),
              ],
              // Submission status badge for students
              if (hasSubmission == true) ...[const SizedBox(height: 12), _buildSubmissionStatusBadge(context)],
            ],
          ),
        ),
      ),
    );
  }

  String _getExpiryText(DateTime expiryDate) {
    final now = DateTime.now();
    final difference = expiryDate.difference(now);

    if (difference.isNegative) {
      return 'Expired';
    } else if (difference.inDays == 0) {
      return 'Due today';
    } else if (difference.inDays == 1) {
      return 'Due tomorrow';
    } else if (difference.inDays < 7) {
      return 'Due in ${difference.inDays} days';
    } else {
      return 'Due on ${expiryDate.day}/${expiryDate.month}/${expiryDate.year}';
    }
  }

  Color _getExpiryColor(DateTime expiryDate, ThemeData theme) {
    final now = DateTime.now();
    final difference = expiryDate.difference(now);

    if (difference.isNegative) {
      return AppTheme.error;
    } else if (difference.inDays < 3) {
      return AppTheme.warning;
    } else {
      return theme.colorScheme.onBackground.withOpacity(0.6);
    }
  }

  Widget _buildSubmissionStatusBadge(BuildContext context) {
    final theme = Theme.of(context);
    final bool isReviewed = submissionGrade != null;
    final bool pending = isPendingReview == true;

    final Color statusColor;
    final IconData statusIcon;
    final String statusText;

    if (isReviewed) {
      // Reviewed - show grade
      final grade = submissionGrade!;
      if (grade >= 80) {
        statusColor = AppTheme.success;
        statusIcon = Icons.verified;
        statusText = 'Reviewed: $grade%';
      } else if (grade >= 60) {
        statusColor = Colors.blue;
        statusIcon = Icons.check_circle;
        statusText = 'Reviewed: $grade%';
      } else {
        statusColor = Colors.orange;
        statusIcon = Icons.info;
        statusText = 'Reviewed: $grade%';
      }
    } else if (pending) {
      // Pending review
      statusColor = AppTheme.warning;
      statusIcon = Icons.pending_actions;
      statusText = 'Review Pending';
    } else {
      // Submitted but status unknown
      statusColor = AppTheme.accentColor;
      statusIcon = Icons.check_circle_outline;
      statusText = 'Submitted';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: statusColor.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(statusIcon, size: 16, color: statusColor),
          const SizedBox(width: 8),
          Text(
            statusText,
            style: theme.textTheme.bodySmall?.copyWith(color: statusColor, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
