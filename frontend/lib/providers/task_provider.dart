import 'package:flutter/material.dart';

import '../models/task_model.dart';
import '../services/api_client.dart';

enum TaskLoadStatus { initial, loading, loaded, error }

enum TaskSort { newest, oldest, expirySoon, expiryLatest }

class TaskProvider extends ChangeNotifier {
  final ApiClient _apiClient;

  TaskLoadStatus _status = TaskLoadStatus.initial;
  List<TaskModel> _tasks = [];
  TaskModel? _selectedTask;
  String? _errorMessage;

  // Filtering options
  String _domainFilter = '';
  RangeValues _effortFilter = const RangeValues(0, 80);
  bool _hideExpired = false;
  TaskSort _sort = TaskSort.expirySoon;

  TaskLoadStatus get status => _status;
  List<TaskModel> get tasks => _tasks;
  TaskModel? get selectedTask => _selectedTask;
  String? get errorMessage => _errorMessage;

  String get domainFilter => _domainFilter;
  RangeValues get effortFilter => _effortFilter;
  bool get hideExpired => _hideExpired;
  TaskSort get sort => _sort;

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

  void setHideExpired(bool value) {
    _hideExpired = value;
    notifyListeners();
  }

  void setSort(TaskSort value) {
    _sort = value;
    notifyListeners();
  }

  bool _isExpired(TaskModel task) {
    final expiry = task.expiryDate;
    if (expiry == null) return false;
    return expiry.isBefore(DateTime.now());
  }

  bool _isActive(TaskModel task) => !_isExpired(task);

  int _compareTasks(TaskModel a, TaskModel b) {
    switch (_sort) {
      case TaskSort.newest:
        return b.createdAt.compareTo(a.createdAt);
      case TaskSort.oldest:
        return a.createdAt.compareTo(b.createdAt);
      case TaskSort.expiryLatest:
        {
          final aExpiry = a.expiryDate;
          final bExpiry = b.expiryDate;
          // Null expiry at end
          if (aExpiry == null && bExpiry == null) return 0;
          if (aExpiry == null) return 1;
          if (bExpiry == null) return -1;
          return bExpiry.compareTo(aExpiry);
        }
      case TaskSort.expirySoon:
        {
          final aExpiry = a.expiryDate ?? DateTime(9999);
          final bExpiry = b.expiryDate ?? DateTime(9999);
          return aExpiry.compareTo(bExpiry);
        }
    }
  }

  List<TaskModel> _applyCommonFilters(Iterable<TaskModel> source) {
    return source.where((task) {
      final matchesDomain =
          _domainFilter.isEmpty ||
          task.domains.any((domain) => domain.toLowerCase().contains(_domainFilter.toLowerCase()));
      final matchesEffort = task.effortHours >= _effortFilter.start && task.effortHours <= _effortFilter.end;
      return matchesDomain && matchesEffort;
    }).toList()..sort(_compareTasks);
  }

  List<TaskModel> get filteredTasks {
    final list = _applyCommonFilters(_tasks);
    if (_hideExpired) {
      return list.where(_isActive).toList();
    }
    return list;
  }

  List<TaskModel> get activeTasks => _tasks.where(_isActive).toList()..sort(_compareTasks);
  List<TaskModel> get expiredTasks => _tasks.where(_isExpired).toList()..sort(_compareTasks);

  List<TaskModel> get filteredActiveTasks => _applyCommonFilters(_tasks.where(_isActive));
  List<TaskModel> get filteredExpiredTasks => _applyCommonFilters(_tasks.where(_isExpired));

  void clearFilters() {
    _domainFilter = '';
    _effortFilter = const RangeValues(0, 80);
    _hideExpired = false;
    _sort = TaskSort.expirySoon;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
