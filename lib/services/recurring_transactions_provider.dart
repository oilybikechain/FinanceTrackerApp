import 'package:flutter/material.dart';
import 'package:finance_tracker/data/recurring_transactions_class.dart';
import 'package:finance_tracker/services/database_service.dart';

class RecurringTransactionsProvider with ChangeNotifier {
  final DatabaseService _dbService = DatabaseService();

  // --- State Variables ---
  List<RecurringTransaction> _recurringTransactions = [];
  bool _isLoading = false;
  String? _error;

  // --- Public Getters ---
  List<RecurringTransaction> get recurringTransactions =>
      _recurringTransactions;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // --- Public Methods (Actions) ---

  // Fetch all recurring transaction rules
  Future<void> fetchRecurringTransactions() async {
    _setError(null);
    _setLoading(true);

    try {
      _recurringTransactions = await _dbService.getAllRecurringTransactions();
      _setLoading(false);
    } catch (e) {
      print("Error fetching recurring transactions: $e");
      _setError("Failed to load recurring transactions.");
      _recurringTransactions = [];
      _setLoading(false);
    }
  }

  // Add a new recurring transaction rule
  Future<bool> addRecurringTransaction(RecurringTransaction recurring) async {
    _setError(null);
    // _setLoading(true); // Optional

    try {
      int id = await _dbService.insertRecurringTransaction(recurring);
      final newRecurring = recurring.copyWith(id: id);
      _recurringTransactions.add(newRecurring);
      // Sort maybe by next due date?
      _recurringTransactions.sort(
        (a, b) => a.nextDueDate.compareTo(b.nextDueDate),
      );
      notifyListeners();
      // _setLoading(false);
      return true; // Success
    } catch (e) {
      print("Error adding recurring transaction: $e");
      _setError("Failed to add recurring transaction rule.");
      // _setLoading(false);
      return false; // Failure
    }
  }

  // Update an existing recurring transaction rule
  Future<bool> updateRecurringTransaction(
    RecurringTransaction recurring,
  ) async {
    _setError(null);
    // _setLoading(true); // Optional

    try {
      await _dbService.updateRecurringTransaction(recurring);
      final index = _recurringTransactions.indexWhere(
        (r) => r.id == recurring.id,
      );
      if (index != -1) {
        _recurringTransactions[index] = recurring;
        _recurringTransactions.sort(
          (a, b) => a.nextDueDate.compareTo(b.nextDueDate),
        );
        notifyListeners();
      }
      // _setLoading(false);
      return true; // Success
    } catch (e) {
      print("Error updating recurring transaction: $e");
      _setError("Failed to update recurring transaction rule.");
      // _setLoading(false);
      return false; // Failure
    }
  }

  // Delete a recurring transaction rule
  Future<bool> deleteRecurringTransaction(int id) async {
    _setError(null);
    // _setLoading(true); // Optional

    try {
      await _dbService.deleteRecurringTransaction(id);
      _recurringTransactions.removeWhere((r) => r.id == id);
      notifyListeners();
      // _setLoading(false);
      return true; // Success
    } catch (e) {
      print("Error deleting recurring transaction: $e");
      _setError("Failed to delete recurring transaction rule.");
      // _setLoading(false);
      return false; // Failure
    }
  }

  // --- TODO: Logic for Processing Due Recurring Transactions ---
  // This is more complex and might involve:
  // 1. Calling _dbService.getDueRecurringTransactions(DateTime.now())
  // 2. Looping through the results
  // 3. For each result:
  //    a. Create a new Transactions object based on the rule.
  //    b. (For transfers) Create the second corresponding Transactions object.
  //    c. Call TransactionsProvider.addTransaction (needs careful context/dependency injection)
  //       OR directly call _dbService.insertTransaction.
  //    d. Calculate the *next* next_due_date based on the rule's frequency.
  //    e. Check if the new next_due_date is after the end_date (if any).
  //    f. Update the RecurringTransaction rule in the DB with the new next_due_date
  //       OR delete it if it has passed its end_date.
  // 4. Update the local _recurringTransactions list (or refetch).
  // This processing might be better suited for a separate service or triggered
  // periodically (e.g., on app startup).

  // Example placeholder:
  // Future<void> processDueRecurringTransactions() async { ... }

  // --- Private Helper Methods ---
  void _setLoading(bool loading) {
    if (_isLoading == loading) return;
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
