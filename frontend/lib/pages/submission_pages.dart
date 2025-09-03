import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../config.dart';

class CreateSubmissionPage extends StatefulWidget {
  const CreateSubmissionPage({super.key, required this.taskId, required this.userId});
  final dynamic taskId;
  final dynamic userId;

  @override
  State<CreateSubmissionPage> createState() => _CreateSubmissionPageState();
}

class _CreateSubmissionPageState extends State<CreateSubmissionPage> {
  PlatformFile? selectedFile;
  bool uploading = false;

  Future<void> _pickFile() async {
    final res = await FilePicker.platform.pickFiles();
    if (res != null && res.files.isNotEmpty) {
      setState(() => selectedFile = res.files.first);
    }
  }

  Future<void> _upload() async {
    if (selectedFile == null) return;
    setState(() => uploading = true);
    try {
      final uri = Uri.parse('$backendBaseUrl/submissions');
      final request = http.MultipartRequest('POST', uri);
      request.fields['task_id'] = '${widget.taskId}';
      request.fields['user_id'] = '${widget.userId}';
      final filePath = selectedFile!.path;
      if (filePath != null) {
        request.files.add(await http.MultipartFile.fromPath('file', filePath));
      } else if (selectedFile!.bytes != null) {
        request.files.add(http.MultipartFile.fromBytes('file', selectedFile!.bytes!, filename: selectedFile!.name));
      }
      final streamed = await request.send();
      final response = await http.Response.fromStream(streamed);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception('Upload failed (${response.statusCode})');
      }
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Submitted')));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e')));
      }
    } finally {
      if (mounted) setState(() => uploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Submit Solution')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            ListTile(
              title: const Text('Selected file'),
              subtitle: Text(selectedFile?.name ?? 'None'),
              trailing: TextButton(onPressed: _pickFile, child: const Text('Pick file')),
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: uploading || selectedFile == null ? null : _upload,
                child: Text(uploading ? 'Uploading...' : 'Upload'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class MySubmissionsPage extends StatelessWidget {
  const MySubmissionsPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Minimal placeholder to keep scope small for now
    return Scaffold(
      appBar: AppBar(title: const Text('My Submissions')),
      body: const Center(child: Text('List submissions here (stub)')),
    );
  }
}

class ReviewSubmissionsPage extends StatelessWidget {
  const ReviewSubmissionsPage({super.key, required this.taskId});
  final dynamic taskId;

  @override
  Widget build(BuildContext context) {
    // Minimal placeholder
    return Scaffold(
      appBar: AppBar(title: const Text('Review Submissions')),
      body: Center(child: Text('Review for task $taskId (stub)')),
    );
  }
}
