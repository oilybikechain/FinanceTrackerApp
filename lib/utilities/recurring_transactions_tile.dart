import 'package:finance_tracker/data/category_class.dart';
import 'package:finance_tracker/data/enums.dart';
import 'package:finance_tracker/data/recurring_transactions_class.dart';
import 'package:finance_tracker/utilities/category_chip.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart';

class RecurringTransactionsTile extends StatelessWidget {
  final RecurringTransaction recurringTransactionData;
  final VoidCallback onEdit;
  final Function(RecurringTransaction) onDelete;
  final String accountName;
  final Category categoryTag;
  final String? transferToAccountName;

  const RecurringTransactionsTile({
    super.key,
    required this.recurringTransactionData,
    required this.onEdit,
    required this.onDelete,
    required this.accountName,
    required this.categoryTag,
    this.transferToAccountName,
  });

  @override
  Widget build(BuildContext context) {
    bool _isInterestMode = recurringTransactionData.isInterestRule;
    String amountText = "nill";
    Color amountColor = Colors.black;
    String endDate = '';
    String accountText = '';
    final String startDate = DateFormat(
      'dd MMM yyyy',
    ).format(recurringTransactionData.startDate.toLocal());
    if (recurringTransactionData.endDate != null) {
      final endDate = DateFormat(
        'dd MMM yyyy',
      ).format(recurringTransactionData.endDate!.toLocal());
    }
    final String nextDueDate = DateFormat(
      'dd MMM yyyy',
    ).format(recurringTransactionData.nextDueDate.toLocal());

    if (_isInterestMode) {
      amountText =
          amountText =
              '${recurringTransactionData.amount.abs().toStringAsFixed(2)} %';
      amountColor = Theme.of(context).colorScheme.onSurface;
    } else if (recurringTransactionData.type == TransactionType.income) {
      amountText =
          '+\$${recurringTransactionData.amount.abs().toStringAsFixed(2)}';
      amountColor = Colors.green;
    } else if (recurringTransactionData.type == TransactionType.expense) {
      amountText =
          '-\$${recurringTransactionData.amount.abs().toStringAsFixed(2)}';
      amountColor = const Color.fromARGB(255, 255, 69, 69);
    } else if (recurringTransactionData.type == TransactionType.transfer) {
      amountText = '\$ ${recurringTransactionData.amount}';
      amountColor = Theme.of(context).colorScheme.onSurface;
    }

    if (_isInterestMode) {
      accountText = '';
    } else if (recurringTransactionData.type == TransactionType.transfer) {
      accountText = "${accountName} → ${transferToAccountName}";
    } else {
      accountText = accountName;
    }

    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(),
      child: Card(
        elevation: 0,
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 16, horizontal: 20),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.max,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    amountText,
                    style: Theme.of(
                      context,
                    ).textTheme.titleLarge!.copyWith(color: amountColor),
                    textAlign: TextAlign.left,
                  ),

                  Text(
                    recurringTransactionData.description!,
                    style: Theme.of(context).textTheme.titleLarge,
                    textAlign: TextAlign.left,
                  ),

                  Text(recurringTransactionData.amount.toString()),

                  SizedBox(height: 6),

                  _isInterestMode
                      ? SizedBox.shrink()
                      : Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            accountText,
                            style: Theme.of(context).textTheme.titleLarge,
                            textAlign: TextAlign.left,
                          ),
                          SizedBox(width: 5),
                          CategoryChip(
                            category: categoryTag,
                            isSelected: false,
                            onSelected: (nill) {},
                          ),
                        ],
                      ),

                  Text(
                    "Frequency: ${recurringTransactionData.frequency.name[0].toUpperCase()}${recurringTransactionData.frequency.name.substring(1)}",
                    style: Theme.of(context).textTheme.labelLarge,
                  ),

                  Text(
                    "Next Due Date: $nextDueDate",
                    textAlign: TextAlign.left,
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                  _isInterestMode
                      ? SizedBox.shrink()
                      : Text(
                        "Start Date: $startDate",
                        textAlign: TextAlign.left,
                        style: Theme.of(context).textTheme.labelLarge,
                      ),

                  endDate != ""
                      ? Text(
                        "End Date: $endDate",
                        textAlign: TextAlign.left,
                        style: Theme.of(context).textTheme.labelLarge,
                      )
                      : SizedBox.shrink(),
                ],
              ),

              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize:
                    MainAxisSize.min, // Column takes minimum vertical space
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  if (recurringTransactionData.isSystemGenerated != true)
                    IconButton(
                      icon: Icon(Icons.edit, size: 20),
                      tooltip: 'Edit Account',
                      onPressed: onEdit,
                      color: colorScheme.secondary,
                    ),
                  if (recurringTransactionData.isSystemGenerated != true)
                    IconButton(
                      icon: Icon(Icons.delete_outline, size: 20),
                      tooltip: 'Delete Account',
                      onPressed: () {
                        onDelete(recurringTransactionData);
                      },
                      color: colorScheme.error,
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
