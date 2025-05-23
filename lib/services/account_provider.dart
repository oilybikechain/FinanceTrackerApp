import 'package:flutter/material.dart';
import 'package:finance_tracker/data/accounts_class.dart';
import 'package:finance_tracker/services/database_service.dart';

// Extend ChangeNotifier to enable notifying listeners
class AccountProvider with ChangeNotifier {
  final DatabaseService _dbService = DatabaseService();

  //State Variables
  List<Account> _accounts = [];
  Map<int, double> _accountBalances = {};
  double? _periodEndBalance;
  static const int allAccountsIdPlaceholder = 0;
  bool _isPeriodEndBalanceLoading = false;
  bool _isAccountCreatedByPeriodEnd = true;

  //Public Getters
  List<Account> get accounts => _accounts;
  Map<int, double> get accountBalances => _accountBalances;

  double? get periodEndBalance => _periodEndBalance;
  bool get isPeriodEndBalanceLoading => _isPeriodEndBalanceLoading;
  bool get isAccountCreatedByPeriodEnd => _isAccountCreatedByPeriodEnd;
  //Public Methods (Actions)

  Future<void> fetchAccounts() async {
    try {
      _accounts = await _dbService.getAccounts();
      _accountBalances = await _dbService.getAllAccountBalances();
    } catch (e) {
      print("Error fetching accounts or balances: $e");
      _accounts = [];
      _accountBalances = {};
    } finally {
      notifyListeners();
    }
  }

  Future<void> fetchAccountBalanceAtDate(
    int accountId,
    DateTime endDate,
  ) async {
    _isPeriodEndBalanceLoading = true;
    _isAccountCreatedByPeriodEnd = true;
    notifyListeners();
    try {
      if (accountId == allAccountsIdPlaceholder) {
        _isAccountCreatedByPeriodEnd = true;
        Map<int, double> allBalancesAtDate = await _dbService
            .getAllAccountBalancesAtDate(endDate);
        double totalPortfolioBalance = 0.0;
        allBalancesAtDate.forEach((accountId, balance) {
          totalPortfolioBalance += balance;
        });
        _periodEndBalance = totalPortfolioBalance;
        print(
          "AccountProvider: Fetched TOTAL period-end balance for All Accounts at $endDate: $_periodEndBalance",
        );
      } else {
        final Account? selectedAccountDetails = _accounts.firstWhere(
          (acc) => acc.id == accountId,
        );
        if (selectedAccountDetails == null) {
          print(
            "AccountProvider: Selected account $accountId not found in local list.",
          );
          _periodEndBalance = 0.0;
          _isAccountCreatedByPeriodEnd = false;
        } else {
          final DateTime accountCreatedAt = selectedAccountDetails.createdAt;
          final DateTime normalizedEndDate = DateTime(
            endDate.year,
            endDate.month,
            endDate.day,
          );
          final DateTime normalizedCreatedAt = DateTime(
            accountCreatedAt.year,
            accountCreatedAt.month,
            accountCreatedAt.day,
          );

          if (normalizedEndDate.isBefore(normalizedCreatedAt)) {
            _isAccountCreatedByPeriodEnd = false;
            _periodEndBalance = 0.0;
            print(
              "AccountProvider: Account $accountId NOT YET CREATED by $endDate.",
            );
          } else {
            _isAccountCreatedByPeriodEnd = true;
            _periodEndBalance = await _dbService.getAccountBalanceAtDate(
              accountId,
              endDate,
            );
            print(
              "AccountProvider: Fetched period-end balance for $accountId at $endDate: $_periodEndBalance",
            );
          }
        }
      }
    } catch (e) {
      print("Error fetching period-end balance (Provider): $e");
      _periodEndBalance = null;
      _isAccountCreatedByPeriodEnd = true;
    } finally {
      _isPeriodEndBalanceLoading = false;
      notifyListeners();
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
