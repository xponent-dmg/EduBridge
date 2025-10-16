import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/submission_model.dart';
import '../models/task_model.dart';
import '../providers/auth_provider.dart';
import '../providers/submission_provider.dart';
import '../providers/task_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/common/app_button.dart';
import '../widgets/layout/app_scaffold.dart';

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

    return AppScaffold(
      title: 'My Submissions',
      currentIndex: 2,
      body: RefreshIndicator(onRefresh: _loadSubmissions, child: _buildContent(submissionProvider)),
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

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Column(
            children: [
              ListTile(
                contentPadding: const EdgeInsets.all(16),
                leading: CircleAvatar(
                  backgroundColor: hasGrade ? _getGradeColor(submission.grade!) : AppTheme.warning,
                  child: Icon(hasGrade ? Icons.check_circle : Icons.hourglass_empty, color: Colors.white),
                ),
                title: Text(
                  task.title,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.calendar_today, size: 16, color: Theme.of(context).hintColor),
                        const SizedBox(width: 4),
                        Text(
                          'Submitted: ${_formatDate(submission.submittedAt)}',
                          style: TextStyle(color: Theme.of(context).hintColor),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          hasGrade ? Icons.grade : Icons.pending_actions,
                          size: 16,
                          color: Theme.of(context).hintColor,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          hasGrade ? 'Grade: ${submission.grade}%' : 'Status: Pending Review',
                          style: TextStyle(
                            color: hasGrade ? _getGradeColor(submission.grade!) : Theme.of(context).hintColor,
                            fontWeight: hasGrade ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                    if (hasFeedback) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.comment, size: 16, color: Theme.of(context).hintColor),
                          const SizedBox(width: 4),
                          Text('Feedback available', style: TextStyle(color: Theme.of(context).colorScheme.primary)),
                        ],
                      ),
                    ],
                  ],
                ),
                trailing: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: hasGrade ? _getGradeColor(submission.grade!).withOpacity(0.2) : Colors.grey.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    hasGrade ? _getGradeLabel(submission.grade!) : 'Pending',
                    style: TextStyle(
                      color: hasGrade ? _getGradeColor(submission.grade!) : Colors.grey,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                onTap: () => _showSubmissionDetails(submission),
              ),

              // Action buttons
              Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.background,
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(12),
                    bottomRight: Radius.circular(12),
                  ),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton.icon(
                      onPressed: () => _showSubmissionDetails(submission),
                      icon: const Icon(Icons.visibility, size: 16),
                      label: const Text('View Details'),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        visualDensity: VisualDensity.compact,
                      ),
                    ),
                    if (hasGrade && submission.grade! >= 70) ...[
                      const SizedBox(width: 8),
                      TextButton.icon(
                        onPressed: () {
                          // Add to portfolio logic would go here
                          ScaffoldMessenger.of(
                            context,
                          ).showSnackBar(const SnackBar(content: Text('Adding to portfolio coming soon')));
                        },
                        icon: const Icon(Icons.work, size: 16),
                        label: const Text('Add to Portfolio'),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          visualDensity: VisualDensity.compact,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
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

    return AppScaffold(
      title: task?.title != null ? 'Review: ${task!.title}' : 'Review Submissions',
      showBottomNav: false,
      currentIndex: 1, // Set Tasks as the current tab
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Task info header
          if (task != null)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                border: Border(bottom: BorderSide(color: Theme.of(context).dividerColor)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Task: ${task.title}',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  if (task.expiryDate != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        'Due: ${_formatDate(task.expiryDate!)}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                ],
              ),
            ),

          // Submissions list
          Expanded(
            child: RefreshIndicator(onRefresh: _loadSubmissions, child: _buildContent(submissionProvider)),
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

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: isPending ? 3 : 1, // Highlight pending submissions
          child: Column(
            children: [
              ListTile(
                contentPadding: const EdgeInsets.all(16),
                leading: CircleAvatar(
                  backgroundColor: isPending
                      ? AppTheme.warning.withOpacity(0.8)
                      : Theme.of(context).colorScheme.primary,
                  child: Icon(isPending ? Icons.pending_actions : Icons.check_circle, color: Colors.white),
                ),
                title: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Submission #${submission.submissionId.substring(0, 8)}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: isPending ? Colors.amber : _getGradeColor(submission.grade!),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        isPending ? 'Needs Review' : '${submission.grade}%',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                    ),
                  ],
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.calendar_today, size: 16, color: Theme.of(context).hintColor),
                        const SizedBox(width: 4),
                        Text(
                          'Submitted: ${_formatDate(submission.submittedAt)}',
                          style: TextStyle(color: Theme.of(context).hintColor),
                        ),
                      ],
                    ),
                    if (submission.fileUrl != null) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.attach_file, size: 16, color: Theme.of(context).hintColor),
                          const SizedBox(width: 4),
                          Text('File attached', style: TextStyle(color: Theme.of(context).colorScheme.primary)),
                        ],
                      ),
                    ],
                  ],
                ),
                onTap: () => _showGradeDialog(submission),
              ),

              // Action buttons
              Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.background,
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(12),
                    bottomRight: Radius.circular(12),
                  ),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (submission.fileUrl != null)
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
                    const SizedBox(width: 8),
                    TextButton.icon(
                      onPressed: () => _showGradeDialog(submission),
                      icon: Icon(isPending ? Icons.rate_review : Icons.edit, size: 16),
                      label: Text(isPending ? 'Grade' : 'Edit Grade'),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        visualDensity: VisualDensity.compact,
                      ),
                    ),
                  ],
                ),
              ),
            ],
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
