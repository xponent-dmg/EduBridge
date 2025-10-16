class EdupointsModel {
  final String userId;
  final int balance;
  final List<EdupointsTransaction> transactions;

  EdupointsModel({required this.userId, required this.balance, this.transactions = const []});

  factory EdupointsModel.fromJson(Map<String, dynamic> json) {
    List<EdupointsTransaction> transactions = [];
    if (json['transactions'] != null) {
      transactions = (json['transactions'] as List).map((tx) => EdupointsTransaction.fromJson(tx)).toList();
    }

    return EdupointsModel(userId: json['user_id'] ?? '', balance: json['balance'] ?? 0, transactions: transactions);
  }

  Map<String, dynamic> toJson() {
    return {'user_id': userId, 'balance': balance, 'transactions': transactions.map((tx) => tx.toJson()).toList()};
  }
}

class EdupointsTransaction {
  final String transactionId;
  final String userId;
  final int amount;
  final String description;
  final DateTime timestamp;

  EdupointsTransaction({
    required this.transactionId,
    required this.userId,
    required this.amount,
    required this.description,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  factory EdupointsTransaction.fromJson(Map<String, dynamic> json) {
    return EdupointsTransaction(
      transactionId: json['transaction_id'] ?? '',
      userId: json['user_id'] ?? '',
      amount: json['amount'] ?? 0,
      description: json['description'] ?? '',
      timestamp: json['timestamp'] != null ? DateTime.parse(json['timestamp']) : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'transaction_id': transactionId,
      'user_id': userId,
      'amount': amount,
      'description': description,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}
