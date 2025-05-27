import 'package:finance_tracker/data/category_class.dart';
import 'package:finance_tracker/data/transactions_class.dart';

abstract class ListItem {}

class DateSeparatorItem implements ListItem {
  final DateTime date;
  DateSeparatorItem(this.date);
}

class TransactionItem implements ListItem {
  final Transactions transaction;
  final String accountName;
  final Category? categoryForDisplay;
  TransactionItem(this.transaction, this.accountName, this.categoryForDisplay);
}
