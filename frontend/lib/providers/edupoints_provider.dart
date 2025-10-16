import 'package:flutter/material.dart';

import '../models/edupoints_model.dart';
import '../services/api_client.dart';

enum EdupointsLoadStatus { initial, loading, loaded, error }

class EdupointsProvider extends ChangeNotifier {
  final ApiClient _apiClient;

  EdupointsLoadStatus _status = EdupointsLoadStatus.initial;
  EdupointsModel? _edupoints;
  String? _errorMessage;

  EdupointsLoadStatus get status => _status;
  EdupointsModel? get edupoints => _edupoints;
  int get balance => _edupoints?.balance ?? 0;
  List<EdupointsTransaction> get transactions => _edupoints?.transactions ?? [];
  String? get errorMessage => _errorMessage;

  EdupointsProvider({required ApiClient apiClient}) : _apiClient = apiClient;

  Future<void> loadEdupoints(String userId) async {
    try {
      _status = EdupointsLoadStatus.loading;
      notifyListeners();

      final res = await _apiClient.get('/edupoints/$userId');
      final data = res['data'] as Map<String, dynamic>?;

      if (data != null) {
        _edupoints = EdupointsModel.fromJson(data);
      }

      _status = EdupointsLoadStatus.loaded;
    } catch (e) {
      _status = EdupointsLoadStatus.error;
      _errorMessage = e.toString();
    }
    notifyListeners();
  }

  Future<bool> awardPoints({required String userId, required int amount, required String description}) async {
    try {
      _status = EdupointsLoadStatus.loading;
      notifyListeners();

      await _apiClient.post(
        '/edupoints/award',
        body: {'user_id': userId, 'amount': amount, 'description': description},
      );

      // Refresh edupoints data
      await loadEdupoints(userId);
      return true;
    } catch (e) {
      _status = EdupointsLoadStatus.error;
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
