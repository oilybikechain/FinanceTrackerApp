import 'package:flutter/material.dart'; 
import 'package:finance_tracker/data/accounts_class.dart';     
import 'package:finance_tracker/data/database_service.dart'; 

// Extend ChangeNotifier to enable notifying listeners
class AccountProvider with ChangeNotifier {
   final DatabaseService _dbService = DatabaseService();

  // --- State Variables ---
  List<Account> _accounts = [];
  // --- NEW: Store balances mapped by account ID ---
  Map<int, double> _accountBalances = {};
  bool _isLoading = false;
  String? _error;

  // --- Public Getters ---
  List<Account> get accounts => _accounts;
  // --- NEW: Getter for the balance map ---
  Map<int, double> get accountBalances => _accountBalances;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // --- Public Methods (Actions) ---

  Future<void> fetchAccounts() async {
    _setError(null);
    _setLoading(true);

    try {
      // Fetch accounts and balances in parallel if desired, or sequentially
      // Sequential example:
      _accounts = await _dbService.getAccounts();
      // Fetch all balances using the efficient method
      _accountBalances = await _dbService.getAllAccountBalances();

      // If using parallel fetching:
      // final results = await Future.wait([
      //   _dbService.getAccounts(),
      //   _dbService.getAllAccountBalances(),
      // ]);
      // _accounts = results[0] as List<Account>;
      // _accountBalances = results[1] as Map<int, double>;

      _setLoading(false); // Set loading false *after* both fetches complete
    } catch (e) {
      print("Error fetching accounts or balances: $e");
      _setError("Failed to load account data.");
      _accounts = [];
      _accountBalances = {}; // Clear balances on error too
      _setLoading(false);
    }
    // notifyListeners() is called by _setLoading and _setError
  }

  // --- UPDATE Add, Update, Delete to Refresh Balances ---
  // The simplest way to keep balances up-to-date after modifications
  // is to re-fetch everything.

  Future<bool> addAccount(Account account) async {
    // ... (existing insert logic) ...
    try {
      int id = await _dbService.insertAccount(account);
      // Success! Now refresh accounts and balances
      await fetchAccounts(); // Re-fetch all data
      return true;
    } catch (e) {
      print("Error adding account: $e");
      _setError("Failed to add account.");
      return false;
    }
  }

  Future<bool> updateAccount(Account account) async {
     // ... (existing update logic) ...
     try {
        await _dbService.updateAccount(account);
        // Success! Refresh accounts and balances (especially if initialBalance changed)
        await fetchAccounts(); // Re-fetch all data
        return true;
     } catch (e) {
         print("Error updating account: $e");
         _setError("Failed to update account.");
        return false;
     }
  }

   Future<bool> updateAccountOrder(List<Account> orderedAccounts) async {
     // ... (existing update logic) ...
     try {
       await _dbService.updateAccountSortOrder(orderedAccounts);
       // OPTIMIZATION: Only need to update local list order, balances don't change
       _accounts = List.from(orderedAccounts);
       notifyListeners(); // Just notify about reorder
       return true;
     } catch (e) {
        // ... (error handling, maybe revert or refetch) ...
        await fetchAccounts(); // Refresh on error to be safe
        return false;
     }
   }

  Future<bool> deleteAccount(int id) async {
    // ... (existing delete logic) ...
    try {
      await _dbService.deleteAccount(id);
      // Success! Refresh accounts and balances
      await fetchAccounts(); // Re-fetch all data
      return true;
    } catch (e) {
       print("Error deleting account: $e");
       _setError("Failed to delete account.");
       return false;
    }
  }

  // Method called when a transaction is added/updated/deleted elsewhere
  // This signals that balances might have changed.
  Future<void> refreshBalances() async {
    // Could implement more targeted balance updates, but fetching all is simpler
    print("Refreshing account balances due to transaction change...");
    _setError(null);
    _setLoading(true); // Maybe a quieter loading indicator?
    try {
       _accountBalances = await _dbService.getAllAccountBalances();
       // No need to fetch _accounts again if only transactions changed
    } catch (e) {
       print("Error refreshing balances: $e");
       _setError("Failed to refresh balances.");
       _accountBalances = {};
    } finally {
       _setLoading(false);
    }
  }

  

  // --- Private Helper Methods ---
  // Helper to set loading state and notify listeners
  void _setLoading(bool loading) {
    if (_isLoading == loading) return; // Avoid unnecessary updates
    _isLoading = loading; // Update the state variable immediately

    // Schedule notifyListeners to run after the current frame/build is finished
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Check if the provider is still mounted/active before notifying.
      // This check isn't strictly necessary for notifyListeners itself,
      // but can be good practice if you have complex logic depending on mount state.
      // In this simple case, direct call is usually fine.
      notifyListeners();
    });
  }

  // Helper to set error state and schedule notification
  void _setError(String? error) {
    if (_error == error) return; // Avoid unnecessary updates
    _error = error; // Update the state variable immediately

    // Schedule notifyListeners to run after the current frame/build is finished
    WidgetsBinding.instance.addPostFrameCallback((_) {
       notifyListeners();
    });
  }
}