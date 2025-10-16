import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../models/task_model.dart';
import '../../theme/app_theme.dart';

class TaskCard extends StatelessWidget {
  final TaskModel task;
  final VoidCallback? onTap;
  final bool showCompanyActions;

  const TaskCard({super.key, required this.task, this.onTap, this.showCompanyActions = false});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasExpiry = task.expiryDate != null;
    final isExpired = hasExpiry && task.expiryDate!.isBefore(DateTime.now());
    final isUrgent =
        hasExpiry &&
        task.expiryDate!.isAfter(DateTime.now()) &&
        task.expiryDate!.difference(DateTime.now()).inDays <= 3;

    // Format dates
    final dateFormat = DateFormat('MMM d, yyyy');
    final createdDate = dateFormat.format(task.createdAt);

    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with colored accent based on urgency
            Container(
              decoration: BoxDecoration(
                color: isExpired
                    ? AppTheme.error.withOpacity(0.1)
                    : isUrgent
                    ? AppTheme.warning.withOpacity(0.1)
                    : AppTheme.primaryColor.withOpacity(0.1),
                borderRadius: const BorderRadius.only(topLeft: Radius.circular(12), topRight: Radius.circular(12)),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      task.title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: isExpired
                            ? AppTheme.error
                            : isUrgent
                            ? AppTheme.warning
                            : AppTheme.primaryColor,
                      ),
                    ),
                  ),
                  if (hasExpiry) _buildExpiryBadge(context, isExpired, isUrgent),
                ],
              ),
            ),

            // Content
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Description (truncated)
                  Text(
                    task.description.length > 100 ? '${task.description.substring(0, 100)}...' : task.description,
                    style: theme.textTheme.bodyMedium,
                  ),

                  const SizedBox(height: 16),

                  // Domain tags
                  if (task.domains.isNotEmpty) ...[
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: task.domains.map((domain) => _buildDomainChip(context, domain)).toList(),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Task metadata
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Effort hours
                      Row(
                        children: [
                          const Icon(Icons.access_time, size: 16, color: AppTheme.textMuted),
                          const SizedBox(width: 4),
                          Text('${task.effortHours} hours', style: theme.textTheme.bodySmall),
                        ],
                      ),

                      // Created date
                      Row(
                        children: [
                          const Icon(Icons.calendar_today, size: 16, color: AppTheme.textMuted),
                          const SizedBox(width: 4),
                          Text(createdDate, style: theme.textTheme.bodySmall),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Company actions if needed
            if (showCompanyActions)
              Container(
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(12),
                    bottomRight: Radius.circular(12),
                  ),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton.icon(
                      onPressed: () => Navigator.pushNamed(context, '/submissions/review', arguments: task.taskId),
                      icon: const Icon(Icons.assignment_turned_in, size: 16),
                      label: const Text('View Submissions'),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        visualDensity: VisualDensity.compact,
                      ),
                    ),
                    const SizedBox(width: 8),
                    TextButton.icon(
                      onPressed: () {
                        // TODO: Implement task editing
                        ScaffoldMessenger.of(
                          context,
                        ).showSnackBar(const SnackBar(content: Text('Task editing coming soon')));
                      },
                      icon: const Icon(Icons.edit, size: 16),
                      label: const Text('Edit'),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        visualDensity: VisualDensity.compact,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildExpiryBadge(BuildContext context, bool isExpired, bool isUrgent) {
    final theme = Theme.of(context);
    final dateFormat = DateFormat('MMM d');
    final expiryDate = dateFormat.format(task.expiryDate!);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isExpired
            ? AppTheme.error
            : isUrgent
            ? AppTheme.warning
            : AppTheme.primaryColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(isExpired ? Icons.warning : Icons.event, size: 14, color: Colors.white),
          const SizedBox(width: 4),
          Text(
            isExpired ? 'Expired' : 'Due $expiryDate',
            style: theme.textTheme.bodySmall?.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildDomainChip(BuildContext context, String domain) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.secondaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.secondaryColor.withOpacity(0.3)),
      ),
      child: Text(domain, style: TextStyle(fontSize: 12, color: AppTheme.secondaryColor)),
    );
  }
}
