import 'package:collection/collection.dart';
import 'package:finance_tracker/data/accounts_class.dart';
import 'package:finance_tracker/data/enums.dart';
import 'package:flutter/material.dart';
import 'package:finance_tracker/data/recurring_transactions_class.dart';
import 'package:finance_tracker/services/database_service.dart';
import 'package:intl/intl.dart';
import 'package:jiffy/jiffy.dart';
import 'package:finance_tracker/data/enums.dart';
import 'package:finance_tracker/data/transactions_class.dart';

class RecurringTransactionsProvider with ChangeNotifier {
  final DatabaseService _dbService = DatabaseService();

  // --- State Variables ---
  List<RecurringTransaction> _recurringTransactions = [];
  bool _isLoading = false;

  // --- Public Getters ---
  List<RecurringTransaction> get recurringTransactions =>
      _recurringTransactions;
  bool get isLoading => _isLoading;

  // --- Public Methods (Actions) ---

  // Fetch all recurring transaction rules
  Future<void> fetchRecurringTransactions() async {
    _setLoading(true);

    try {
      _recurringTransactions = await _dbService.getAllRecurringTransactions();
      _setLoading(false);
    } catch (e) {
      print("Error fetching recurring transactions: $e");
      _recurringTransactions = [];
      _setLoading(false);
    }
  }

