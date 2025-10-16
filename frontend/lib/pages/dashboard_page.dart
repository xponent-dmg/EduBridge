import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/task_model.dart';
import '../providers/auth_provider.dart';
import '../providers/edupoints_provider.dart';
import '../providers/task_provider.dart';
import '../providers/user_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/dashboard/edupoints_card.dart';
import '../widgets/dashboard/stats_card.dart';
import '../widgets/dashboard/task_card.dart';
import '../widgets/dashboard/welcome_header.dart';
import '../widgets/layout/app_scaffold.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key, this.legacyToken});
  final String? legacyToken;

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final taskProvider = Provider.of<TaskProvider>(context, listen: false);
    final edupointsProvider = Provider.of<EdupointsProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    // Load tasks
    taskProvider.loadTasks();

    // Load edupoints if we have a user
    if (authProvider.currentUser != null) {
      edupointsProvider.loadEdupoints(authProvider.currentUser!.userId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final edupointsProvider = Provider.of<EdupointsProvider>(context);
    final taskProvider = Provider.of<TaskProvider>(context);

    final user = authProvider.currentUser;
    final role = user?.role ?? 'student';

    return AppScaffold(
      title: 'Dashboard',
      showBackButton: false,
      currentIndex: 0,
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: ListView(
          padding: const EdgeInsets.only(bottom: 24),
          children: [
            WelcomeHeader(name: user?.name ?? 'Guest', role: role),

            // Edupoints Card
            if (edupointsProvider.status == EdupointsLoadStatus.loaded && edupointsProvider.edupoints != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: EdupointsCard(
                  balance: edupointsProvider.balance,
                  transactions: edupointsProvider.transactions.take(3).toList(),
                ),
              ),

            // Role-specific sections
            if (role == 'student') _buildStudentSection(taskProvider),
            if (role == 'company') _buildCompanySection(context, user?.userId),
            if (role == 'admin') _buildAdminSection(context),
          ],
        ),
      ),
    );
  }

  Widget _buildStudentSection(TaskProvider taskProvider) {
    final tasks = taskProvider.tasks;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Available Tasks',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              TextButton(onPressed: () => Navigator.pushNamed(context, '/tasks'), child: const Text('View All')),
            ],
          ),
        ),

        if (taskProvider.status == TaskLoadStatus.loading)
          const Center(child: CircularProgressIndicator())
        else if (tasks.isEmpty)
          const Padding(
            padding: EdgeInsets.all(24),
            child: Center(child: Text('No tasks available at the moment')),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: tasks.length > 5 ? 5 : tasks.length,
            itemBuilder: (context, index) {
              final task = TaskModel.fromJson(tasks[index].toJson());
              return TaskCard(
                task: task,
                onTap: () => Navigator.pushNamed(context, '/tasks/detail', arguments: task.taskId),
              );
            },
          ),
      ],
    );
  }

  Widget _buildCompanySection(BuildContext context, String? companyId) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
          child: Text(
            'Company Tools',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
        ),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Expanded(
                child: StatsCard(
                  title: 'Post Task',
                  value: 'Create',
                  icon: Icons.add_task,
                  color: AppTheme.primaryColor,
                  onTap: () => Navigator.pushNamed(context, '/tasks/create', arguments: companyId),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: StatsCard(
                  title: 'My Tasks',
                  value: 'View',
                  icon: Icons.list_alt,
                  color: AppTheme.secondaryColor,
                  onTap: () => Navigator.pushNamed(context, '/company/tasks', arguments: companyId),
                ),
              ),
            ],
          ),
        ),

        Padding(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
          child: Text(
            'Recent Submissions',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
        ),

        // Placeholder for submissions
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          child: Center(child: Text('No submissions to review yet')),
        ),
      ],
    );
  }

  Widget _buildAdminSection(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);

    // Load users if not already loaded
    if (userProvider.status == UserLoadStatus.initial) {
      userProvider.loadUsers();
    }

    final userCount = userProvider.users.length;
    final studentCount = userProvider.students.length;
    final companyCount = userProvider.companies.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
          child: Text(
            'Admin Dashboard',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
        ),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Expanded(
                child: StatsCard(
                  title: 'Total Users',
                  value: userCount.toString(),
                  icon: Icons.people,
                  color: AppTheme.primaryColor,
                  onTap: () => Navigator.pushNamed(context, '/users'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: StatsCard(
                  title: 'Students',
                  value: studentCount.toString(),
                  icon: Icons.school,
                  color: AppTheme.accentColor,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Expanded(
                child: StatsCard(
                  title: 'Companies',
                  value: companyCount.toString(),
                  icon: Icons.business,
                  color: AppTheme.secondaryColor,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: StatsCard(
                  title: 'Tasks',
                  value: Provider.of<TaskProvider>(context).tasks.length.toString(),
                  icon: Icons.task_alt,
                  color: Colors.amber.shade700,
                  onTap: () => Navigator.pushNamed(context, '/tasks'),
                ),
              ),
            ],
          ),
        ),

        Padding(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
          child: ElevatedButton.icon(
            onPressed: () => Navigator.pushNamed(context, '/admin'),
            icon: const Icon(Icons.admin_panel_settings),
            label: const Text('Open Admin Panel'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
              minimumSize: const Size(double.infinity, 0),
            ),
          ),
        ),
      ],
    );
  }
}
