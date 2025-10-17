import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/submission_model.dart';
import '../../models/task_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/submission_provider.dart';
import '../../providers/task_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common/app_button.dart';
import '../../widgets/layout/app_scaffold.dart';

class CreateSubmissionPage extends StatefulWidget {
  const CreateSubmissionPage({super.key, required this.taskId});
  final dynamic taskId;

  @override
  State<CreateSubmissionPage> createState() => _CreateSubmissionPageState();
}

class _CreateSubmissionPageState extends State<CreateSubmissionPage> {
  PlatformFile? selectedFile;
  bool uploading = false;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    // Load task details
    final taskProvider = Provider.of<TaskProvider>(context, listen: false);
    taskProvider.loadTaskDetails(widget.taskId.toString());
  }

  Future<void> _pickFile() async {
    final res = await FilePicker.platform.pickFiles();
    if (res != null && res.files.isNotEmpty) {
      setState(() {
        selectedFile = res.files.first;
        errorMessage = null;
      });
    }
  }

  Future<void> _upload() async {
    if (selectedFile == null) {
      setState(() {
        errorMessage = "Please select a file first";
      });
      return;
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userId = authProvider.currentUser?.userId;

    if (userId == null) {
      setState(() {
        errorMessage = "User not authenticated";
      });
      return;
    }

    final submissionProvider = Provider.of<SubmissionProvider>(context, listen: false);

    try {
      setState(() => uploading = true);

      final success = await submissionProvider.uploadSubmission(
        taskId: widget.taskId.toString(),
        fileBytes: selectedFile!.bytes?.toList(),
        filePath: selectedFile!.path,
        fileName: selectedFile!.name,
      );

      if (!mounted) return;

      if (success) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Submission uploaded successfully')));
      } else {
        setState(() {
          errorMessage = submissionProvider.errorMessage ?? "Upload failed";
          uploading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          errorMessage = e.toString();
          uploading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final taskProvider = Provider.of<TaskProvider>(context);
    final task = taskProvider.selectedTask;

    return AppScaffold(
      title: 'Submit Solution',
      showBottomNav: false,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (task != null) ...[
              Card(
                margin: const EdgeInsets.only(bottom: 16),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Task: ${task.title}',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        task.description,
                        style: Theme.of(context).textTheme.bodyMedium,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),
            ],

            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Upload Submission',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),

                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                selectedFile != null ? Icons.check_circle : Icons.upload_file,
                                color: selectedFile != null ? Theme.of(context).colorScheme.primary : Colors.grey,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      selectedFile?.name ?? 'No file selected',
                                      style: Theme.of(context).textTheme.bodyLarge,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    if (selectedFile != null)
                                      Text(
                                        '${(selectedFile!.size / 1024).toStringAsFixed(2)} KB',
                                        style: Theme.of(context).textTheme.bodySmall,
                                      ),
                                  ],
                                ),
                              ),
                              TextButton.icon(
                                onPressed: _pickFile,
                                icon: const Icon(Icons.attach_file),
                                label: const Text('Choose File'),
                              ),
                            ],
                          ),
                          if (errorMessage != null) ...[
                            const SizedBox(height: 8),
                            Text(errorMessage!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
                          ],
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    AppButton(
                      text: uploading ? 'Uploading...' : 'Submit Solution',
                      isLoading: uploading,
                      isFullWidth: true,
                      onPressed: uploading ? null : _upload,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class MySubmissionsPage extends StatefulWidget {
  const MySubmissionsPage({super.key});

  @override
  State<MySubmissionsPage> createState() => _MySubmissionsPageState();
}

class _MySubmissionsPageState extends State<MySubmissionsPage> {
  @override
  void initState() {
    super.initState();
    _loadSubmissions();
  }

  Future<void> _loadSubmissions() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final submissionProvider = Provider.of<SubmissionProvider>(context, listen: false);

    if (authProvider.currentUser != null) {
      await submissionProvider.loadUserSubmissions(authProvider.currentUser!.userId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final submissionProvider = Provider.of<SubmissionProvider>(context);
    final submissions = submissionProvider.submissions;
    final gradedCount = submissions.where((s) => s.grade != null).length;
    final pendingCount = submissions.where((s) => s.grade == null).length;

    return AppScaffold(
      title: 'My Submissions',
      currentIndex: 2,
      customAppBar: AppBar(
        title: const Text('My Submissions'),
        centerTitle: true,
        elevation: 0,
        automaticallyImplyLeading: false,
        actions: [
          if (submissions.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${submissions.length} total',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          // Statistics Header
          if (submissions.isNotEmpty)
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Theme.of(context).colorScheme.primary,
                    Theme.of(context).colorScheme.primary.withOpacity(0.7),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _buildQuickStat(
                      icon: Icons.assignment_turned_in,
                      label: 'Graded',
                      value: gradedCount.toString(),
                    ),
                  ),
                  Container(width: 1, height: 40, color: Colors.white30),
                  Expanded(
                    child: _buildQuickStat(
                      icon: Icons.pending_actions,
                      label: 'Pending',
                      value: pendingCount.toString(),
                    ),
                  ),
                  Container(width: 1, height: 40, color: Colors.white30),
                  Expanded(
                    child: _buildQuickStat(
                      icon: Icons.analytics,
                      label: 'Avg Score',
                      value: gradedCount > 0
                          ? '${(submissions.where((s) => s.grade != null).fold<int>(0, (sum, s) => sum + s.grade!) / gradedCount).round()}%'
                          : '-',
                    ),
                  ),
                ],
              ),
            ),

          // Submissions List
          Expanded(
            child: RefreshIndicator(onRefresh: _loadSubmissions, child: _buildContent(submissionProvider)),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStat({required IconData icon, required String label, required String value}) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: Colors.white, size: 28),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
      ],
    );
  }

  Widget _buildContent(SubmissionProvider submissionProvider) {
    switch (submissionProvider.status) {
      case SubmissionLoadStatus.loading:
        return const Center(child: CircularProgressIndicator());

      case SubmissionLoadStatus.error:
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text('Failed to load submissions: ${submissionProvider.errorMessage}'),
              const SizedBox(height: 16),
              ElevatedButton(onPressed: _loadSubmissions, child: const Text('Try Again')),
            ],
          ),
        );

      case SubmissionLoadStatus.loaded:
        final submissions = submissionProvider.submissions;
        if (submissions.isEmpty) {
          return _buildEmptyState();
        }
        return _buildSubmissionsList(submissions);

      default:
        return const Center(child: CircularProgressIndicator());
    }
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.upload_file, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text('No Submissions Yet', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(
              'Complete tasks and submit your solutions to see them here',
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: Theme.of(context).textTheme.bodySmall?.color),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => Navigator.pushNamed(context, '/tasks'),
              icon: const Icon(Icons.search),
              label: const Text('Find Tasks'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubmissionsList(List<SubmissionModel> submissions) {
    // Sort submissions by date (newest first)
    final sortedSubmissions = [...submissions];
    sortedSubmissions.sort((a, b) => b.submittedAt.compareTo(a.submittedAt));

    final taskProvider = Provider.of<TaskProvider>(context);

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: sortedSubmissions.length,
      itemBuilder: (context, index) {
        final submission = sortedSubmissions[index];
        final hasGrade = submission.grade != null;
        final hasFeedback = submission.feedback != null && submission.feedback!.isNotEmpty;

        // Try to get task details if available
        final task = taskProvider.tasks.firstWhere(
          (t) => t.taskId == submission.taskId,
          orElse: () => TaskModel(
            taskId: submission.taskId,
            title: 'Task #${submission.taskId.substring(0, 6)}',
            description: '',
            domains: [],
            effortHours: 0,
            postedBy: '',
          ),
        );

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: hasGrade ? _getGradeColor(submission.grade!).withOpacity(0.1) : Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Card(
            margin: EdgeInsets.zero,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 0,
            child: Column(
              children: [
                InkWell(
                  onTap: () => _showSubmissionDetails(submission),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: hasGrade
                                    ? _getGradeColor(submission.grade!).withOpacity(0.15)
                                    : AppTheme.warning.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                hasGrade ? Icons.check_circle : Icons.hourglass_empty,
                                color: hasGrade ? _getGradeColor(submission.grade!) : AppTheme.warning,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    task.title,
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Icon(Icons.calendar_today, size: 13, color: Theme.of(context).hintColor),
                                      const SizedBox(width: 4),
                                      Flexible(
                                        child: Text(
                                          _formatDateShort(submission.submittedAt),
                                          style: TextStyle(color: Theme.of(context).hintColor, fontSize: 12),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              constraints: const BoxConstraints(minWidth: 70),
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: hasGrade ? _getGradeColor(submission.grade!) : AppTheme.warning,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                hasGrade ? '${submission.grade}%' : 'Pending',
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 12,
                          runSpacing: 8,
                          children: [
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  hasGrade ? Icons.grade : Icons.pending_actions,
                                  size: 14,
                                  color: Theme.of(context).hintColor,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  hasGrade ? _getGradeLabel(submission.grade!) : 'Under Review',
                                  style: TextStyle(
                                    color: hasGrade ? _getGradeColor(submission.grade!) : Theme.of(context).hintColor,
                                    fontWeight: hasGrade ? FontWeight.bold : FontWeight.normal,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                            if (hasFeedback)
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.comment, size: 14, color: Theme.of(context).colorScheme.primary),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Feedback',
                                    style: TextStyle(
                                      color: Theme.of(context).colorScheme.primary,
                                      fontWeight: FontWeight.w500,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                // Action buttons
                Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.background.withOpacity(0.5),
                    borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
                    border: Border(top: BorderSide(color: Theme.of(context).dividerColor.withOpacity(0.5))),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      OutlinedButton.icon(
                        onPressed: () => _showSubmissionDetails(submission),
                        icon: const Icon(Icons.visibility, size: 16),
                        label: const Text('Details'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          visualDensity: VisualDensity.compact,
                        ),
                      ),
                      if (hasGrade && submission.grade! >= 70) ...[
                        const SizedBox(width: 8),
                        FilledButton.icon(
                          onPressed: () {
                            // Add to portfolio logic would go here
                            ScaffoldMessenger.of(
                              context,
                            ).showSnackBar(const SnackBar(content: Text('Adding to portfolio coming soon')));
                          },
                          icon: const Icon(Icons.work, size: 16),
                          label: const Text('Portfolio'),
                          style: FilledButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            visualDensity: VisualDensity.compact,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _getGradeLabel(int grade) {
    if (grade >= 90) return 'Excellent';
    if (grade >= 80) return 'Great';
    if (grade >= 70) return 'Good';
    if (grade >= 60) return 'Satisfactory';
    if (grade >= 50) return 'Needs Work';
    return 'Poor';
  }

  void _showSubmissionDetails(SubmissionModel submission) {
    // Try to get task details
    final taskProvider = Provider.of<TaskProvider>(context, listen: false);
    final task = taskProvider.tasks.firstWhere(
      (t) => t.taskId == submission.taskId,
      orElse: () => TaskModel(
        taskId: submission.taskId,
        title: 'Task #${submission.taskId.substring(0, 6)}',
        description: '',
        domains: [],
        effortHours: 0,
        postedBy: '',
      ),
    );

    final hasGrade = submission.grade != null;
    final hasFeedback = submission.feedback != null && submission.feedback!.isNotEmpty;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        expand: false,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
                  ),
                ),
                const SizedBox(height: 20),

                // Header with grade
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Submission Details',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ),
                    if (hasGrade)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: _getGradeColor(submission.grade!),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          '${submission.grade}%',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      ),
                  ],
                ),

                const SizedBox(height: 8),
                Text(task.title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w500)),

                const SizedBox(height: 24),

                // Task info card
                Card(
                  margin: EdgeInsets.zero,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.info_outline, size: 20, color: Theme.of(context).colorScheme.primary),
                            const SizedBox(width: 8),
                            Text(
                              'Task Information',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        if (task.description.isNotEmpty) ...[
                          Text(
                            'Description:',
                            style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            task.description,
                            style: Theme.of(context).textTheme.bodyMedium,
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 12),
                        ],
                        if (task.domains.isNotEmpty) ...[
                          Text(
                            'Domains:',
                            style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary),
                          ),
                          const SizedBox(height: 4),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: task.domains.map((domain) {
                              return Chip(
                                label: Text(domain),
                                backgroundColor: Theme.of(context).colorScheme.secondary.withOpacity(0.1),
                                labelStyle: TextStyle(color: Theme.of(context).colorScheme.secondary),
                                visualDensity: VisualDensity.compact,
                                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              );
                            }).toList(),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Submission info
                Card(
                  margin: EdgeInsets.zero,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.upload_file, size: 20, color: Theme.of(context).colorScheme.primary),
                            const SizedBox(width: 8),
                            Text(
                              'Submission Information',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _buildDetailRow('Submitted On', _formatDate(submission.submittedAt)),
                        if (submission.fileUrl != null) ...[
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(child: _buildDetailRow('File', 'Attachment')),
                              TextButton.icon(
                                onPressed: () {
                                  // TODO: Implement file download/view
                                  ScaffoldMessenger.of(
                                    context,
                                  ).showSnackBar(const SnackBar(content: Text('File download coming soon')));
                                },
                                icon: const Icon(Icons.download, size: 16),
                                label: const Text('Download'),
                                style: TextButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(horizontal: 8),
                                  visualDensity: VisualDensity.compact,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ),

                // Feedback section if available
                if (hasGrade || hasFeedback) ...[
                  const SizedBox(height: 24),
                  Card(
                    margin: EdgeInsets.zero,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    color: hasGrade ? _getGradeColor(submission.grade!).withOpacity(0.05) : null,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.rate_review,
                                size: 20,
                                color: hasGrade
                                    ? _getGradeColor(submission.grade!)
                                    : Theme.of(context).colorScheme.primary,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Evaluation',
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          if (hasGrade) ...[
                            Row(
                              children: [
                                Text('Grade:', style: TextStyle(fontWeight: FontWeight.bold)),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: _getGradeColor(submission.grade!),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    '${submission.grade}%',
                                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  '(${_getGradeLabel(submission.grade!)})',
                                  style: TextStyle(
                                    color: _getGradeColor(submission.grade!),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ],
                          if (hasFeedback) ...[
                            const SizedBox(height: 16),
                            Text('Feedback:', style: TextStyle(fontWeight: FontWeight.bold)),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.background,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.grey.shade300),
                              ),
                              child: Text(submission.feedback!),
                            ),
                          ],
                          if (hasGrade && submission.grade! >= 70) ...[
                            const SizedBox(height: 16),
                            Center(
                              child: AppButton(
                                text: 'Add to Portfolio',
                                icon: Icons.work,
                                onPressed: () {
                                  // Add to portfolio logic would go here
                                  Navigator.pop(context);
                                  ScaffoldMessenger.of(
                                    context,
                                  ).showSnackBar(const SnackBar(content: Text('Adding to portfolio coming soon')));
                                },
                                type: AppButtonType.primary,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],

                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close'))],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  String _formatDateShort(DateTime date) {
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
}

class ReviewSubmissionsPage extends StatefulWidget {
  const ReviewSubmissionsPage({super.key, required this.taskId});
  final dynamic taskId;

  @override
  State<ReviewSubmissionsPage> createState() => _ReviewSubmissionsPageState();
}

class _ReviewSubmissionsPageState extends State<ReviewSubmissionsPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadSubmissions();
    });
  }

  Future<void> _loadSubmissions() async {
    final submissionProvider = Provider.of<SubmissionProvider>(context, listen: false);
    await submissionProvider.loadTaskSubmissions(widget.taskId.toString());
  }

  @override
  Widget build(BuildContext context) {
    final submissionProvider = Provider.of<SubmissionProvider>(context);
    final taskProvider = Provider.of<TaskProvider>(context);

    // Load task details if needed
    if (taskProvider.selectedTask == null || taskProvider.selectedTask?.taskId != widget.taskId.toString()) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        taskProvider.loadTaskDetails(widget.taskId.toString());
      });
    }

    final task = taskProvider.selectedTask;

    return Scaffold(
      appBar: AppBar(title: const Text('Review Submissions'), centerTitle: true, elevation: 0),
      body: Column(
        children: [
          // Enhanced Task Header
          if (task != null) _buildTaskHeader(task, submissionProvider),

          // Submissions list
          Expanded(
            child: RefreshIndicator(onRefresh: _loadSubmissions, child: _buildContent(submissionProvider)),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskHeader(TaskModel task, SubmissionProvider submissionProvider) {
    final submissions = submissionProvider.submissions;
    final totalSubmissions = submissions.length;
    final pendingCount = submissions.where((s) => s.grade == null).length;
    final gradedCount = submissions.where((s) => s.grade != null).length;
    final avgGrade = gradedCount > 0
        ? (submissions.where((s) => s.grade != null).fold<int>(0, (sum, s) => sum + s.grade!) / gradedCount).round()
        : 0;

    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Theme.of(context).colorScheme.primary, Theme.of(context).colorScheme.primary.withOpacity(0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Task Title and Status
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        task.title,
                        style: Theme.of(
                          context,
                        ).textTheme.titleLarge?.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.category, size: 16, color: Colors.white70),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              task.domains.join(', '),
                              style: const TextStyle(color: Colors.white70, fontSize: 13),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (task.expiryDate != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white.withOpacity(0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.calendar_today, size: 14, color: Colors.white),
                        const SizedBox(width: 6),
                        Text(
                          _formatDateShort(task.expiryDate!),
                          style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 20),

            // Statistics Cards
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    icon: Icons.assignment,
                    label: 'Total',
                    value: totalSubmissions.toString(),
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    icon: Icons.pending_actions,
                    label: 'Pending',
                    value: pendingCount.toString(),
                    color: Colors.amber,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    icon: Icons.check_circle,
                    label: 'Graded',
                    value: gradedCount.toString(),
                    color: Colors.green,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    icon: Icons.analytics,
                    label: 'Avg Grade',
                    value: gradedCount > 0 ? '$avgGrade%' : '-',
                    color: Colors.lightBlue,
                  ),
                ),
              ],
            ),

            if (task.description.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Divider(color: Colors.white24, height: 1),
              const SizedBox(height: 16),
              Text(
                task.description,
                style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.4),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard({required IconData icon, required String label, required String value, required Color color}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(color: color, fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(color: Colors.white70, fontSize: 11),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildContent(SubmissionProvider submissionProvider) {
    switch (submissionProvider.status) {
      case SubmissionLoadStatus.loading:
        return const Center(child: CircularProgressIndicator());

      case SubmissionLoadStatus.error:
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text('Failed to load submissions: ${submissionProvider.errorMessage}'),
              const SizedBox(height: 16),
              ElevatedButton(onPressed: _loadSubmissions, child: const Text('Try Again')),
            ],
          ),
        );

      case SubmissionLoadStatus.loaded:
        final submissions = submissionProvider.submissions;
        if (submissions.isEmpty) {
          return _buildEmptyState();
        }
        return _buildSubmissionsList(submissions);

      default:
        return const Center(child: CircularProgressIndicator());
    }
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.assignment_outlined, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text('No Submissions Yet', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            const Text('There are no submissions for this task yet', textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  Widget _buildSubmissionsList(List<SubmissionModel> submissions) {
    // Sort submissions: pending first, then by date
    final sortedSubmissions = [...submissions];
    sortedSubmissions.sort((a, b) {
      // First sort by grade status (null grades first)
      if (a.grade == null && b.grade != null) return -1;
      if (a.grade != null && b.grade == null) return 1;
      // Then sort by submission date (newest first)
      return b.submittedAt.compareTo(a.submittedAt);
    });

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: sortedSubmissions.length,
      itemBuilder: (context, index) {
        final submission = sortedSubmissions[index];
        final isPending = submission.grade == null;

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: isPending ? Colors.amber.withOpacity(0.15) : Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Card(
            margin: EdgeInsets.zero,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 0,
            child: Column(
              children: [
                InkWell(
                  onTap: () => _showGradeDialog(submission),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: isPending
                                    ? Colors.amber.withOpacity(0.15)
                                    : _getGradeColor(submission.grade!).withOpacity(0.15),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                isPending ? Icons.pending_actions : Icons.check_circle,
                                color: isPending ? Colors.amber.shade700 : _getGradeColor(submission.grade!),
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Submission #${submission.submissionId.substring(0, 8)}',
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Icon(Icons.calendar_today, size: 14, color: Theme.of(context).hintColor),
                                      const SizedBox(width: 4),
                                      Text(
                                        _formatDate(submission.submittedAt),
                                        style: TextStyle(color: Theme.of(context).hintColor, fontSize: 12),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: isPending ? Colors.amber : _getGradeColor(submission.grade!),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                isPending ? 'Review Needed' : '${submission.grade}%',
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                            ),
                          ],
                        ),
                        if (submission.fileUrl != null) ...[
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.primary.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Theme.of(context).colorScheme.primary.withOpacity(0.2)),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.attach_file, size: 18, color: Theme.of(context).colorScheme.primary),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'File attached',
                                    style: TextStyle(
                                      color: Theme.of(context).colorScheme.primary,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                                Icon(Icons.arrow_forward_ios, size: 14, color: Theme.of(context).colorScheme.primary),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),

                // Action buttons
                Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.background.withOpacity(0.5),
                    borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
                    border: Border(top: BorderSide(color: Theme.of(context).dividerColor.withOpacity(0.5))),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      if (submission.fileUrl != null) ...[
                        OutlinedButton.icon(
                          onPressed: () {
                            // TODO: Implement file download/view
                            ScaffoldMessenger.of(
                              context,
                            ).showSnackBar(const SnackBar(content: Text('File download coming soon')));
                          },
                          icon: const Icon(Icons.download, size: 18),
                          label: const Text('Download'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            visualDensity: VisualDensity.compact,
                          ),
                        ),
                        const SizedBox(width: 12),
                      ],
                      FilledButton.icon(
                        onPressed: () => _showGradeDialog(submission),
                        icon: Icon(isPending ? Icons.rate_review : Icons.edit, size: 18),
                        label: Text(isPending ? 'Grade Now' : 'Edit Grade'),
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          visualDensity: VisualDensity.compact,
                          backgroundColor: isPending ? Colors.amber.shade600 : null,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showGradeDialog(SubmissionModel submission) {
    final gradeController = TextEditingController(text: submission.grade?.toString() ?? '');
    final feedbackController = TextEditingController(text: submission.feedback ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Grade Submission'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: gradeController,
              decoration: const InputDecoration(labelText: 'Grade (0-100)'),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: feedbackController,
              decoration: const InputDecoration(labelText: 'Feedback'),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(
            onPressed: () =>
                _submitGrade(submission.submissionId, int.tryParse(gradeController.text) ?? 0, feedbackController.text),
            child: const Text('Submit'),
          ),
        ],
      ),
    );
  }

  Future<void> _submitGrade(String submissionId, int grade, String feedback) async {
    final submissionProvider = Provider.of<SubmissionProvider>(context, listen: false);

    Navigator.pop(context);

    final success = await submissionProvider.gradeSubmission(
      submissionId: submissionId,
      grade: grade,
      feedback: feedback,
    );

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Grade submitted successfully')));
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to submit grade: ${submissionProvider.errorMessage}')));
      }
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  String _formatDateShort(DateTime date) {
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
}
