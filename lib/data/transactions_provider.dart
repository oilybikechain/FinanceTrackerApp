import 'package:flutter/material.dart'; 
import 'package:finance_tracker/data/transactions_class.dart';     
import 'package:finance_tracker/data/database_service.dart'; 


class TransactionsProvider with ChangeNotifier {
  final DatabaseService _dbService = DatabaseService();

  // --- State Variables ---
  // Holds the currently displayed list of transactions (might be filtered)
  List<Transactions> _transactions = [];
  bool _isLoading = false;
  String? _error;

  // --- Public Getters ---
  List<Transactions> get transactions => _transactions;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // --- Public Methods (Actions) ---

  // Fetch transactions based on optional filters
  // This allows fetching all, by account, by date range, etc.
  Future<void> fetchTransactions({
    List<int>? accountIds,
    DateTime? startDate,
    DateTime? endDate,
    int? limit,
  }) async {
    _setError(null);
    _setLoading(true);

    try {
      _transactions = await _dbService.getTransactions(
        accountIds: accountIds,
        startDate: startDate,
        endDate: endDate,
        limit: limit,
      );
      _setLoading(false);
    } catch (e) {
      print("Error fetching transactions: $e");
      _setError("Failed to load transactions.");
      _transactions = []; // Clear list on error
      _setLoading(false);
    }
  }

  // Add a new transaction
  // Note: For transfers, you'll need to call this TWICE (one positive, one negative)
  // potentially wrapped in a higher-level function.
  Future<bool> addTransaction(Transactions transaction) async {
    _setError(null);
    // _setLoading(true); // Optional: maybe not needed for simple adds

    try {
      int id = await _dbService.insertTransaction(transaction);
      final newTransaction = transaction.copyWith(id: id);

      // Add to the beginning of the list if maintaining recent-first order
      _transactions.insert(0, newTransaction);
      // Or, if sorting is handled elsewhere/refetched: _transactions.add(newTransaction);

      notifyListeners();
      // _setLoading(false);
      return true; // Success
    } catch (e) {
      print("Error adding transaction: $e");
      _setError("Failed to add transaction.");
      // _setLoading(false);
      return false; // Failure
    }
  }

  // Update an existing transaction
  Future<bool> updateTransaction(Transactions transaction) async {
    _setError(null);
    // _setLoading(true); // Optional

    try {
      await _dbService.updateTransaction(transaction);

      final index = _transactions.indexWhere((t) => t.id == transaction.id);
      if (index != -1) {
        _transactions[index] = transaction;
        // Re-sort if necessary, e.g., by date
        _transactions.sort((a, b) => b.timestamp.compareTo(a.timestamp)); // Descending
        notifyListeners();
      }
      // _setLoading(false);
      return true; // Success
    } catch (e) {
      print("Error updating transaction: $e");
      _setError("Failed to update transaction.");
      // _setLoading(false);
      return false; // Failure
    }
  }

  // Delete a transaction
  Future<bool> deleteTransaction(int id) async {
    _setError(null);
    // _setLoading(true); // Optional

    try {
      await _dbService.deleteTransaction(id);
      _transactions.removeWhere((t) => t.id == id);
      notifyListeners();
      // _setLoading(false);
      return true; // Success
    } catch (e) {
      print("Error deleting transaction: $e");
      _setError("Failed to delete transaction.");
      // _setLoading(false);
      return false; // Failure
    }
  }

  // --- TODO: Add methods for specific calculations if needed ---
  // e.g., Future<Map<String, double>> getIncomeExpenseTotals(...)


  // --- Private Helper Methods ---
  void _setLoading(bool loading) {
    if (_isLoading == loading) return; // Avoid unnecessary notifications
    _isLoading = loading;
    WidgetsBinding.instance.addPostFrameCallback((_) {
       notifyListeners();
    });
  }

  void _setError(String? error) {
    if (_error == error) return;
    _error = error;
    WidgetsBinding.instance.addPostFrameCallback((_) {
       notifyListeners();
    });
  }
}