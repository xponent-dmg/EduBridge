import 'package:flutter/material.dart';

import '../../models/portfolio_model.dart';
import '../../theme/app_theme.dart';

class PortfolioCard extends StatelessWidget {
  final PortfolioEntryModel entry;
  final VoidCallback? onTap;

  const PortfolioCard({super.key, required this.entry, this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final submission = entry.submission;
    final task = entry.task;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with task title and grade
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary,
                borderRadius: const BorderRadius.only(topLeft: Radius.circular(12), topRight: Radius.circular(12)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      task.title,
                      style: theme.textTheme.titleMedium?.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  _buildGradeBadge(context, submission.grade),
                ],
              ),
            ),

            // Content
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Domains
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: task.domains.map((domain) {
                      return Chip(
                        label: Text(domain, style: TextStyle(fontSize: 12, color: theme.colorScheme.onSecondary)),
                        backgroundColor: theme.colorScheme.secondary,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        visualDensity: VisualDensity.compact,
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 16),

                  // Feedback
                  if (submission.feedback != null && submission.feedback!.isNotEmpty) ...[
                    Text('Feedback:', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(
                      submission.feedback!,
                      style: theme.textTheme.bodyMedium,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],

                  const SizedBox(height: 8),

                  // Submission date
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Icon(Icons.calendar_today, size: 14, color: theme.colorScheme.onBackground.withOpacity(0.6)),
                      const SizedBox(width: 4),
                      Text(
                        _formatDate(submission.submittedAt),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onBackground.withOpacity(0.6),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGradeBadge(BuildContext context, int? grade) {
    if (grade == null) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(color: Colors.grey.withOpacity(0.3), borderRadius: BorderRadius.circular(16)),
        child: Text(
          'Pending',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
        ),
      );
    }

    Color badgeColor;
    if (grade >= 80) {
      badgeColor = AppTheme.success;
    } else if (grade >= 60) {
      badgeColor = AppTheme.info;
    } else if (grade >= 40) {
      badgeColor = AppTheme.warning;
    } else {
      badgeColor = AppTheme.error;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(color: badgeColor, borderRadius: BorderRadius.circular(16)),
      child: Text(
        '$grade%',
        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
