import 'package:finance_tracker/data/category_class.dart';
import 'package:finance_tracker/data/recurring_transactions_class.dart';

abstract class RecurringTransactionsListItem {}

class SeparatorItem implements RecurringTransactionsListItem {
  final String separatorName; // e.g., "Interest", "Custom Rules"
  SeparatorItem(this.separatorName);
}

class RecurringTransactionItem implements RecurringTransactionsListItem {
  final RecurringTransaction recurringTransactionData; // Renamed for clarity
  final String accountName;
  final Category categoryForDisplay; // Renamed for clarity
  final String? transferToAccountName; // For transfer rules

  RecurringTransactionItem({
    // Using named parameters for better readability
    required this.recurringTransactionData,
    required this.accountName,
    required this.categoryForDisplay,
    this.transferToAccountName,
  });
}
