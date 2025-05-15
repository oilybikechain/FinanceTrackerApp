import 'package:flutter/material.dart';
import 'package:finance_tracker/data/transactions_class.dart';
import 'package:finance_tracker/data/database_service.dart';

class TransactionsProvider with ChangeNotifier {
  final DatabaseService _dbService = DatabaseService();

  List<Transactions> _transactions = [];

  List<Transactions> get transactions => _transactions;

  Future<void> fetchTransactions({
    List<int>? accountIds,
    DateTime? startDate,
    DateTime? endDate,
    int? limit,
  }) async {
    try {
      _transactions = await _dbService.getTransactions(
        accountIds: accountIds,
        startDate: startDate,
        endDate: endDate,
        limit: limit,
      );
    } catch (e) {
      print("Error fetching transactions: $e");
      _transactions = [];
    }
  }

  Future<bool> addTransaction(Transactions transaction) async {
    try {
      int id = await _dbService.insertTransaction(transaction);
      final newTransaction = transaction.copyWith(id: id);

      _transactions.insert(0, newTransaction);

      notifyListeners();
      return true;
    } catch (e) {
      print("Error adding transaction: $e");
      return false;
    }
  }

  Future<bool> updateTransaction(Transactions transaction) async {
    try {
      await _dbService.updateTransaction(transaction);

      final index = _transactions.indexWhere((t) => t.id == transaction.id);
      if (index != -1) {
        _transactions[index] = transaction;
        _transactions.sort(
          (a, b) => b.timestamp.compareTo(a.timestamp),
        ); // Descending
        notifyListeners();
      }
      return true;
    } catch (e) {
      print("Error updating transaction: $e");
      return false;
    }
  }

  // Delete a transaction
  Future<bool> deleteTransaction(int id) async {
    try {
      await _dbService.deleteTransaction(id);
      _transactions.removeWhere((t) => t.id == id);
      notifyListeners();
      return true;
    } catch (e) {
      print("Error deleting transaction: $e");
      return false;
    }
  }
}
