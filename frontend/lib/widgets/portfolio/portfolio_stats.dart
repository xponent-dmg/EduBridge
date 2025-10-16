import 'package:flutter/material.dart';

import '../../models/portfolio_model.dart';
import '../../theme/app_theme.dart';

class PortfolioStats extends StatelessWidget {
  final List<PortfolioEntryModel> entries;

  const PortfolioStats({super.key, required this.entries});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Calculate stats
    final totalEntries = entries.length;
    final completedEntries = entries.where((e) => e.submission.grade != null).length;
    final averageGrade = _calculateAverageGrade();
    final domains = _calculateDomains();

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Portfolio Stats', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),

            // Stats grid
            Row(
              children: [
                _StatItem(
                  title: 'Total Tasks',
                  value: totalEntries.toString(),
                  icon: Icons.task_alt,
                  color: theme.colorScheme.primary,
                ),
                _StatItem(
                  title: 'Completed',
                  value: completedEntries.toString(),
                  icon: Icons.check_circle,
                  color: AppTheme.success,
                ),
                _StatItem(
                  title: 'Avg. Grade',
                  value: averageGrade != null ? '$averageGrade%' : 'N/A',
                  icon: Icons.grade,
                  color: AppTheme.warning,
                ),
              ],
            ),

            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 8),

            // Domain tags
            Text('Skills & Domains', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),

            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: domains.entries.map((entry) {
                return Chip(
                  label: Text(entry.key, style: TextStyle(fontSize: 12, color: theme.colorScheme.onSecondary)),
                  backgroundColor: theme.colorScheme.secondary,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  visualDensity: VisualDensity.compact,
                  avatar: CircleAvatar(
                    backgroundColor: Colors.white,
                    radius: 8,
                    child: Text(
                      entry.value.toString(),
                      style: TextStyle(fontSize: 10, color: theme.colorScheme.secondary, fontWeight: FontWeight.bold),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  int? _calculateAverageGrade() {
    final gradedEntries = entries.where((e) => e.submission.grade != null).toList();
    if (gradedEntries.isEmpty) return null;

    final sum = gradedEntries.fold<int>(0, (sum, entry) => sum + (entry.submission.grade ?? 0));

    return (sum / gradedEntries.length).round();
  }

  Map<String, int> _calculateDomains() {
    final domainCounts = <String, int>{};

    for (final entry in entries) {
      for (final domain in entry.task.domains) {
        domainCounts[domain] = (domainCounts[domain] ?? 0) + 1;
      }
    }

    return domainCounts;
  }
}

class _StatItem extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatItem({required this.title, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Expanded(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold, color: color),
          ),
          const SizedBox(height: 4),
          Text(title, style: theme.textTheme.bodySmall, textAlign: TextAlign.center),
        ],
      ),
    );
  }
}