  // Add a new recurring transaction rule
  Future<bool> addRecurringTransaction(RecurringTransaction recurring) async {
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
      // _setLoading(false);
      return false; // Failure
    }
  }

  // Update an existing recurring transaction rule
  Future<bool> updateRecurringTransaction(
    RecurringTransaction recurring,
  ) async {
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
      // _setLoading(false);
      return false; // Failure
    }
  }

  // Delete a recurring transaction rule
  Future<bool> deleteRecurringTransaction(int id) async {
    // _setLoading(true); // Optional

    try {
      await _dbService.deleteRecurringTransaction(id);
      _recurringTransactions.removeWhere((r) => r.id == id);
      notifyListeners();
      // _setLoading(false);
      return true; // Success
    } catch (e) {
      print("Error deleting recurring transaction: $e");
      // _setLoading(false);
      return false; // Failure
    }
  }

  DateTime _calculateNextDueDate(DateTime currentDueDate, Frequency frequency) {
    Jiffy currentJiffy = Jiffy.parseFromDateTime(currentDueDate);
    switch (frequency) {
      case Frequency.daily:
        return currentJiffy.add(days: 1).dateTime;
      case Frequency.weekly:
        return currentJiffy.add(weeks: 1).dateTime;
      case Frequency.monthly:
        return currentJiffy.add(months: 1).dateTime;
      case Frequency.yearly:
        return currentJiffy.add(years: 1).dateTime;
    }
  }

  Future<bool> processDueRecurringTransactions(DateTime currentDate) async {
    _setLoading(true);
    await fetchRecurringTransactions(); // Get the latest set of rules

    bool transactionsWereProcessedThisRun = false;
    List<RecurringTransaction> rulesToUpdateInDb = [];

    // Normalize currentDate to the beginning of the day for comparison
    final DateTime today = DateTime(
      currentDate.year,
      currentDate.month,
      currentDate.day,
    );

    for (var rule in List.from(_recurringTransactions)) {
      // Iterate on a copy
      // Skip interest rules; they are handled by a separate method
      if (rule.isInterestRule) {
        // Also skipping systemGenerated just in case, though interest rules are system.
        continue;
      }

      // Normalize nextDueDate from the rule to the beginning of its day
      DateTime currentRuleNextDue = DateTime(
        rule.nextDueDate.year,
        rule.nextDueDate.month,
        rule.nextDueDate.day,
      );
      bool ruleAdvancedThisCycle =
          false; // Tracks if this rule's nextDueDate has been changed in the while loop

      // Loop as long as the rule's next due date is on or before 'today'
      while (!currentRuleNextDue.isAfter(today)) {
        // Check if the rule has an end date and if the current due date has passed it
        if (rule.endDate != null && currentRuleNextDue.isAfter(rule.endDate!)) {
          print(
            "Recurring rule ID ${rule.id} ('${rule.description}') has passed its end date (${rule.endDate}). Stopping processing for this rule.",
          );
          // No need to update nextDueDate further if it's past the end date
          ruleAdvancedThisCycle =
              true; // Mark as advanced to prevent adding to rulesToUpdate with old date
          break; // Exit while loop for this rule
        }

        print(
          "Processing non-interest rule ID ${rule.id}: '${rule.description}' due on $currentRuleNextDue",
        );
        bool currentIterationDbSuccess = false;

        if (rule.type == TransactionType.transfer) {
          if (rule.transferToAccountId == null) {
            print(
              "Skipping transfer rule ID ${rule.id} (missing transferToAccountId).",
            );
            // Still advance due date to prevent infinite loop on this invalid rule
          } else {
            currentIterationDbSuccess = await _dbService.insertTransfer(
              fromAccountId: rule.accountId,
              toAccountId: rule.transferToAccountId!,
              amount: rule.amount.abs(),
              timestamp: currentRuleNextDue,
              description: rule.description ?? "Recurring Transfer",
              transferCategoryId: rule.categoryId,
              recurringTransactionID: rule.id,
            );
            if (currentIterationDbSuccess)
              transactionsWereProcessedThisRun = true;
          }
        } else {
          // Income or Expense
          final newTransaction = Transactions(
            accountId: rule.accountId,
            type:
                rule.type == TransactionType.income
                    ? TransactionType.income
                    : TransactionType.expense,
            amount:
                rule.type == TransactionType.income
                    ? rule.amount.abs()
                    : -rule.amount.abs(),
            timestamp:
                currentRuleNextDue, // Transaction happens ON the due date (start of day)
            description: rule.description,
            categoryId: rule.categoryId,
            recurringTransactionId: rule.id,
          );
          int newTxId = await _dbService.insertTransaction(newTransaction);
          if (newTxId > 0) {
            currentIterationDbSuccess = true;
            transactionsWereProcessedThisRun = true;
          }
        }

        if (currentIterationDbSuccess ||
            (rule.type == TransactionType.transfer &&
                rule.transferToAccountId == null)) {
          // If successful, or skippable issue, advance the due date
          currentRuleNextDue = _calculateNextDueDate(
            currentRuleNextDue,
            rule.frequency,
          );
          ruleAdvancedThisCycle = true;
        } else {
          // DB operation failed for a valid rule. Log, advance to prevent infinite loop, and potentially break for this rule.
          print(
            "DB operation failed for rule ${rule.id} for due date. Advancing due date to prevent loop.",
          );
          currentRuleNextDue = _calculateNextDueDate(
            currentRuleNextDue,
            rule.frequency,
          );
          ruleAdvancedThisCycle = true;
          // break; // Optional: stop processing this rule for this run if one instance fails
        }
      } // End while loop (processing multiple occurrences of a single rule if overdue)

      // If the rule's nextDueDate was advanced in this cycle, add it for DB update
      if (ruleAdvancedThisCycle && currentRuleNextDue != rule.nextDueDate) {
        // Final check: ensure new nextDueDate is not past a potential endDate
        if (rule.endDate == null ||
            !currentRuleNextDue.isAfter(rule.endDate!)) {
          rulesToUpdateInDb.add(rule.copyWith(nextDueDate: currentRuleNextDue));
        } else {
          print(
            "Recurring rule ID ${rule.id} ('${rule.description}') reached end date after processing. New nextDueDate $currentRuleNextDue not saved beyond endDate.",
          );
          // Optionally, you could also add logic here to delete or deactivate the rule if it's truly finished.
        }
      }
    } // End for loop over all rules

    // Batch update recurring transaction rules in the database
    for (var ruleToUpdate in rulesToUpdateInDb) {
      await _dbService.updateRecurringTransaction(ruleToUpdate);
    }

    // If rules were updated OR transactions were processed, the local list needs refreshing.
    // The 'transactionsWereProcessedThisRun' flag indicates if the main transaction list (managed by TransactionsProvider)
    // is now stale and needs a full refresh by the caller (e.g., HomePage).
    if (rulesToUpdateInDb.isNotEmpty) {
      await fetchRecurringTransactions(); // Refreshes this provider's list and notifies its listeners.
    }

    _setLoading(false);
    return transactionsWereProcessedThisRun;
  }

  Future<bool> processDueInterestTransactions(DateTime currentDate) async {
    _setLoading(true);
    // Fetch fresh rules. If this is called after processDueRecurringTransactions,
    // and that method calls fetchRecurringTransactions, this might be redundant.
    // However, for standalone calls or robustness, it's good.
    await fetchRecurringTransactions();

    bool anyInterestTransactionCreated = false;
    List<RecurringTransaction> interestRulesToUpdate = [];

    // 'currentDate' is the reference for "today". We care about the end of this day.
    final DateTime endOfCurrentProcessingDay = DateTime(
      currentDate.year,
      currentDate.month,
      currentDate.day,
      23,
      59,
      59,
      999,
    );

    for (var rule in List.from(_recurringTransactions)) {
      if (!rule.isInterestRule) continue;

      // 'nextDueDate' from the rule is the *date* on which interest should be credited.
      // We normalize it to the start of that day for comparison.
      DateTime ruleNextDueDateNormalized = DateTime(
        rule.nextDueDate.year,
        rule.nextDueDate.month,
        rule.nextDueDate.day,
      );
      bool ruleAdvancedThisCycle = false;

      // Loop while the rule's next due date (start of day) is on or before 'today' (start of day)
      while (!ruleNextDueDateNormalized.isAfter(
        DateTime(currentDate.year, currentDate.month, currentDate.day),
      )) {
        // The specific DateTime when interest is credited and balance is taken
        DateTime interestCreditTimestamp = DateTime(
          ruleNextDueDateNormalized.year,
          ruleNextDueDateNormalized.month,
          ruleNextDueDateNormalized.day,
          23,
          59,
          59,
          999, // End of the due day
        );

        // Check against rule's end date
        if (rule.endDate != null &&
            ruleNextDueDateNormalized.isAfter(rule.endDate!)) {
          print(
            "Interest rule ID ${rule.id} (Acc ${rule.accountId}) passed end date (${rule.endDate}). Stopping.",
          );
          ruleAdvancedThisCycle =
              true; // To ensure it's considered for update if nextDueDate changed
          break;
        }

        print(
          "Processing interest rule ID ${rule.id} for account ${rule.accountId}, due on $ruleNextDueDateNormalized (credit at $interestCreditTimestamp)",
        );

        // 1. Balance Calculation: Use the 'interestCreditTimestamp'
        //    getAccountBalanceAtDate will sum transactions <= interestCreditTimestamp.
        //    This balance is *before* the current interest is added.
        double
        accountBalanceForInterest = await _dbService.getAccountBalanceAtDate(
          rule.accountId,
          interestCreditTimestamp, // Balance at the end of the due day, before this interest
        );
        print(
          "Interest for Acc ${rule.accountId}: Balance at $interestCreditTimestamp was \$${accountBalanceForInterest.toStringAsFixed(2)}",
        );

        // 2. Calculate Interest Amount (annual rate stored in rule.amount)
        double annualRateDecimal = rule.amount / 100.0;
        double interestAmountForThisPeriod = 0;
        // ... (Your switch (rule.frequency) to calculate interestAmountForThisPeriod) ...
        // This calculation should use 'accountBalanceForInterest'
        switch (rule.frequency) {
          case Frequency.daily:
            int daysInYear =
                Jiffy.parseFromDateTime(interestCreditTimestamp).isLeapYear
                    ? 366
                    : 365;
            interestAmountForThisPeriod =
                (accountBalanceForInterest * annualRateDecimal) / daysInYear;
            break;
          case Frequency.weekly:
            interestAmountForThisPeriod =
                (accountBalanceForInterest * annualRateDecimal) / (365.25 / 7);
            break;
          case Frequency.monthly:
            interestAmountForThisPeriod =
                (accountBalanceForInterest * annualRateDecimal) / 12.0;
            break;
          case Frequency.yearly:
            interestAmountForThisPeriod =
                accountBalanceForInterest * annualRateDecimal;
            break;
        }
        interestAmountForThisPeriod =
            (interestAmountForThisPeriod * 100).roundToDouble() / 100.0;
        if (accountBalanceForInterest < 0 && interestAmountForThisPeriod > 0) {
          // Typically no interest on negative balance, or banks might charge interest (which would be an expense rule)
          interestAmountForThisPeriod = 0;
        }

        bool currentIterationDbSuccess = false;
        if (interestAmountForThisPeriod > 0.001) {
          final newInterestTransaction = Transactions(
            accountId: rule.accountId,
            type: TransactionType.income, // Ensure this is correct
            amount: interestAmountForThisPeriod,
            timestamp:
                interestCreditTimestamp, // <<< Use the end-of-day timestamp
            description:
                rule.description ??
                "Interest Earned (${DateFormat('dd MMM yyyy').format(ruleNextDueDateNormalized)})",
            categoryId: 3,
            recurringTransactionId: rule.id,
          );
          int newTxId = await _dbService.insertTransaction(
            newInterestTransaction,
          );
          if (newTxId > 0) {
            currentIterationDbSuccess =
                true; // DB insert of transaction was successful
            anyInterestTransactionCreated = true;
            print(
              "Interest generated and saved for Acc ${rule.accountId}: \$${interestAmountForThisPeriod.toStringAsFixed(2)} on $interestCreditTimestamp",
            );

            // --- UPDATE Account's lastInterestCreditDate in DB ---
            int accountUpdateSuccess = await _dbService
                .updateAccountLastInterestCreditDate(
                  rule.accountId,
                  ruleNextDueDateNormalized, // Store the DATE part
                );
            if (accountUpdateSuccess > 0) {
              print(
                "Successfully updated lastInterestCreditDate for account ${rule.accountId} to $ruleNextDueDateNormalized",
              );
            } else {
              print(
                "ERROR: Failed to update lastInterestCreditDate for account ${rule.accountId}",
              );
              currentIterationDbSuccess =
                  false; // Consider this a failure if account update fails
            }
            // --- ---
          } else {
            print(
              "Failed to save generated interest transaction for rule ID ${rule.id}.",
            );
            currentIterationDbSuccess = false;
          }
        } else {
          print(
            "No significant interest for Acc ${rule.accountId} for period ending $ruleNextDueDateNormalized (Amount: $interestAmountForThisPeriod).",
          );
          currentIterationDbSuccess =
              true; // Consider "processed" for this due date
        }

        if (currentIterationDbSuccess) {
          ruleNextDueDateNormalized = _calculateNextDueDate(
            ruleNextDueDateNormalized,
            rule.frequency,
          );
          ruleAdvancedThisCycle = true;
        } else {
          print(
            "DB operation failed for interest rule ${rule.id}. Advancing due date to prevent loop.",
          );
          ruleNextDueDateNormalized = _calculateNextDueDate(
            ruleNextDueDateNormalized,
            rule.frequency,
          );
          ruleAdvancedThisCycle = true;
          // break; // Optional: Stop processing this specific rule for this run if a critical part failed
        }
      } // End while

      if (ruleAdvancedThisCycle &&
          ruleNextDueDateNormalized != rule.nextDueDate) {
        if (rule.endDate == null ||
            !ruleNextDueDateNormalized.isAfter(rule.endDate!)) {
          interestRulesToUpdate.add(
            rule.copyWith(nextDueDate: ruleNextDueDateNormalized),
          );
        } else {
          print(
            "Interest rule ID ${rule.id} (Acc ${rule.accountId}) reached end date. Not updating further.",
          );
        }
      }
    } // End for

    for (var ruleToUpdate in interestRulesToUpdate) {
      await _dbService.updateRecurringTransaction(ruleToUpdate);
    }

    if (interestRulesToUpdate.isNotEmpty || anyInterestTransactionCreated) {
      // If rules were updated or interest transactions were created,
      // refetching rules is good for this provider's state.
      // The main transactions list will be refreshed by HomePage.
      await fetchRecurringTransactions();
    }

    _setLoading(false);
    return anyInterestTransactionCreated;
  }

  Future<RecurringTransaction?> _findExistingInterestRule(int accountId) async {
    await fetchRecurringTransactions();
    return _recurringTransactions.firstWhereOrNull(
      (rule) => rule.accountId == accountId && rule.isInterestRule == true,
    );
  }

  Future<bool> setupOrUpdateInterestRecurringRule(Account account) async {
    if (_recurringTransactions.isEmpty && !_isLoading) {
      await fetchRecurringTransactions();
    }

    final existingRule = await _findExistingInterestRule(account.id!);

    // Case 1: Account has interest, and a rule needs to be created or updated
    if (account.interestRate > 0 && account.interestPeriod != null) {
      Frequency interestFrequency = account.interestPeriod!;

      DateTime ruleStartDate = account.createdAt.toLocal();
      DateTime nextDueDate = account.nextInterestCreditDate!;

      if (existingRule != null) {
        print("Updating existing interest rule for account ${account.id}");
        final updatedRule = existingRule.copyWith(
          amount: account.interestRate,
          frequency: interestFrequency,
          description: "Interest for ${account.name}",
          startDate: ruleStartDate,
          nextDueDate: nextDueDate,
          // categoryId will be INTEREST_CATEGORY_ID, isInterestRule=true, isSystemGenerated=true
        );
        return await updateRecurringTransaction(updatedRule);
      } else {
        // --- Create new interest rule ---
        print("Creating new interest rule for account ${account.id}");
        final newInterestRule = RecurringTransaction(
          accountId: account.id!,
          type:
              TransactionType
                  .income, // Interest is effectively income for the rule template
          amount: account.interestRate, // Store annual rate
          description: "Interest for ${account.name}",
          frequency: interestFrequency,
          startDate: ruleStartDate,
          nextDueDate: nextDueDate,
          categoryId: 3,
          isInterestRule: true,
          isSystemGenerated: true, // System manages this rule
        );
        return await addRecurringTransaction(newInterestRule);
      }
    } else {
      if (existingRule != null) {
        print(
          "Account ${account.id} no longer has interest. Deleting existing interest rule ID ${existingRule.id}.",
        );
        return await deleteRecurringTransaction(existingRule.id!);
      }
      return true;
    }
  }

  // --- Private Helper Methods ---
  void _setLoading(bool loading) {
    if (_isLoading == loading) return;
    _isLoading = loading;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });
  }
}
