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
    // No need to notify for loading start here if the caller (HomePage) manages overall page loading.
    // If this method could be called independently and UI should react to its specific loading, then notify.

    await fetchRecurringTransactions(); // Fetch fresh rules

    bool transactionsWereProcessed = false; // Track if any DB change happened
    List<RecurringTransaction> rulesToUpdate = [];

    final DateTime today = DateTime(
      currentDate.year,
      currentDate.month,
      currentDate.day,
    );

    for (var rule in List.from(_recurringTransactions)) {
      if (rule.isInterestRule || rule.isSystemGenerated) {
        continue;
      }

      DateTime nextDue = DateTime(
        rule.nextDueDate.year,
        rule.nextDueDate.month,
        rule.nextDueDate.day,
      );
      bool ruleAdvancedInThisCycle = false;

      while (!nextDue.isAfter(today)) {
        if (rule.endDate != null && nextDue.isAfter(rule.endDate!)) {
          print(
            "Recurring rule ID ${rule.id} ('${rule.description}') has passed end date. Stopping.",
          );
          break;
        }

        print(
          "Processing rule ID ${rule.id}: ${rule.description} due on $nextDue",
        );
        bool currentIterationSuccess = false;

        if (rule.type == RecurringTransactionType.transfer) {
          if (rule.transferToAccountId == null) {
            print(
              "Skipping transfer rule ID ${rule.id} (missing transferToAccountId).",
            );
          } else {
            currentIterationSuccess = await _dbService.insertTransfer(
              fromAccountId: rule.accountId,
              toAccountId: rule.transferToAccountId!,
              amount: rule.amount.abs(),
              timestamp: nextDue,
              description: rule.description ?? "Recurring Transfer",
              // Use category from rule, ensuring it's the "Transfer" category when rule is created
              transferCategoryId: rule.categoryId,
            );
            if (currentIterationSuccess) {
              print(
                "Recurring Transfer processed successfully for rule ID ${rule.id}.",
              );
              transactionsWereProcessed = true;
            } else {
              print(
                "Failed to process recurring Transfer for rule ID ${rule.id}.",
              );
            }
          }
        } else {
          // Income or Expense
          final newTransaction = Transactions(
            accountId: rule.accountId,
            type:
                rule.type == RecurringTransactionType.income
                    ? TransactionType.income
                    : TransactionType.expense,
            amount:
                rule.type == RecurringTransactionType.income
                    ? rule.amount.abs()
                    : -rule.amount.abs(),
            timestamp: nextDue,
            description: rule.description,
            categoryId: rule.categoryId,
          );
          // --- DIRECTLY INSERT into DB ---
          int newTxId = await _dbService.insertTransaction(newTransaction);
          if (newTxId > 0) {
            print(
              "Recurring Income/Expense processed successfully for rule ID ${rule.id}. Tx ID: $newTxId",
            );
            currentIterationSuccess = true;
            transactionsWereProcessed = true;
          } else {
            print(
              "Failed to process recurring Income/Expense for rule ID ${rule.id}.",
            );
          }
          // --- ---
        }

        // Advance nextDue only if successful or if it was a skippable structural issue
        if (currentIterationSuccess ||
            (rule.type == RecurringTransactionType.transfer &&
                rule.transferToAccountId == null)) {
          nextDue = _calculateNextDueDate(nextDue, rule.frequency);
          ruleAdvancedInThisCycle = true;
        } else {
          // If a DB insert failed for a valid rule, we might want to stop processing this rule
          // for this run to avoid hammering DB or creating inconsistent nextDue dates.
          // Or, log and advance to prevent infinite loop on next app start.
          print(
            "DB operation failed for rule ${rule.id}. Advancing due date to prevent loop.",
          );
          nextDue = _calculateNextDueDate(
            nextDue,
            rule.frequency,
          ); // Advance to avoid infinite loop
          ruleAdvancedInThisCycle = true; // Mark as advanced for this cycle
          // Break from WHILE loop for this rule in this run?
          // break;
        }
      } // End while

      if (ruleAdvancedInThisCycle && nextDue != rule.nextDueDate) {
        // Check if nextDue actually changed
        if (rule.endDate == null || !nextDue.isAfter(rule.endDate!)) {
          rulesToUpdate.add(rule.copyWith(nextDueDate: nextDue));
        } else {
          print(
            "Recurring rule ID ${rule.id} reached end date. New due date $nextDue not saved.",
          );
        }
      }
    } // End for

    for (var ruleToUpdate in rulesToUpdate) {
      await _dbService.updateRecurringTransaction(ruleToUpdate);
    }

    if (rulesToUpdate.isNotEmpty) {
      // If rules were updated, their list in provider changed
      await fetchRecurringTransactions(); // Refreshes _recurringTransactions and notifies
    } else if (transactionsWereProcessed && !rulesToUpdate.isNotEmpty) {
      // If transactions were processed but no rules needed their nextDueDate updated
      // (e.g. a one-time rule that's now past its end date),
      // we still might want to notify if _isLoading was the only change.
      // However, fetchRecurringTransactions() above or the final notify in the caller's
      // sequence should cover UI refresh for the transaction list itself.
    }

    _setLoading(
      false,
    ); // Set loading false if it was set true at the start of this method
    return transactionsWereProcessed; // Return true if any DB write occurred
  }

  Future<bool> addInterestRecurringRuleForAccount(Account account) async {
    if (account.id == null ||
        account.interestRate <= 0 ||
        account.interestPeriod == null) {
      print(
        "Cannot create interest rule: Account ID null, rate <= 0, or period null.",
      );
      return false;
    }

    Frequency interestFrequency;
    switch (account.interestPeriod?.toLowerCase()) {
      case 'daily':
        interestFrequency = Frequency.daily;
        break;
      case 'monthly':
        interestFrequency = Frequency.monthly;
        break;
      case 'yearly':
        interestFrequency = Frequency.yearly;
        break;
      default:
        print("Invalid interest period: ${account.interestPeriod}");
        return false;
    }

    DateTime startDate = account.createdAt.toLocal();
    DateTime nextDueDate = _calculateNextDueDate(startDate, interestFrequency);

    final interestRule = RecurringTransaction(
      accountId: account.id!,
      type: RecurringTransactionType.income, // Interest is income
      // Store the ANNUAL rate in the amount field for this system rule.
      // The processing logic will divide it by frequency.
      amount: account.interestRate,
      description: "Interest for ${account.name}",
      frequency: interestFrequency,
      startDate: startDate,
      nextDueDate:
          nextDueDate, // First interest payment will be after one period
      categoryId: 3, // Specific category for interest
      isInterestRule: true, // Mark as an interest rule
      isSystemGenerated: true, // Mark as system-generated
    );

    return await addRecurringTransaction(
      interestRule,
    ); // Use existing add method
  }

  Future<bool> processDueInterestTransactions(DateTime currentDate) async {
    _setLoading(true); // Indicate processing
    // It's often good to fetch fresh rules, especially if other processes might change them.
    // If called immediately after processDueRecurringTransactions, this might be redundant
    // if that method also calls fetchRecurringTransactions().
    // await fetchRecurringTransactions();

    bool anyInterestTransactionCreated = false;
    List<RecurringTransaction> interestRulesToUpdate = [];
    final DateTime today = DateTime(
      currentDate.year,
      currentDate.month,
      currentDate.day,
    );

    // Iterate on a copy in case fetchRecurringTransactions is called inside loop by another async path
    for (var rule in List.from(_recurringTransactions)) {
      if (!rule.isInterestRule) {
        // Only process rules marked as interest rules
        continue;
      }

      // Normalize nextDueDate to compare with 'today' (ignoring time)
      DateTime nextDue = DateTime(
        rule.nextDueDate.year,
        rule.nextDueDate.month,
        rule.nextDueDate.day,
      );
      bool ruleAdvancedThisCycle =
          false; // Track if nextDueDate changed for this rule in this run

      // Loop while the rule is due (on or before today)
      while (!nextDue.isAfter(today)) {
        // Check for end date
        if (rule.endDate != null && nextDue.isAfter(rule.endDate!)) {
          print(
            "Interest rule ID ${rule.id} for account ${rule.accountId} has passed its end date ($rule.endDate). Stopping.",
          );
          break; // Stop processing this rule for future dates
        }

        print(
          "Processing interest rule ID ${rule.id} for account ${rule.accountId}, due on $nextDue",
        );

        // 1. Determine the period for which interest is being calculated.
        //    The balance should be taken from the *start* of this interest period,
        //    which is effectively the *previous* due date (or account creation/rule start date).
        DateTime interestPeriodStartDate = today;
        // To find the start of the *current* interest period, we go back one period from `nextDue`.
        // This requires a robust way to subtract a period.
        Jiffy jiffyNextDue = Jiffy.parseFromDateTime(nextDue);
        switch (rule.frequency) {
          case Frequency.daily:
            interestPeriodStartDate = jiffyNextDue.subtract(days: 1).dateTime;
            break;
          case Frequency.weekly:
            interestPeriodStartDate = jiffyNextDue.subtract(weeks: 1).dateTime;
            break;
          case Frequency.monthly:
            interestPeriodStartDate = jiffyNextDue.subtract(months: 1).dateTime;
            break;
          case Frequency.yearly:
            interestPeriodStartDate = jiffyNextDue.subtract(years: 1).dateTime;
            break;
        }
        // Ensure interest period start is not before rule start date
        if (interestPeriodStartDate.isBefore(rule.startDate)) {
          interestPeriodStartDate = rule.startDate;
        }

        // 2. Fetch the account's balance at the END of the 'interestPeriodStartDate'
        //    (or effectively, just before the 'nextDue' date).
        //    For daily interest, this would be the balance at the end of the previous day.
        //    For monthly, balance at end of previous month (relative to due date).
        //    The date passed to getAccountBalanceAtDate should be the *last day of the period*
        //    for which interest is being calculated.
        DateTime balanceCalculationEndDate = nextDue.subtract(
          const Duration(days: 1),
        );
        // Ensure balance calculation end date is not before the rule's start date
        if (balanceCalculationEndDate.isBefore(rule.startDate)) {
          // This scenario means we are calculating interest for the very first period.
          // The balance to consider is effectively the initial balance if nextDue is the first due date
          // or balance at rule.startDate if it's a later start.
          // For simplicity, if balanceCalculationEndDate is before rule.startDate,
          // it implies an issue or the very first period calculation.
          // Let's assume getAccountBalanceAtDate handles startDate correctly with created_at.
          // A more precise balance for the *first* period might use initial balance
          // if nextDue is the first calculated due date from rule.startDate.
        }

        double accountBalanceForInterest = await _dbService
            .getAccountBalanceAtDate(rule.accountId, balanceCalculationEndDate);
        print(
          "Interest for Acc ${rule.accountId}: Balance on $balanceCalculationEndDate was \$${accountBalanceForInterest.toStringAsFixed(2)}",
        );

        // 3. Calculate the interest amount for this specific period
        // 'rule.amount' stores the ANNUAL interest rate as a percentage (e.g., 5 for 5%)
        double annualRateDecimal =
            rule.amount / 100.0; // Convert percentage e.g., 5% -> 0.05
        double interestAmountForThisPeriod = 0;

        switch (rule.frequency) {
          case Frequency.daily:
            // (Balance * AnnualRate) / DaysInYear
            // Consider leap years for more accuracy or use a fixed 365.25
            int daysInYear =
                Jiffy.parseFromDateTime(nextDue).isLeapYear ? 366 : 365;
            interestAmountForThisPeriod =
                (accountBalanceForInterest * annualRateDecimal) / daysInYear;
            break;
          case Frequency.weekly:
            interestAmountForThisPeriod =
                (accountBalanceForInterest * annualRateDecimal) /
                (365.25 / 7); // Average weeks
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

        // Round to 2 decimal places for currency
        interestAmountForThisPeriod =
            (interestAmountForThisPeriod * 100).roundToDouble() / 100.0;

        // Ensure interest isn't paid on negative balances (unless your bank does that!)
        if (accountBalanceForInterest < 0) {
          interestAmountForThisPeriod = 0;
        }

        bool currentIterationDbSuccess = false;
        if (interestAmountForThisPeriod > 0.001) {
          // Only create transaction if interest is earned (e.g., > 0.01 cent)
          final newInterestTransaction = Transactions(
            accountId: rule.accountId,
            type: TransactionType.income,
            amount: interestAmountForThisPeriod, // Positive amount
            timestamp: nextDue, // Interest credited on this due date
            description:
                rule.description ??
                "Interest Earned (${DateFormat('MMM yyyy').format(nextDue)})", // More descriptive
            categoryId: 3,
            // recurringTransactionId: rule.id, // Optional: link to the rule
          );
          int newTxId = await _dbService.insertTransaction(
            newInterestTransaction,
          );
          if (newTxId > 0) {
            currentIterationDbSuccess = true;
            anyInterestTransactionCreated = true; // Set the overall flag
            print(
              "Interest generated and saved for Acc ${rule.accountId}: \$${interestAmountForThisPeriod.toStringAsFixed(2)} on $nextDue",
            );

            // --- CRITICAL TODO: Update account's last_interest_credit_date ---
            // This needs a new method in DatabaseService and to be called here or after loop.
            // Example: await _dbService.updateAccountLastInterestCreditDate(rule.accountId, nextDue);
            // For now, this is a manual step you'd need to add. If not done, interest
            // might be calculated repeatedly for the same period if the rule's nextDueDate
            // isn't advanced past the last credit event.
            // --- ---
          } else {
            print(
              "Failed to save generated interest transaction for rule ID ${rule.id}.",
            );
          }
        } else {
          print(
            "No significant interest earned for Acc ${rule.accountId} for period ending $nextDue (Amount: $interestAmountForThisPeriod). Skipping transaction.",
          );
          currentIterationDbSuccess =
              true; // Considered "processed" for this due date even if no tx created
        }

        // Advance nextDueDate
        if (currentIterationDbSuccess) {
          // Advance if processed (even if $0 interest) or if DB save failed (to avoid loop)
          nextDue = _calculateNextDueDate(nextDue, rule.frequency);
          ruleAdvancedThisCycle = true;
        } else {
          // If DB insert specifically failed for a >0 interest amount.
          print(
            "DB save for interest transaction failed for rule ${rule.id}. Advancing due date to prevent loop.",
          );
          nextDue = _calculateNextDueDate(nextDue, rule.frequency);
          ruleAdvancedThisCycle =
              true; // Still advance to prevent infinite loop
          // break; // Optionally break from while loop for this rule if one instance fails.
        }
      } // end while for a single rule

      // If nextDue was updated for this rule, prepare to save it
      if (ruleAdvancedThisCycle && nextDue != rule.nextDueDate) {
        if (rule.endDate == null || !nextDue.isAfter(rule.endDate!)) {
          interestRulesToUpdate.add(rule.copyWith(nextDueDate: nextDue));
        } else {
          print(
            "Interest rule ID ${rule.id} for account ${rule.accountId} reached its end date. Not updating nextDueDate further.",
          );
          // Optionally: Delete or deactivate the rule here if it's past its end date.
          // await _dbService.deleteRecurringTransaction(rule.id!);
        }
      }
    } // end for loop over all rules

    // Batch update all recurring transaction rules that had their next_due_dates changed
    for (var ruleToUpdate in interestRulesToUpdate) {
      await _dbService.updateRecurringTransaction(ruleToUpdate);
    }

    // If rules were updated, their list in this provider has changed,
    // so refetch to update the local _recurringTransactions list and notify listeners.
    if (interestRulesToUpdate.isNotEmpty) {
      await fetchRecurringTransactions();
    }

    _setLoading(false);
    return anyInterestTransactionCreated; // Return true if any new interest transaction was actually CREATED
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
