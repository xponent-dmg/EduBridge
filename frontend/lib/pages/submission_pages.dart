import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/submission_model.dart';
import '../providers/auth_provider.dart';
import '../providers/submission_provider.dart';
import '../providers/task_provider.dart';
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
        userId: userId,
        fileBytes: selectedFile!.bytes ?? [],
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
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: submissions.length,
      itemBuilder: (context, index) {
        final submission = submissions[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Theme.of(context).colorScheme.primary,
              child: const Icon(Icons.upload_file, color: Colors.white),
            ),
            title: Text(
              'Submission #${submission.submissionId.substring(0, 8)}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text('Submitted: ${_formatDate(submission.submittedAt)}'),
                if (submission.grade != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Row(
                      children: [
                        Text('Grade: '),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: _getGradeColor(submission.grade!),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${submission.grade}%',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showSubmissionDetails(submission),
          ),
        );
      },
    );
  }

  void _showSubmissionDetails(SubmissionModel submission) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.5,
        maxChildSize: 0.9,
        minChildSize: 0.4,
        expand: false,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          child: Padding(
            padding: const EdgeInsets.all(16),
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
                const SizedBox(height: 16),
                Text(
                  'Submission Details',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 16),
                _buildDetailRow('ID', submission.submissionId),
                _buildDetailRow('Task ID', submission.taskId),
                _buildDetailRow('Submitted', _formatDate(submission.submittedAt)),
                if (submission.fileUrl != null) _buildDetailRow('File', submission.fileUrl!),
                if (submission.grade != null) ...[
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Grade',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                ],
                if (submission.feedback != null && submission.feedback!.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Text(
                    'Feedback',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Text(submission.feedback!),
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
    _loadSubmissions();
  }

  Future<void> _loadSubmissions() async {
    final submissionProvider = Provider.of<SubmissionProvider>(context, listen: false);
    await submissionProvider.loadTaskSubmissions(widget.taskId.toString());
  }

  @override
  Widget build(BuildContext context) {
    final submissionProvider = Provider.of<SubmissionProvider>(context);

    return AppScaffold(
      title: 'Review Submissions',
      showBottomNav: false,
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
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: submissions.length,
      itemBuilder: (context, index) {
        final submission = submissions[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Theme.of(context).colorScheme.primary,
              child: const Icon(Icons.upload_file, color: Colors.white),
            ),
            title: Text(
              'User ID: ${submission.userId.substring(0, 8)}...',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text('Submitted: ${_formatDate(submission.submittedAt)}'),
                if (submission.grade != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Row(
                      children: [
                        Text('Grade: '),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: _getGradeColor(submission.grade!),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${submission.grade}%',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showGradeDialog(submission),
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
