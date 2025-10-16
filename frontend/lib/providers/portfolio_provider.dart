import 'package:flutter/material.dart';

import '../models/portfolio_model.dart';
import '../services/api_client.dart';

enum PortfolioLoadStatus { initial, loading, loaded, error }

class PortfolioProvider extends ChangeNotifier {
  final ApiClient _apiClient;

  PortfolioLoadStatus _status = PortfolioLoadStatus.initial;
  List<PortfolioEntryModel> _entries = [];
  String? _errorMessage;

  PortfolioLoadStatus get status => _status;
  List<PortfolioEntryModel> get entries => _entries;
  String? get errorMessage => _errorMessage;

  PortfolioProvider({required ApiClient apiClient}) : _apiClient = apiClient;

  Future<void> loadPortfolio(String userId) async {
    try {
      _status = PortfolioLoadStatus.loading;
      notifyListeners();

      final res = await _apiClient.get('/portfolio/$userId');
      final List portfolioData = res['data'] as List? ?? [];

      _entries = portfolioData.map((entry) => PortfolioEntryModel.fromJson(entry)).toList();

      _status = PortfolioLoadStatus.loaded;
    } catch (e) {
      _status = PortfolioLoadStatus.error;
      _errorMessage = e.toString();
    }
    notifyListeners();
  }

  Future<bool> addToPortfolio(String userId, String submissionId) async {
    try {
      _status = PortfolioLoadStatus.loading;
      notifyListeners();

      await _apiClient.post('/portfolio', body: {'user_id': userId, 'submission_id': submissionId});

      // Refresh portfolio after adding a new entry
      await loadPortfolio(userId);
      return true;
    } catch (e) {
      _status = PortfolioLoadStatus.error;
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

//TODO: Uncomment this when the API is implemented
  // Future<bool> removeFromPortfolio(String portfolioId, String userId) async {
  //   try {
  //     _status = PortfolioLoadStatus.loading;
  //     notifyListeners();

  //     await _apiClient.delete('/portfolio/$portfolioId');

  //     // Refresh portfolio after removing an entry
  //     await loadPortfolio(userId);
  //     return true;
  //   } catch (e) {
  //     _status = PortfolioLoadStatus.error;
  //     _errorMessage = e.toString();
  //     notifyListeners();
  //     return false;
  //   }
  // }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
