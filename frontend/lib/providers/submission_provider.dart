import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;

import '../config.dart';
import '../models/submission_model.dart';
import '../services/api_client.dart';

enum SubmissionLoadStatus { initial, loading, loaded, uploading, success, error }

class SubmissionProvider extends ChangeNotifier {
  final ApiClient _apiClient;

  SubmissionLoadStatus _status = SubmissionLoadStatus.initial;
  List<SubmissionModel> _submissions = [];
  String? _errorMessage;

  SubmissionLoadStatus get status => _status;
  List<SubmissionModel> get submissions => _submissions;
  String? get errorMessage => _errorMessage;

  SubmissionProvider({required ApiClient apiClient}) : _apiClient = apiClient;

  Future<void> loadUserSubmissions(String userId) async {
    try {
      _status = SubmissionLoadStatus.loading;
      notifyListeners();

      final res = await _apiClient.get('/submissions/user/$userId');
      final List submissionData = res['data'] as List? ?? [];

      _submissions = submissionData.map((submission) => SubmissionModel.fromJson(submission)).toList();
      _status = SubmissionLoadStatus.loaded;
    } catch (e) {
      _status = SubmissionLoadStatus.error;
      _errorMessage = e.toString();
    }
    notifyListeners();
  }

  Future<void> loadTaskSubmissions(String taskId) async {
    try {
      _status = SubmissionLoadStatus.loading;
      notifyListeners();

      final res = await _apiClient.get('/submissions/task/$taskId');
      final List submissionData = res['data'] as List? ?? [];

      _submissions = submissionData.map((submission) => SubmissionModel.fromJson(submission)).toList();
      _status = SubmissionLoadStatus.loaded;
    } catch (e) {
      _status = SubmissionLoadStatus.error;
      _errorMessage = e.toString();
    }
    notifyListeners();
  }

  Future<bool> uploadSubmission({
    required String taskId,
    required String userId,
    List<int>? fileBytes,
    String? filePath,
    required String fileName,
  }) async {
    try {
      _status = SubmissionLoadStatus.uploading;
      notifyListeners();

      final uri = Uri.parse('$backendBaseUrl/submissions');
      final request = http.MultipartRequest('POST', uri);

      // Add auth header if we have a token
      if (_apiClient.authToken != null) {
        request.headers['Authorization'] = 'Bearer ${_apiClient.authToken!}';
      }

      request.fields['task_id'] = taskId;
      request.fields['user_id'] = userId;

      // Add file to request (prefer bytes; fallback to path)
      if (fileBytes != null) {
        final multipartFile = http.MultipartFile.fromBytes('file', fileBytes, filename: path.basename(fileName));
        request.files.add(multipartFile);
      } else if (filePath != null && filePath.isNotEmpty) {
        final multipartFile = await http.MultipartFile.fromPath('file', filePath, filename: path.basename(fileName));
        request.files.add(multipartFile);
      } else {
        throw Exception('No file data found');
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        _status = SubmissionLoadStatus.success;
        notifyListeners();
        return true;
      } else {
        throw Exception('Upload failed with status code: ${response.statusCode}');
      }
    } catch (e) {
      _status = SubmissionLoadStatus.error;
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> gradeSubmission({required String submissionId, required int grade, required String feedback}) async {
    try {
      _status = SubmissionLoadStatus.loading;
      notifyListeners();

      await _apiClient.patch('/submissions/$submissionId/grade', body: {'grade': grade, 'feedback': feedback});

      // Update the submission in our local list
      final index = _submissions.indexWhere((s) => s.submissionId == submissionId);
      if (index >= 0) {
        final updated = _submissions[index].copyWith(grade: grade, feedback: feedback);
        _submissions[index] = updated;
      }

      _status = SubmissionLoadStatus.success;
      notifyListeners();
      return true;
    } catch (e) {
      _status = SubmissionLoadStatus.error;
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
