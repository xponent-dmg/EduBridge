import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/user_model.dart';
import '../services/api_client.dart';
import '../services/auth_service.dart';

enum AuthStatus { initial, authenticated, unauthenticated, loading, error }

class AuthProvider extends ChangeNotifier {
  AuthStatus _status = AuthStatus.initial;
  String? _token;
  UserModel? _currentUser;
  String? _errorMessage;

  AuthStatus get status => _status;
  String? get token => _token;
  UserModel? get currentUser => _currentUser;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _status == AuthStatus.authenticated;

  AuthProvider() {
    _initAuth();
  }

  Future<void> _initAuth() async {
    try {
      _status = AuthStatus.loading;
      notifyListeners();

      await AuthService.initIfConfigured();
      _token = AuthService.currentToken;

      if (_token != null) {
        await _fetchCurrentUser();
      } else {
        _status = AuthStatus.unauthenticated;
      }
    } catch (e) {
      _status = AuthStatus.error;
      _errorMessage = e.toString();
    }
    notifyListeners();
  }

  Future<void> _fetchCurrentUser() async {
    try {
      final api = ApiClient(authToken: _token);
      final res = await api.get('/users/me');
      if (res['data'] != null) {
        _currentUser = UserModel.fromJson(res['data']);
        _status = AuthStatus.authenticated;
      } else {
        _status = AuthStatus.unauthenticated;
      }
    } catch (e) {
      _status = AuthStatus.unauthenticated;
      _errorMessage = e.toString();
    }
    notifyListeners();
  }

  Future<bool> signIn(String email, String password) async {
    try {
      _status = AuthStatus.loading;
      _errorMessage = null;
      notifyListeners();

      _token = await AuthService.signIn(email, password);

      if (_token != null) {
        await _fetchCurrentUser();
        return true;
      } else {
        _status = AuthStatus.unauthenticated;
        _errorMessage = "Authentication failed";
        notifyListeners();
        return false;
      }
    } catch (e) {
      _status = AuthStatus.error;
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> signUp(String email, String password, String name, String role) async {
    try {
      _status = AuthStatus.loading;
      _errorMessage = null;
      notifyListeners();

      _token = await AuthService.signUp(email, password);

      if (_token != null) {
        // Register user in backend users table
        final api = ApiClient(authToken: _token);
        await api.post('/users', body: {'name': name.isEmpty ? email : name, 'email': email, 'role': role});

        await _fetchCurrentUser();
        return true;
      } else {
        _status = AuthStatus.unauthenticated;
        _errorMessage = "Registration failed";
        notifyListeners();
        return false;
      }
    } catch (e) {
      _status = AuthStatus.error;
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<void> signOut() async {
    try {
      _status = AuthStatus.loading;
      notifyListeners();

      if (AuthService.isInitialized) {
        await Supabase.instance.client.auth.signOut();
      }

      _token = null;
      _currentUser = null;
      _status = AuthStatus.unauthenticated;
    } catch (e) {
      _errorMessage = e.toString();
    }
    notifyListeners();
  }

  // For demo mode
  void setMockUser(String role) {
    _status = AuthStatus.authenticated;
    _currentUser = UserModel(
      userId: 'mock-${DateTime.now().millisecondsSinceEpoch}',
      name: 'Demo ${role[0].toUpperCase()}${role.substring(1)}',
      email: 'demo_$role@example.com',
      role: role,
    );
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
