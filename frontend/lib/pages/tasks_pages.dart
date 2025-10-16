import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../models/task_model.dart';
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
    final filteredTasks = taskProvider.filteredActiveTasks;

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
                    final expired = taskProvider.filteredExpiredTasks;
                    return ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        // Active tasks
                        ...filteredTasks.map(
                          (task) => TaskCard(
                            task: task,
                            onTap: () => Navigator.pushNamed(context, '/tasks/detail', arguments: task.taskId),
                          ),
                        ),
                        const SizedBox(height: 12),
                        if (expired.isNotEmpty) _ExpiredSection(tasks: expired),
                      ],
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
    final filteredTasks = taskProvider.filteredActiveTasks;
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
                    final expired = taskProvider.filteredExpiredTasks;
                    return ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        // Active tasks first
                        ...filteredTasks.map(
                          (task) => TaskCard(
                            task: task,
                            showCompanyActions: isCompany,
                            onTap: () => Navigator.pushNamed(context, '/tasks/detail', arguments: task.taskId),
                          ),
                        ),
                        const SizedBox(height: 12),
                        if (expired.isNotEmpty) _ExpiredSection(tasks: expired),
                      ],
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

class _ExpiredSection extends StatefulWidget {
  const _ExpiredSection({required this.tasks});
  final List<TaskModel> tasks;

  @override
  State<_ExpiredSection> createState() => _ExpiredSectionState();
}

