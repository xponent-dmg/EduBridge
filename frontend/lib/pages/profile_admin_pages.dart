import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/user_model.dart';
import '../providers/auth_provider.dart';
import '../providers/edupoints_provider.dart';
import '../providers/portfolio_provider.dart';
import '../providers/submission_provider.dart';
import '../providers/task_provider.dart';
import '../services/api_client.dart';
import '../theme/app_theme.dart';
import '../widgets/common/app_button.dart';
import '../widgets/dashboard/edupoints_card.dart';
import '../widgets/layout/app_scaffold.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key, this.userId});

  final dynamic userId;

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final api = ApiClient();
  final skillsCtrl = TextEditingController();
  Map<String, dynamic>? user;
  UserModel? currentUser;
  bool loading = true;
  bool isEditing = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    setState(() => loading = true);
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final edupointsProvider = Provider.of<EdupointsProvider>(context, listen: false);
      final portfolioProvider = Provider.of<PortfolioProvider>(context, listen: false);
      final submissionProvider = Provider.of<SubmissionProvider>(context, listen: false);

      final targetUserId = widget.userId?.toString() ?? authProvider.currentUser?.userId;

      if (targetUserId != null) {
        final userRes = await api.get('/users/$targetUserId');
        user = userRes['data'] as Map<String, dynamic>?;
        currentUser = authProvider.currentUser;

        // Load provider data only once in initState if this is the user's own profile
        final isOwnProfile = targetUserId == authProvider.currentUser?.userId;
        if (isOwnProfile && authProvider.currentUser != null) {
          edupointsProvider.loadEdupoints(targetUserId);
          portfolioProvider.loadPortfolio(targetUserId);
          submissionProvider.loadUserSubmissions(targetUserId);
        }
      }
    } catch (e) {
      // ignore: avoid_print
      print('Failed to load user data: $e');
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> _saveSkills() async {
    final skills = skillsCtrl.text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
    final userId = user?['user_id'];

    if (userId != null) {
      await api.patch('/users/$userId/skills', body: {'skills': skills});
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Skills updated')));
      setState(() {
        user?['skills'] = skills;
        isEditing = false;
      });
    }
  }

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.error.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.logout, color: AppTheme.error, size: 24),
            ),
            const SizedBox(width: 12),
            const Text('Sign Out'),
          ],
        ),
        content: const Text(
          'Are you sure you want to sign out?\n\nYou will need to log in again to access your account.',
          style: TextStyle(fontSize: 15),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.error,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      await authProvider.signOut();
      if (!mounted) return;
      Navigator.pushNamedAndRemoveUntil(context, '/auth', (_) => false);
    }
  }

  @override
  void dispose() {
    skillsCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final edupointsProvider = Provider.of<EdupointsProvider>(context);
    final portfolioProvider = Provider.of<PortfolioProvider>(context);
    final submissionProvider = Provider.of<SubmissionProvider>(context);

    final isOwnProfile = widget.userId?.toString() == authProvider.currentUser?.userId;
    final role = user?['role'] ?? authProvider.currentUser?.role ?? 'student';

    return AppScaffold(
      title: isOwnProfile ? 'My Profile' : 'Profile',
      showBottomNav: false,
      showBackButton: true,
      body: RefreshIndicator(
        onRefresh: _loadUserData,
        child: loading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Profile Header
                  _buildProfileHeader(),

                  const SizedBox(height: 24),

                  // Role-specific content
                  if (role == 'student') ...[
                    // Edupoints Card (for students only)
                    if (isOwnProfile &&
                        edupointsProvider.status == EdupointsLoadStatus.loaded &&
                        edupointsProvider.edupoints != null)
                      EdupointsCard(
                        balance: edupointsProvider.balance,
                        transactions: edupointsProvider.transactions.take(3).toList(),
                      ),

                    const SizedBox(height: 24),

                    // Student Statistics
                    _buildStudentStats(portfolioProvider, submissionProvider),

                    const SizedBox(height: 24),

                    // Skills Section (for students only)
                    _buildSkillsSection(),
                  ] else if (role == 'company') ...[
                    // Company Statistics
                    _buildCompanyStats(),

                    const SizedBox(height: 24),

                    // Company Description
                    _buildCompanyDescription(),
                  ],

                  const SizedBox(height: 24),

                  // Settings Section (for own profile only)
                  if (isOwnProfile) ...[_buildSettingsSection(), const SizedBox(height: 24)],

                  // Sign Out Button (at bottom, for own profile only)
                  if (isOwnProfile) _buildSignOutButton(),
                ],
              ),
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: AppTheme.primaryGradient,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          // Avatar
          CircleAvatar(
            radius: 40,
            backgroundColor: Colors.white,
            child: Text(
              user?['name']?.toString()[0].toUpperCase() ?? '?',
              style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: AppTheme.primaryColor),
            ),
          ),
          const SizedBox(height: 16),
          // Name and Role
          Text(
            user?['name'] ?? 'Unknown User',
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(12)),
            child: Text(
              _formatRole(user?['role'] ?? 'student'),
              style: const TextStyle(color: Colors.white, fontSize: 14),
            ),
          ),
          const SizedBox(height: 8),
          Text(user?['email'] ?? '', style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildStudentStats(PortfolioProvider portfolioProvider, SubmissionProvider submissionProvider) {
    final portfolioEntries = portfolioProvider.entries;
    final submissions = submissionProvider.submissions;
    final completedTasks = portfolioEntries.length;
    final totalSubmissions = submissions.length;
    final avgGrade = _calculateAverageGrade();

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Statistics', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _StatItem(
                    title: 'Tasks Completed',
                    value: completedTasks.toString(),
                    icon: Icons.task_alt,
                    color: AppTheme.primaryColor,
                  ),
                ),
                Expanded(
                  child: _StatItem(
                    title: 'Submissions',
                    value: totalSubmissions.toString(),
                    icon: Icons.upload_file,
                    color: AppTheme.secondaryColor,
                  ),
                ),
                Expanded(
                  child: _StatItem(
                    title: 'Avg. Grade',
                    value: avgGrade != null ? '$avgGrade%' : 'N/A',
                    icon: Icons.grade,
                    color: AppTheme.accentColor,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompanyStats() {
    final taskProvider = Provider.of<TaskProvider>(context);
    final submissionProvider = Provider.of<SubmissionProvider>(context);

    // Calculate company stats
    final tasksPosted = taskProvider.tasks.where((t) => t.postedBy == user?['user_id']).length;
    final submissionsReceived = submissionProvider.submissions.length;
    final pendingReviews = submissionProvider.submissions.where((s) => s.grade == null).length;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Company Statistics',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _StatItem(
                    title: 'Tasks Posted',
                    value: tasksPosted.toString(),
                    icon: Icons.post_add,
                    color: AppTheme.primaryColor,
                  ),
                ),
                Expanded(
                  child: _StatItem(
                    title: 'Submissions',
                    value: submissionsReceived.toString(),
                    icon: Icons.assignment_turned_in,
                    color: AppTheme.secondaryColor,
                  ),
                ),
                Expanded(
                  child: _StatItem(
                    title: 'Pending Review',
                    value: pendingReviews.toString(),
                    icon: Icons.pending_actions,
                    color: AppTheme.warning,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompanyDescription() {
    final description = user?['description'] as String? ?? 'No company description available.';
    final isOwnProfile = widget.userId?.toString() == Provider.of<AuthProvider>(context).currentUser?.userId;
    final descriptionCtrl = TextEditingController(text: description);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'About Company',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                if (isOwnProfile)
                  IconButton(
                    onPressed: () => setState(() => isEditing = !isEditing),
                    icon: Icon(isEditing ? Icons.close : Icons.edit),
                    tooltip: isEditing ? 'Cancel editing' : 'Edit description',
                  ),
              ],
            ),
            const SizedBox(height: 16),
            if (isEditing && isOwnProfile)
              Column(
                children: [
                  TextField(
                    controller: descriptionCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Company Description',
                      hintText: 'Tell students about your company...',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 5,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: AppButton(
                          text: 'Save',
                          onPressed: () async {
                            // Save company description
                            final userId = user?['user_id'];
                            if (userId != null) {
                              await api.patch('/users/$userId', body: {'description': descriptionCtrl.text});
                              if (!mounted) return;
                              ScaffoldMessenger.of(
                                context,
                              ).showSnackBar(const SnackBar(content: Text('Company description updated')));
                              setState(() {
                                user?['description'] = descriptionCtrl.text;
                                isEditing = false;
                              });
                            }
                          },
                          type: AppButtonType.primary,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: AppButton(
                          text: 'Cancel',
                          onPressed: () => setState(() => isEditing = false),
                          type: AppButtonType.secondary,
                        ),
                      ),
                    ],
                  ),
                ],
              )
            else
              Text(description, style: Theme.of(context).textTheme.bodyMedium),
          ],
        ),
      ),
    );
  }

  Widget _buildSkillsSection() {
    final skills = user?['skills'] as List<dynamic>? ?? [];

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Skills', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                if (widget.userId?.toString() == Provider.of<AuthProvider>(context).currentUser?.userId)
                  IconButton(
                    onPressed: () => setState(() => isEditing = !isEditing),
                    icon: Icon(isEditing ? Icons.close : Icons.edit),
                    tooltip: isEditing ? 'Cancel editing' : 'Edit skills',
                  ),
              ],
            ),
            const SizedBox(height: 16),
            if (isEditing)
              Column(
                children: [
                  TextField(
                    controller: skillsCtrl..text = skills.join(', '),
                    decoration: const InputDecoration(
                      labelText: 'Skills (comma separated)',
                      hintText: 'e.g. Flutter, React, Python',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: AppButton(text: 'Save', onPressed: _saveSkills, type: AppButtonType.primary),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: AppButton(
                          text: 'Cancel',
                          onPressed: () => setState(() => isEditing = false),
                          type: AppButtonType.secondary,
                        ),
                      ),
                    ],
                  ),
                ],
              )
            else if (skills.isEmpty)
              Text('No skills added yet', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey))
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: skills.map((skill) {
                  return Chip(
                    label: Text(skill.toString()),
                    backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                    labelStyle: TextStyle(color: AppTheme.primaryColor),
                  );
                }).toList(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Settings', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Push Notifications'),
              subtitle: const Text('Receive notifications about tasks and submissions'),
              value: true, // This would be connected to a provider in a real implementation
              onChanged: (value) {
                // Implement notification toggle functionality
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text('Notifications ${value ? 'enabled' : 'disabled'}')));
              },
              secondary: const Icon(Icons.notifications_outlined),
            ),
            const Divider(),
            SwitchListTile(
              title: const Text('Dark Mode'),
              subtitle: const Text('Switch between light and dark theme'),
              value: false, // This would be connected to a theme provider
              onChanged: (value) {
                // Implement theme toggle functionality
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text('Dark mode ${value ? 'enabled' : 'disabled'}')));
              },
              secondary: const Icon(Icons.dark_mode_outlined),
            ),
            const Divider(),
            SwitchListTile(
              title: const Text('Email Notifications'),
              subtitle: const Text('Receive email updates about your account'),
              value: true, // This would be connected to a provider
              onChanged: (value) {
                // Implement email notification toggle functionality
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text('Email notifications ${value ? 'enabled' : 'disabled'}')));
              },
              secondary: const Icon(Icons.email_outlined),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSignOutButton() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ElevatedButton.icon(
        icon: const Icon(Icons.logout, color: Colors.white),
        label: const Text('Sign Out', style: TextStyle(color: Colors.white)),
        onPressed: _logout,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.error,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          minimumSize: const Size(double.infinity, 56),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    );
  }

  // User info section removed as requested

  Widget _StatItem({required String title, required String value, required IconData icon, required Color color}) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold, color: color),
        ),
        const SizedBox(height: 4),
        Text(title, style: Theme.of(context).textTheme.bodySmall, textAlign: TextAlign.center),
      ],
    );
  }

  String _formatRole(String role) {
    return role[0].toUpperCase() + role.substring(1);
  }

  // Removed unused _formatDate method

  double? _calculateAverageGrade() {
    final portfolioProvider = Provider.of<PortfolioProvider>(context);
    final entries = portfolioProvider.entries;
    final gradedEntries = entries.where((e) => e.submission.grade != null).toList();

    if (gradedEntries.isEmpty) return null;

    final sum = gradedEntries.fold<int>(0, (sum, entry) => sum + (entry.submission.grade ?? 0));
    return (sum / gradedEntries.length).roundToDouble();
  }
}

class AdminPage extends StatefulWidget {
  const AdminPage({super.key});

  @override
  State<AdminPage> createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> {
  final api = ApiClient();
  List users = [];
  List tasks = [];
  List submissions = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final resUsers = await api.get('/users');
      users = (resUsers['data'] as List?) ?? [];
      final resTasks = await api.get('/tasks');
      tasks = (resTasks['data'] as List?) ?? [];
      // Minimal: show counts only; submissions listing would need extra endpoint
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Admin')),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Wrap(
                spacing: 16,
                runSpacing: 16,
                children: [
                  _StatCard(title: 'Users', value: users.length.toString()),
                  _StatCard(title: 'Tasks', value: tasks.length.toString()),
                  _StatCard(title: 'Submissions', value: '—'),
                ],
              ),
            ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.title, required this.value});
  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: SizedBox(
        width: 220,
        height: 120,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(title),
              const SizedBox(height: 8),
              Text(value, style: Theme.of(context).textTheme.headlineMedium),
            ],
          ),
        ),
      ),
    );
  }
}
