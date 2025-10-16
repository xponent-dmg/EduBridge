import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../providers/submission_provider.dart';
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

class CompanyTasksPage extends StatefulWidget {
  const CompanyTasksPage({super.key, required this.companyId});
  final dynamic companyId;

  @override
  State<CompanyTasksPage> createState() => _CompanyTasksPageState();
}

class _CompanyTasksPageState extends State<CompanyTasksPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final taskProvider = Provider.of<TaskProvider>(context, listen: false);
      taskProvider.loadCompanyTasks(widget.companyId.toString());
    });
  }

  @override
  Widget build(BuildContext context) {
    final taskProvider = Provider.of<TaskProvider>(context);
    final filteredTasks = taskProvider.filteredTasks;

    return AppScaffold(
      title: 'Company Tasks',
      showBottomNav: false,
      body: Column(
        children: [
          const TaskFilterBar(),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => taskProvider.loadCompanyTasks(widget.companyId.toString()),
              child: Builder(
                builder: (context) {
                  if (taskProvider.status == TaskLoadStatus.loading) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (taskProvider.status == TaskLoadStatus.error) {
                    return _buildErrorState(taskProvider.errorMessage);
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
            Icon(Icons.folder_off, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text('No tasks for this company', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(
              'This company has not posted any tasks yet.',
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: Theme.of(context).textTheme.bodySmall?.color),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(String? message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.redAccent),
            const SizedBox(height: 16),
            Text('Failed to load tasks', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(
              message ?? 'Please try again later.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            AppButton(
              text: 'Retry',
              onPressed: () =>
                  Provider.of<TaskProvider>(context, listen: false).loadCompanyTasks(widget.companyId.toString()),
            ),
          ],
        ),
      ),
    );
  }
}

class _TaskListPageState extends State<TaskListPage> {
  @override
  void initState() {
    super.initState();
    // Load tasks after first frame to avoid notifyListeners during build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final taskProvider = Provider.of<TaskProvider>(context, listen: false);
      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      if (taskProvider.status == TaskLoadStatus.initial) {
        // Load appropriate tasks based on role
        if (authProvider.currentUser?.role == 'company') {
          taskProvider.loadCompanyTasks(authProvider.currentUser!.userId);
        } else {
          taskProvider.loadTasks();
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final taskProvider = Provider.of<TaskProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final filteredTasks = taskProvider.filteredTasks;
    final role = authProvider.currentUser?.role ?? 'student';
    final isCompany = role == 'company';

    return AppScaffold(
      title: isCompany ? 'Manage Tasks' : 'Available Tasks',
      currentIndex: 1,
      floatingActionButton: isCompany
          ? FloatingActionButton(
              onPressed: () =>
                  Navigator.pushNamed(context, '/tasks/create', arguments: authProvider.currentUser?.userId),
              child: const Icon(Icons.add),
              tooltip: 'Create New Task',
            )
          : null,
      body: Column(
        children: [
          const TaskFilterBar(),

          Expanded(
            child: RefreshIndicator(
              onRefresh: () => isCompany
                  ? taskProvider.loadCompanyTasks(authProvider.currentUser!.userId)
                  : taskProvider.loadTasks(),
              child: Builder(
                builder: (context) {
                  if (taskProvider.status == TaskLoadStatus.loading) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (filteredTasks.isEmpty) {
                    return _buildEmptyState(isCompany);
                  } else {
                    return ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: filteredTasks.length,
                      itemBuilder: (context, index) {
                        final task = filteredTasks[index];
                        return TaskCard(
                          task: task,
                          showCompanyActions: isCompany,
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

  Widget _buildEmptyState(bool isCompany) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(isCompany ? Icons.post_add : Icons.search_off, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(isCompany ? 'No tasks posted yet' : 'No tasks found', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(
              isCompany
                  ? 'Create your first task to start receiving submissions from students'
                  : 'Try adjusting your filters or check back later for new tasks',
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: Theme.of(context).textTheme.bodySmall?.color),
            ),
            const SizedBox(height: 24),
            AppButton(
              text: isCompany ? 'Create Task' : 'Clear Filters',
              icon: isCompany ? Icons.add : Icons.filter_alt_off,
              onPressed: () => isCompany
                  ? Navigator.pushNamed(
                      context,
                      '/tasks/create',
                      arguments: Provider.of<AuthProvider>(context, listen: false).currentUser?.userId,
                    )
                  : Provider.of<TaskProvider>(context, listen: false).clearFilters(),
              type: isCompany ? AppButtonType.primary : AppButtonType.secondary,
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
    final role = authProvider.currentUser?.role ?? 'student';
    final isStudent = role == 'student';
    final isCompany = role == 'company';
    final isTaskOwner = isCompany && task?.postedBy == authProvider.currentUser?.userId;

    return AppScaffold(
      title: 'Task Details',
      showBottomNav: false,
      currentIndex: 1, // Set Tasks as the current tab
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

                          // Role-specific actions
                          if (isStudent) ...[
                            // Check if student has already submitted a solution
                            FutureBuilder<bool>(
                              future: _hasSubmitted(task.taskId),
                              builder: (context, snapshot) {
                                final hasSubmitted = snapshot.data ?? false;

                                return hasSubmitted
                                    ? Column(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.all(16),
                                            decoration: BoxDecoration(
                                              color: Colors.green.withOpacity(0.1),
                                              borderRadius: BorderRadius.circular(8),
                                              border: Border.all(color: Colors.green.withOpacity(0.3)),
                                            ),
                                            child: Row(
                                              children: [
                                                const Icon(Icons.check_circle, color: Colors.green),
                                                const SizedBox(width: 12),
                                                Expanded(
                                                  child: Text(
                                                    'You have already submitted a solution for this task',
                                                    style: TextStyle(color: Colors.green),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(height: 16),
                                          AppButton(
                                            text: 'View Your Submission',
                                            icon: Icons.visibility,
                                            isFullWidth: true,
                                            onPressed: () => Navigator.pushNamed(context, '/submissions'),
                                          ),
                                        ],
                                      )
                                    : AppButton(
                                        text: 'Submit Solution',
                                        icon: Icons.upload_file,
                                        isFullWidth: true,
                                        onPressed: () =>
                                            Navigator.pushNamed(context, '/submissions/create', arguments: task.taskId),
                                      );
                              },
                            ),
                          ] else if (isTaskOwner) ...[
                            // Company actions for their own task
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: AppButton(
                                        text: 'Edit Task',
                                        icon: Icons.edit,
                                        type: AppButtonType.secondary,
                                        onPressed: () {
                                          // TODO: Implement task editing
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(const SnackBar(content: Text('Task editing coming soon')));
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 24),
                                // Show submissions section directly here
                                Text(
                                  'Submissions',
                                  style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 16),
                                AppButton(
                                  text: 'View All Submissions',
                                  icon: Icons.assignment_turned_in,
                                  isFullWidth: true,
                                  onPressed: () =>
                                      Navigator.pushNamed(context, '/submissions/review', arguments: task.taskId),
                                ),
                              ],
                            ),
                          ] else if (isCompany) ...[
                            // Other companies can't submit or edit
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.grey.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.grey.withOpacity(0.3)),
                              ),
                              child: const Text(
                                'This task was posted by another company. You can view details but cannot submit solutions or edit it.',
                                style: TextStyle(color: Colors.grey),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  Future<bool> _hasSubmitted(String taskId) async {
    final submissionProvider = Provider.of<SubmissionProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userId = authProvider.currentUser?.userId;

    if (userId == null) return false;

    // Check if submissions are already loaded
    await submissionProvider.loadUserSubmissions(userId);

    // Check if user has submitted for this task
    return submissionProvider.submissions.any((s) => s.taskId == taskId);
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