class _ExpiredSectionState extends State<_ExpiredSection> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.history_toggle_off),
          title: Text('Expired (${widget.tasks.length})'),
          trailing: Icon(_expanded ? Icons.expand_less : Icons.expand_more),
          onTap: () => setState(() => _expanded = !_expanded),
        ),
        AnimatedCrossFade(
          crossFadeState: _expanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
          duration: const Duration(milliseconds: 200),
          firstChild: const SizedBox.shrink(),
          secondChild: Column(
            children: widget.tasks
                .map(
                  (t) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: TaskCard(
                      task: t,
                      onTap: () => Navigator.pushNamed(context, '/tasks/detail', arguments: t.taskId),
                    ),
                  ),
                )
                .toList(),
          ),
        ),
      ],
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

    await submissionProvider.loadTaskSubmissions(taskId);
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
  final customDomainCtrl = TextEditingController();

  final List<String> selectedDomains = [];
  double effortValue = 2; // In hours initially
  DateTime? expiry;
  bool loading = false;
  bool showCustomDomainInput = false;

  // Grouped domain categories
  final Map<String, List<String>> domainCategories = {
    'Development': [
      'Web Development',
      'Mobile Development',
      'Backend Development',
      'Frontend Development',
      'Full Stack Development',
      'Game Development',
    ],
    'Design': ['UI/UX Design', 'Graphic Design', 'Product Design', 'Motion Graphics', 'Brand Design'],
    'Data & AI': ['Data Science', 'Machine Learning', 'Data Analysis', 'Artificial Intelligence', 'Deep Learning'],
    'Business': ['Marketing', 'Content Writing', 'Business Analysis', 'Project Management', 'Market Research'],
    'Other': ['DevOps', 'Cybersecurity', 'Cloud Computing', 'Blockchain', 'IoT'],
  };

  String _formatEffort() {
    return '${effortValue.toInt()} hour${effortValue.toInt() != 1 ? 's' : ''}';
  }

  void _showDomainPicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        expand: false,
        builder: (context, scrollController) => Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Select Domains',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  TextButton.icon(
                    onPressed: () {
                      setState(() => showCustomDomainInput = true);
                      Navigator.pop(context);
                    },
                    icon: const Icon(Icons.add_circle_outline, size: 20),
                    label: const Text('Custom'),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                controller: scrollController,
                itemCount: domainCategories.length,
                itemBuilder: (context, index) {
                  final category = domainCategories.keys.elementAt(index);
                  final domains = domainCategories[category]!;

                  return ExpansionTile(
                    title: Text(category, style: const TextStyle(fontWeight: FontWeight.bold)),
                    initiallyExpanded: index == 0,
                    children: domains.map((domain) {
                      final isSelected = selectedDomains.contains(domain);
                      return CheckboxListTile(
                        title: Text(domain),
                        value: isSelected,
                        onChanged: (checked) {
                          setState(() {
                            if (checked == true) {
                              selectedDomains.add(domain);
                            } else {
                              selectedDomains.remove(domain);
                            }
                          });
                        },
                      );
                    }).toList(),
                  );
                },
              ),
            ),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -2)),
                ],
              ),
              child: AppButton(
                text: 'Done (${selectedDomains.length} selected)',
                isFullWidth: true,
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final taskProvider = Provider.of<TaskProvider>(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Create New Task'), centerTitle: true, elevation: 0),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // Basic Information Section
            _buildSectionHeader('Basic Information', Icons.info_outline),
            const SizedBox(height: 16),
            _buildCard(
              child: Column(
                children: [
                  TextFormField(
                    controller: titleCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Task Title',
                      hintText: 'Enter a clear and concise title',
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) => (v == null || v.isEmpty) ? 'Title is required' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: descCtrl,
                    maxLines: 6,
                    decoration: const InputDecoration(
                      labelText: 'Description',
                      hintText: 'Provide detailed instructions and requirements for the task',
                      alignLabelWithHint: true,
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) => (v == null || v.isEmpty) ? 'Description is required' : null,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Domains Section
            _buildSectionHeader('Domains & Categories', Icons.category),
            const SizedBox(height: 16),
            _buildCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  InkWell(
                    onTap: _showDomainPicker,
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        border: Border.all(color: Theme.of(context).dividerColor),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.category, color: Theme.of(context).primaryColor),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              selectedDomains.isEmpty
                                  ? 'Select domains from list'
                                  : '${selectedDomains.length} domain${selectedDomains.length > 1 ? 's' : ''} selected',
                              style: TextStyle(
                                color: selectedDomains.isEmpty
                                    ? Theme.of(context).hintColor
                                    : Theme.of(context).textTheme.bodyLarge?.color,
                              ),
                            ),
                          ),
                          const Icon(Icons.arrow_forward_ios, size: 16),
                        ],
                      ),
                    ),
                  ),

                  if (selectedDomains.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: selectedDomains.map((domain) {
                        return Chip(
                          label: Text(domain),
                          deleteIcon: const Icon(Icons.close, size: 18),
                          onDeleted: () {
                            setState(() => selectedDomains.remove(domain));
                          },
                        );
                      }).toList(),
                    ),
                  ],

                  const SizedBox(height: 16),

                  // Custom domain input
                  AnimatedCrossFade(
                    duration: const Duration(milliseconds: 300),
                    crossFadeState: showCustomDomainInput ? CrossFadeState.showSecond : CrossFadeState.showFirst,
                    firstChild: OutlinedButton.icon(
                      onPressed: () => setState(() => showCustomDomainInput = true),
                      icon: const Icon(Icons.add),
                      label: const Text('Add Custom Domain'),
                      style: OutlinedButton.styleFrom(minimumSize: const Size(double.infinity, 48)),
                    ),
                    secondChild: Column(
                      children: [
                        TextField(
                          controller: customDomainCtrl,
                          decoration: InputDecoration(
                            labelText: 'Custom Domain',
                            hintText: 'Enter a custom domain name',
                            prefixIcon: const Icon(Icons.edit),
                            border: const OutlineInputBorder(),
                            suffixIcon: IconButton(
                              icon: const Icon(Icons.add_circle),
                              onPressed: () {
                                if (customDomainCtrl.text.trim().isNotEmpty) {
                                  setState(() {
                                    selectedDomains.add(customDomainCtrl.text.trim());
                                    customDomainCtrl.clear();
                                    showCustomDomainInput = false;
                                  });
                                }
                              },
                            ),
                          ),
                          onSubmitted: (value) {
                            if (value.trim().isNotEmpty) {
                              setState(() {
                                selectedDomains.add(value.trim());
                                customDomainCtrl.clear();
                                showCustomDomainInput = false;
                              });
                            }
                          },
                        ),
                        const SizedBox(height: 8),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () {
                              setState(() => showCustomDomainInput = false);
                              customDomainCtrl.clear();
                            },
                            child: const Text('Cancel'),
                          ),
                        ),
                      ],
                    ),
                  ),

                  if (selectedDomains.isEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        'At least one domain is required',
                        style: TextStyle(color: Theme.of(context).colorScheme.error, fontSize: 12),
                      ),
                    ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Effort & Timeline Section
            _buildSectionHeader('Effort & Timeline', Icons.schedule),
            const SizedBox(height: 16),
            _buildCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Estimated Effort',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: Theme.of(context).primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          _formatEffort(),
                          style: TextStyle(
                            color: Theme.of(context).primaryColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Select estimated hours needed (0-24)',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).hintColor),
                  ),
                  Slider(
                    min: 0,
                    max: 24,
                    divisions: 24,
                    value: effortValue,
                    label: _formatEffort(),
                    onChanged: (v) => setState(() => effortValue = v),
                  ),

                  const Divider(height: 32),

                  // Expiry Date Picker
                  InkWell(
                    onTap: () async {
                      final now = DateTime.now();
                      final picked = await showDatePicker(
                        context: context,
                        firstDate: now,
                        lastDate: now.add(const Duration(days: 365)),
                        initialDate: expiry ?? now,
                      );
                      if (picked != null) setState(() => expiry = picked);
                    },
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        border: Border.all(color: Theme.of(context).dividerColor),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.calendar_today, color: Theme.of(context).primaryColor),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Deadline',
                                  style: Theme.of(
                                    context,
                                  ).textTheme.bodySmall?.copyWith(color: Theme.of(context).hintColor),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  expiry != null
                                      ? '${expiry!.day}/${expiry!.month}/${expiry!.year}'
                                      : 'No deadline set (optional)',
                                  style: Theme.of(context).textTheme.bodyLarge,
                                ),
                              ],
                            ),
                          ),
                          if (expiry != null)
                            IconButton(icon: const Icon(Icons.clear), onPressed: () => setState(() => expiry = null))
                          else
                            const Icon(Icons.arrow_forward_ios, size: 16),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 40),

            // Submit Button
            AppButton(
              text: 'Create Task',
              icon: Icons.check_circle,
              isLoading: loading,
              isFullWidth: true,
              onPressed: () => _submit(taskProvider),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Theme.of(context).primaryColor),
        const SizedBox(width: 8),
        Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: Theme.of(context).primaryColor),
        ),
      ],
    );
  }

  Widget _buildCard({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 2))],
      ),
      child: child,
    );
  }

  Future<void> _submit(TaskProvider taskProvider) async {
    if (!_formKey.currentState!.validate()) return;

    if (selectedDomains.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select at least one domain')));
      return;
    }

    setState(() => loading = true);

    try {
      final success = await taskProvider.createTask({
        'posted_by': widget.companyId,
        'title': titleCtrl.text.trim(),
        'description': descCtrl.text.trim(),
        'domains': selectedDomains,
        'effort_hours': effortValue.toInt(),
        'expiry_date': expiry?.toIso8601String(),
      });

      if (!mounted) return;

      if (success) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Task created successfully'), backgroundColor: Colors.green));
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed: ${taskProvider.errorMessage}'), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  void dispose() {
    titleCtrl.dispose();
    descCtrl.dispose();
    customDomainCtrl.dispose();
    super.dispose();
  }
}
