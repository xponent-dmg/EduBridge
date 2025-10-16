import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/task_model.dart';
import '../providers/auth_provider.dart';
import '../providers/portfolio_provider.dart';
import '../providers/submission_provider.dart';
import '../providers/task_provider.dart';
import '../providers/user_provider.dart';
import '../theme/app_theme.dart';
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
    // Defer provider-triggered loads to avoid setState during build
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
  }

  Future<void> _loadData() async {
    final taskProvider = Provider.of<TaskProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final submissionProvider = Provider.of<SubmissionProvider>(context, listen: false);
    final portfolioProvider = Provider.of<PortfolioProvider>(context, listen: false);

    // Load tasks
    await taskProvider.loadTasks();

    // Load role-specific data so dashboard counts are accurate
    final user = authProvider.currentUser;
    if (user != null) {
      if (user.role == 'student') {
        // Student: load own submissions and portfolio entries
        await Future.wait([
          submissionProvider.loadUserSubmissions(user.userId),
          portfolioProvider.loadPortfolio(user.userId),
        ]);
      } else if (user.role == 'company') {
        // Company: aggregate submissions across posted tasks
        await submissionProvider.loadCompanySubmissions(user.userId);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
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
            WelcomeHeader(
              name: user?.name ?? 'Guest',
              role: role,
              onProfileTap: role == 'student'
                  ? () => Navigator.pushNamed(context, '/profile', arguments: user?.userId)
                  : null,
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
    final tasks = taskProvider.filteredActiveTasks;
    final submissionProvider = Provider.of<SubmissionProvider>(context);
    final portfolioProvider = Provider.of<PortfolioProvider>(context);

    // Calculate quick stats
    final totalSubmissions = submissionProvider.submissions.length;
    final pendingSubmissions = submissionProvider.submissions.where((s) => s.grade == null).length;
    final approvedSubmissions = submissionProvider.submissions.where((s) => s.grade != null && s.grade! >= 60).length;

    // Build a map of taskId -> submission for quick lookup
    final Map<String, dynamic> taskSubmissionMap = {};
    for (final submission in submissionProvider.submissions) {
      taskSubmissionMap[submission.taskId] = {
        'hasSubmission': true,
        'isPending': submission.grade == null,
        'grade': submission.grade,
      };
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Quick Stats Cards
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(
            'Your Progress',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
        ),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Expanded(
                child: StatsCard(
                  title: 'Submissions',
                  value: totalSubmissions.toString(),
                  icon: Icons.upload_file,
                  color: AppTheme.primaryColor,
                  onTap: () => Navigator.pushNamed(context, '/submissions'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: StatsCard(
                  title: 'Pending',
                  value: pendingSubmissions.toString(),
                  icon: Icons.hourglass_empty,
                  color: AppTheme.warning,
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
                  title: 'Approved',
                  value: approvedSubmissions.toString(),
                  icon: Icons.check_circle,
                  color: AppTheme.success,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: StatsCard(
                  title: 'Portfolio',
                  value: portfolioProvider.entries.length.toString(),
                  icon: Icons.work_outline,
                  color: AppTheme.accentColor,
                  onTap: () => Navigator.pushNamed(context, '/portfolio'),
                ),
              ),
            ],
          ),
        ),

        // // EduPoints Card
        // if (edupointsProvider.status == EdupointsLoadStatus.loaded && edupointsProvider.edupoints != null) ...[
        //   const SizedBox(height: 24),
        //   Padding(
        //     padding: const EdgeInsets.symmetric(horizontal: 16),
        //     child: EdupointsCard(
        //       balance: edupointsProvider.balance,
        //       transactions: edupointsProvider.transactions.take(3).toList(),
        //     ),
        //   ),
        // ],

        // Available Tasks Section
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
            child: Center(child: Text('No active tasks available at the moment')),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: tasks.length > 3 ? 3 : tasks.length, // Show fewer tasks to make room for stats
            itemBuilder: (context, index) {
              final task = TaskModel.fromJson(tasks[index].toJson());
              final submissionInfo = taskSubmissionMap[task.taskId];
              return TaskCard(
                task: task,
                hasSubmission: submissionInfo?['hasSubmission'],
                isPendingReview: submissionInfo?['isPending'],
                submissionGrade: submissionInfo?['grade'],
                onTap: () => Navigator.pushNamed(context, '/tasks/detail', arguments: task.taskId),
              );
            },
          ),
      ],
    );
  }

  Widget _buildCompanySection(BuildContext context, String? companyId) {
    final taskProvider = Provider.of<TaskProvider>(context);
    final submissionProvider = Provider.of<SubmissionProvider>(context);

    // Calculate stats
    final totalTasks = taskProvider.tasks.where((t) => t.postedBy == companyId).length;
    final totalSubmissions = submissionProvider.companySubmissions.length;
    final pendingReviews = submissionProvider.companySubmissions.where((s) => s.grade == null).length;
    final reviewedSubmissions = totalSubmissions - pendingReviews;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Stats Overview
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(
            'Dashboard Overview',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
        ),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Expanded(
                child: StatsCard(
                  title: 'Tasks Posted',
                  value: totalTasks.toString(),
                  icon: Icons.task_alt,
                  color: AppTheme.primaryColor,
                  onTap: () => Navigator.pushNamed(context, '/company/tasks', arguments: companyId),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: StatsCard(
                  title: 'Submissions',
                  value: totalSubmissions.toString(),
                  icon: Icons.upload_file,
                  color: AppTheme.secondaryColor,
                  // onTap: () => Navigator.pushNamed(context, '/submissions/review'),
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
                  title: 'Pending Review',
                  value: pendingReviews.toString(),
                  icon: Icons.pending_actions,
                  color: AppTheme.warning,
                  // onTap: () => Navigator.pushNamed(context, '/submissions/review'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: StatsCard(
                  title: 'Reviewed',
                  value: reviewedSubmissions.toString(),
                  icon: Icons.grading,
                  color: AppTheme.success,
                ),
              ),
            ],
          ),
        ),

        // Quick Actions
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
          child: Text(
            'Quick Actions',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
        ),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: AppTheme.primaryColor.withOpacity(0.1), shape: BoxShape.circle),
                      child: const Icon(Icons.add_task, color: AppTheme.primaryColor),
                    ),
                    title: const Text('Create New Task'),
                    subtitle: const Text('Post a new task for students'),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () => Navigator.pushNamed(context, '/tasks/create', arguments: companyId),
                  ),
                  // const Divider(),
                  // ListTile(
                  //   leading: Container(
                  //     padding: const EdgeInsets.all(8),
                  //     decoration: BoxDecoration(
                  //       color: AppTheme.secondaryColor.withOpacity(0.1),
                  //       shape: BoxShape.circle,
                  //     ),
                  //     child: const Icon(Icons.grading, color: AppTheme.secondaryColor),
                  //   ),
                  //   title: const Text('Review Submissions'),
                  //   subtitle: const Text('Grade and provide feedback'),
                  //   trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  //   onTap: () => Navigator.pushNamed(context, '/submissions/review'),
                  // ),
                  const Divider(),
                  ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: AppTheme.accentColor.withOpacity(0.1), shape: BoxShape.circle),
                      child: const Icon(Icons.list_alt, color: AppTheme.accentColor),
                    ),
                    title: const Text('Manage Tasks'),
                    subtitle: const Text('View and edit your tasks'),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () => Navigator.pushNamed(context, '/company/tasks', arguments: companyId),
                  ),
                ],
              ),
            ),
          ),
        ),

        // Recent Submissions
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Recent Submissions',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              TextButton(
                onPressed: () => Navigator.pushNamed(context, '/submissions/review'),
                child: const Text('View All'),
              ),
            ],
          ),
        ),

        if (submissionProvider.status == SubmissionLoadStatus.loading)
          const Center(child: CircularProgressIndicator())
        else if (submissionProvider.companySubmissions.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 24),
            child: Center(child: Text('No submissions to review yet')),
          )
        else
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: submissionProvider.companySubmissions.length > 3
                    ? 3
                    : submissionProvider.companySubmissions.length,
                separatorBuilder: (context, index) => const Divider(),
                itemBuilder: (context, index) {
                  final submission = submissionProvider.companySubmissions[index];
                  return ListTile(
                    title: Text('Submission #${submission.submissionId.substring(0, 8)}'),
                    subtitle: Text('Submitted: ${_formatDate(submission.submittedAt)}'),
                    trailing: submission.grade == null
                        ? const Chip(label: Text('Pending'), backgroundColor: Colors.amber)
                        : Chip(
                            label: Text('${submission.grade}%'),
                            backgroundColor: _getGradeColor(submission.grade!),
                            labelStyle: const TextStyle(color: Colors.white),
                          ),
                    onTap: () => Navigator.pushNamed(context, '/submissions/review', arguments: submission.taskId),
                  );
                },
              ),
            ),
          ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  Color _getGradeColor(int grade) {
    if (grade >= 80) {
      return Colors.green;
    } else if (grade >= 60) {
      return Colors.blue;
    } else if (grade >= 40) {
      return Colors.orange;
    } else {
      return Colors.red;
    }
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
