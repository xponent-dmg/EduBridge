import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/task_provider.dart';
import '../../theme/app_theme.dart';

class TaskFilterBar extends StatelessWidget {
  const TaskFilterBar({super.key});

  @override
  Widget build(BuildContext context) {
    final taskProvider = Provider.of<TaskProvider>(context);
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Filter by domain',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: taskProvider.domainFilter.isNotEmpty
                        ? IconButton(icon: const Icon(Icons.clear), onPressed: () => taskProvider.setDomainFilter(''))
                        : null,
                    contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                    filled: true,
                    fillColor: theme.brightness == Brightness.light ? Colors.grey.shade100 : Colors.grey.shade800,
                  ),
                  onChanged: taskProvider.setDomainFilter,
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.filter_list),
                onPressed: () => _showFilterDialog(context),
                style: IconButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
                  foregroundColor: theme.colorScheme.primary,
                ),
              ),
            ],
          ),
          if (taskProvider.domainFilter.isNotEmpty ||
              taskProvider.effortFilter.start > 0 ||
              taskProvider.effortFilter.end < 80) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (taskProvider.domainFilter.isNotEmpty)
                  _FilterChip(
                    label: 'Domain: ${taskProvider.domainFilter}',
                    onRemove: () => taskProvider.setDomainFilter(''),
                  ),
                if (taskProvider.effortFilter.start > 0 || taskProvider.effortFilter.end < 80)
                  _FilterChip(
                    label:
                        'Effort: ${taskProvider.effortFilter.start.toInt()}-${taskProvider.effortFilter.end.toInt()} hrs',
                    onRemove: () => taskProvider.setEffortFilter(const RangeValues(0, 80)),
                  ),
                TextButton.icon(
                  onPressed: () => taskProvider.clearFilters(),
                  icon: const Icon(Icons.clear_all, size: 16),
                  label: const Text('Clear All'),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    visualDensity: VisualDensity.compact,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  void _showFilterDialog(BuildContext context) {
    final taskProvider = Provider.of<TaskProvider>(context, listen: false);
    RangeValues effortRange = taskProvider.effortFilter;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('Filter Tasks'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Effort Hours'),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [Text('${effortRange.start.toInt()}h'), Text('${effortRange.end.toInt()}h')],
                ),
                RangeSlider(
                  values: effortRange,
                  min: 0,
                  max: 80,
                  divisions: 16,
                  onChanged: (values) {
                    setState(() {
                      effortRange = values;
                    });
                  },
                ),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
              FilledButton(
                onPressed: () {
                  taskProvider.setEffortFilter(effortRange);
                  Navigator.pop(context);
                },
                child: const Text('Apply'),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final VoidCallback onRemove;

  const _FilterChip({required this.label, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text(label, style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onPrimary)),
      backgroundColor: Theme.of(context).colorScheme.primary,
      deleteIcon: const Icon(Icons.close, size: 16, color: Colors.white),
      onDeleted: onRemove,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      visualDensity: VisualDensity.compact,
    );
  }
}
