import 'package:flutter/material.dart';
import 'package:finance_tracker/data/accounts_class.dart';
import 'package:finance_tracker/data/database_service.dart';

// Extend ChangeNotifier to enable notifying listeners
class AccountProvider with ChangeNotifier {
  final DatabaseService _dbService = DatabaseService();

  //State Variables
  List<Account> _accounts = [];
  Map<int, double> _accountBalances = {};

  //Public Getters
  List<Account> get accounts => _accounts;
  Map<int, double> get accountBalances => _accountBalances;

  //Public Methods (Actions)

  Future<void> fetchAccounts() async {
    try {
      _accounts = await _dbService.getAccounts();
      _accountBalances = await _dbService.getAllAccountBalances();
    } catch (e) {
      print("Error fetching accounts or balances: $e");
      _accounts = [];
      _accountBalances = {};
    }
  }

  Future<bool> addAccount(Account account) async {
    try {
      int id = await _dbService.insertAccount(account);
      await fetchAccounts();
      return true;
    } catch (e) {
      print("Error adding account: $e");
      return false;
    }
  }

  Future<bool> updateAccount(Account account) async {
    try {
      await _dbService.updateAccount(account);
      await fetchAccounts();
      return true;
    } catch (e) {
      print("Error updating account: $e");
      return false;
    }
  }

  Future<bool> updateAccountOrder(List<Account> orderedAccounts) async {
    try {
      await _dbService.updateAccountSortOrder(orderedAccounts);
      _accounts = List.from(orderedAccounts);
      notifyListeners();
      return true;
    } catch (e) {
      await fetchAccounts();
      return false;
    }
  }

  Future<bool> deleteAccount(int id) async {
    try {
      int rowsAffected = await _dbService.deleteAccount(id);

      if (rowsAffected > 0) {
        print("Account $id deleted from DB. Refreshing local data.");

        _accounts.removeWhere((acc) => acc.id == id);
        _accountBalances.remove(id);
        notifyListeners();
        return true;
      } else {
        print("Delete operation affected 0 rows for account ID $id.");
        return false;
      }
    } catch (e) {
      print("Error deleting account in provider: $e");
      return false;
    }
  }

  /*
  Future<void> refreshBalances() async {
    print("Refreshing account balances due to transaction change...");
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
*/
}
