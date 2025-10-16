import 'package:flutter/material.dart';

import '../models/task_model.dart';
import '../services/api_client.dart';

enum TaskLoadStatus { initial, loading, loaded, error }

class TaskProvider extends ChangeNotifier {
  final ApiClient _apiClient;

  TaskLoadStatus _status = TaskLoadStatus.initial;
  List<TaskModel> _tasks = [];
  TaskModel? _selectedTask;
  String? _errorMessage;

  // Filtering options
  String _domainFilter = '';
  RangeValues _effortFilter = const RangeValues(0, 80);

  TaskLoadStatus get status => _status;
  List<TaskModel> get tasks => _tasks;
  TaskModel? get selectedTask => _selectedTask;
  String? get errorMessage => _errorMessage;

  String get domainFilter => _domainFilter;
  RangeValues get effortFilter => _effortFilter;

  TaskProvider({required ApiClient apiClient}) : _apiClient = apiClient;

  Future<void> loadTasks() async {
    try {
      _status = TaskLoadStatus.loading;
      notifyListeners();

      final res = await _apiClient.get('/tasks');
      final List taskData = res['data'] as List? ?? [];

      _tasks = taskData.map((task) => TaskModel.fromJson(task)).toList();
      _status = TaskLoadStatus.loaded;
    } catch (e) {
      _status = TaskLoadStatus.error;
      _errorMessage = e.toString();
    }
    notifyListeners();
  }

  Future<void> loadCompanyTasks(String companyId) async {
    try {
      _status = TaskLoadStatus.loading;
      notifyListeners();

      final res = await _apiClient.get('/tasks/company/$companyId');
      final List taskData = res['data'] as List? ?? [];

      _tasks = taskData.map((task) => TaskModel.fromJson(task)).toList();
      _status = TaskLoadStatus.loaded;
    } catch (e) {
      _status = TaskLoadStatus.error;
      _errorMessage = e.toString();
    }
    notifyListeners();
  }

  Future<void> loadTaskDetails(String taskId) async {
    try {
      _status = TaskLoadStatus.loading;
      notifyListeners();

      final res = await _apiClient.get('/tasks/$taskId');
      final taskData = res['data'] as Map<String, dynamic>?;

      if (taskData != null) {
        _selectedTask = TaskModel.fromJson(taskData);
      }

      _status = TaskLoadStatus.loaded;
    } catch (e) {
      _status = TaskLoadStatus.error;
      _errorMessage = e.toString();
    }
    notifyListeners();
  }

  Future<bool> createTask(Map<String, dynamic> taskData) async {
    try {
      _status = TaskLoadStatus.loading;
      notifyListeners();

      await _apiClient.post('/tasks', body: taskData);

      // Refresh task list after creating a new task
      await loadTasks();
      return true;
    } catch (e) {
      _status = TaskLoadStatus.error;
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  void setDomainFilter(String domain) {
    _domainFilter = domain;
    notifyListeners();
  }

  void setEffortFilter(RangeValues range) {
    _effortFilter = range;
    notifyListeners();
  }

  List<TaskModel> get filteredTasks {
    return _tasks.where((task) {
      final matchesDomain =
          _domainFilter.isEmpty ||
          task.domains.any((domain) => domain.toLowerCase().contains(_domainFilter.toLowerCase()));
      final matchesEffort = task.effortHours >= _effortFilter.start && task.effortHours <= _effortFilter.end;
      return matchesDomain && matchesEffort;
    }).toList();
  }

  void clearFilters() {
    _domainFilter = '';
    _effortFilter = const RangeValues(0, 80);
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
