import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/task_model.dart';
import '../providers/auth_provider.dart';
import '../providers/task_provider.dart';
import '../widgets/common/app_button.dart';
import '../widgets/layout/app_scaffold.dart';
import '../widgets/tasks/task_card.dart';
import '../widgets/tasks/task_detail_header.dart';
import '../widgets/tasks/task_filter_bar.dart';

class TaskListPage extends StatefulWidget {
  const TaskListPage({super.key});

  @override
  State<TaskListPage> createState() => _TaskListPageState();
}

class _TaskListPageState extends State<TaskListPage> {
  @override
  void initState() {
    super.initState();
    // Load tasks if not already loaded
    final taskProvider = Provider.of<TaskProvider>(context, listen: false);
    if (taskProvider.status == TaskLoadStatus.initial) {
      taskProvider.loadTasks();
    }
  }

  @override
  Widget build(BuildContext context) {
    final taskProvider = Provider.of<TaskProvider>(context);
    final filteredTasks = taskProvider.filteredTasks;

    return AppScaffold(
      title: 'Tasks',
      currentIndex: 1,
      body: Column(
        children: [
          const TaskFilterBar(),

          Expanded(
            child: RefreshIndicator(
              onRefresh: () => taskProvider.loadTasks(),
              child: Builder(
                builder: (context) {
                  if (taskProvider.status == TaskLoadStatus.loading) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (filteredTasks.isEmpty) {
                    return _buildEmptyState();
                  } else {
                    return ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: filteredTasks.length,
                      itemBuilder: (context, index) {
                        final task = filteredTasks[index];
                        return TaskCard(
                          task: task,
                          onTap: () => Navigator.pushNamed(context, '/tasks/detail', arguments: task.taskId),
                        );
                      },
                    );
                  }
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search_off, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text('No tasks found', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(
              'Try adjusting your filters or check back later for new tasks',
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: Theme.of(context).textTheme.bodySmall?.color),
            ),
            const SizedBox(height: 24),
            AppButton(
              text: 'Clear Filters',
              onPressed: () => Provider.of<TaskProvider>(context, listen: false).clearFilters(),
              type: AppButtonType.secondary,
            ),
          ],
        ),
      ),
    );
  }
}

class TaskDetailPage extends StatefulWidget {
  const TaskDetailPage({super.key, required this.taskId});
  final dynamic taskId;

  @override
  State<TaskDetailPage> createState() => _TaskDetailPageState();
}

class _TaskDetailPageState extends State<TaskDetailPage> {
  @override
  void initState() {
    super.initState();
    _loadTaskDetails();
  }

  Future<void> _loadTaskDetails() async {
    final taskProvider = Provider.of<TaskProvider>(context, listen: false);
    await taskProvider.loadTaskDetails(widget.taskId.toString());
  }

  @override
  Widget build(BuildContext context) {
    final taskProvider = Provider.of<TaskProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final task = taskProvider.selectedTask;
    final isStudent = authProvider.currentUser?.role == 'student';

    return AppScaffold(
      title: 'Task Details',
      showBottomNav: false,
      body: RefreshIndicator(
        onRefresh: _loadTaskDetails,
        child: taskProvider.status == TaskLoadStatus.loading
            ? const Center(child: CircularProgressIndicator())
            : task == null
            ? Center(child: Text('Task not found'))
            : SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TaskDetailHeader(task: task),
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Description',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          Text(task.description, style: Theme.of(context).textTheme.bodyLarge),
                          const SizedBox(height: 32),
                          if (isStudent)
                            AppButton(
                              text: 'Submit Solution',
                              icon: Icons.upload_file,
                              isFullWidth: true,
                              onPressed: () =>
                                  Navigator.pushNamed(context, '/submissions/create', arguments: task.taskId),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}

class CreateTaskPage extends StatefulWidget {
  const CreateTaskPage({super.key, required this.companyId});
  final dynamic companyId;

  @override
  State<CreateTaskPage> createState() => _CreateTaskPageState();
}

class _CreateTaskPageState extends State<CreateTaskPage> {
  final _formKey = GlobalKey<FormState>();
  final titleCtrl = TextEditingController();
  final descCtrl = TextEditingController();
  final domainsCtrl = TextEditingController();
  double effort = 2;
  DateTime? expiry;
  bool loading = false;

  @override
  Widget build(BuildContext context) {
    final taskProvider = Provider.of<TaskProvider>(context);

    return AppScaffold(
      title: 'Create Task',
      showBottomNav: false,
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: titleCtrl,
              decoration: const InputDecoration(
                labelText: 'Title',
                hintText: 'Enter a descriptive title',
                prefixIcon: Icon(Icons.title),
              ),
              validator: (v) => (v == null || v.isEmpty) ? 'Title is required' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: descCtrl,
              maxLines: 5,
              decoration: const InputDecoration(
                labelText: 'Description',
                hintText: 'Provide detailed instructions for the task',
                alignLabelWithHint: true,
                prefixIcon: Icon(Icons.description),
              ),
              validator: (v) => (v == null || v.isEmpty) ? 'Description is required' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: domainsCtrl,
              decoration: const InputDecoration(
                labelText: 'Domains (comma separated)',
                hintText: 'e.g. Web Development, UI/UX, Mobile',
                prefixIcon: Icon(Icons.category),
              ),
              validator: (v) => (v == null || v.isEmpty) ? 'At least one domain is required' : null,
            ),
            const SizedBox(height: 24),
            Text('Effort Hours: ${effort.toInt()}', style: Theme.of(context).textTheme.titleMedium),
            Slider(
              min: 1,
              max: 80,
              divisions: 79,
              value: effort,
              label: '${effort.toInt()} hours',
              onChanged: (v) => setState(() => effort = v),
            ),
            const SizedBox(height: 16),
            InkWell(
              onTap: () async {
                final now = DateTime.now();
                final picked = await showDatePicker(
                  context: context,
                  firstDate: now,
                  lastDate: now.add(const Duration(days: 365)),
                  initialDate: now,
                );
                if (picked != null) setState(() => expiry = picked);
              },
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                decoration: BoxDecoration(
                  color: Theme.of(context).inputDecorationTheme.fillColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Expiry Date',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.onBackground.withOpacity(0.6),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            expiry != null
                                ? '${expiry!.day}/${expiry!.month}/${expiry!.year}'
                                : 'No deadline (optional)',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                    if (expiry != null)
                      IconButton(icon: const Icon(Icons.clear), onPressed: () => setState(() => expiry = null)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),
            AppButton(
              text: 'Create Task',
              isLoading: loading,
              isFullWidth: true,
              onPressed: () => _submit(taskProvider),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submit(TaskProvider taskProvider) async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => loading = true);

    try {
      final success = await taskProvider.createTask({
        'posted_by': widget.companyId,
        'title': titleCtrl.text.trim(),
        'description': descCtrl.text.trim(),
        'domains': domainsCtrl.text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList(),
        'effort_hours': effort.toInt(),
        'expiry_date': expiry?.toIso8601String(),
      });

      if (!mounted) return;

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Task created successfully')));
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: ${taskProvider.errorMessage}')));
      }
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }
}
