import 'package:flutter/material.dart';

import '../models/user_model.dart';
import '../services/api_client.dart';

enum UserLoadStatus { initial, loading, loaded, error }

class UserProvider extends ChangeNotifier {
  final ApiClient _apiClient;

  UserLoadStatus _status = UserLoadStatus.initial;
  List<UserModel> _users = [];
  UserModel? _selectedUser;
  String? _errorMessage;

  UserLoadStatus get status => _status;
  List<UserModel> get users => _users;
  UserModel? get selectedUser => _selectedUser;
  String? get errorMessage => _errorMessage;

  List<UserModel> get students => _users.where((user) => user.role == 'student').toList();
  List<UserModel> get companies => _users.where((user) => user.role == 'company').toList();
  List<UserModel> get admins => _users.where((user) => user.role == 'admin').toList();

  UserProvider({required ApiClient apiClient}) : _apiClient = apiClient;

  Future<void> loadUsers() async {
    try {
      _status = UserLoadStatus.loading;
      notifyListeners();

      final res = await _apiClient.get('/users');
      final List userData = res['data'] as List? ?? [];

      _users = userData.map((user) => UserModel.fromJson(user)).toList();
      _status = UserLoadStatus.loaded;
    } catch (e) {
      _status = UserLoadStatus.error;
      _errorMessage = e.toString();
    }
    notifyListeners();
  }

  Future<void> loadUserDetails(String userId) async {
    try {
      _status = UserLoadStatus.loading;
      notifyListeners();

      final res = await _apiClient.get('/users/$userId');
      final userData = res['data'] as Map<String, dynamic>?;

      if (userData != null) {
        _selectedUser = UserModel.fromJson(userData);
      }

      _status = UserLoadStatus.loaded;
    } catch (e) {
      _status = UserLoadStatus.error;
      _errorMessage = e.toString();
    }
    notifyListeners();
  }

  Future<bool> updateUserSkills(String userId, List<String> skills) async {
    try {
      _status = UserLoadStatus.loading;
      notifyListeners();

      await _apiClient.patch('/users/$userId/skills', body: {'skills': skills});

      // Update user in our local list
      final index = _users.indexWhere((u) => u.userId == userId);
      if (index >= 0) {
        _users[index] = _users[index].copyWith(skills: skills);
      }

      // Update selected user if it's the same
      if (_selectedUser?.userId == userId) {
        _selectedUser = _selectedUser!.copyWith(skills: skills);
      }

      _status = UserLoadStatus.loaded;
      notifyListeners();
      return true;
    } catch (e) {
      _status = UserLoadStatus.error;
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
