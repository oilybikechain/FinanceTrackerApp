import 'package:finance_tracker/data/accounts_class.dart';
import 'package:finance_tracker/data/recurring_transactions_class.dart';
import 'package:flutter/material.dart';

class AccountsTile extends StatelessWidget {
  final Account accountData;
  final double currentBalance;
  // --- Add parameter for associated recurring transactions ---
  final List<RecurringTransaction>? associatedRecurringTransactions;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const AccountsTile({
    super.key,
    required this.accountData,
    required this.currentBalance,
    this.associatedRecurringTransactions, // Make it optional
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    String subtitleText = 'Balance: \$${currentBalance.toStringAsFixed(2)}';
    if (accountData.interestRate > 0.0) {
      subtitleText += '\nInterest: ${accountData.interestRate.toStringAsFixed(1)}%';
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
          title: Text(
            accountData.name,
            style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          subtitle: Column( // Use a Column in the subtitle to stack info
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min, // Keep column height minimal
            children: [
              // Display balance and interest info
              Text(
                subtitleText,
                style: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurface.withAlpha(200)),
              ),
              // --- Conditionally display recurring transactions ---
              if (associatedRecurringTransactions != null && associatedRecurringTransactions!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 4.0), // Add some space
                  child: Column( // Nested column for recurring items
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                          Text( // Header for recurring section
                            "Recurring:",
                            style: textTheme.labelMedium?.copyWith(fontWeight: FontWeight.bold, color: colorScheme.secondary),
                          ),
                          // Generate a Text widget for each recurring transaction description
                          ...associatedRecurringTransactions!.map((rt) => Text(
                                "- ${rt.description ?? rt.type.name} (\$${rt.amount.toStringAsFixed(2)})", // Show description or type, and amount
                                style: textTheme.bodySmall?.copyWith(color: colorScheme.onSurface.withAlpha(180)),
                                overflow: TextOverflow.ellipsis, // Prevent long text overflow
                              )).toList(), // Convert map result to list of widgets
                      ],
                  ),
                ),
              // --- ---
            ],
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (onEdit != null)
                IconButton(
                  icon: Icon(Icons.edit, size: 20, color: colorScheme.secondary),
                  tooltip: 'Edit Account',
                  onPressed: onEdit,
                ),
              if (onDelete != null)
                IconButton(
                  icon: Icon(Icons.delete_outline, size: 20, color: colorScheme.error),
                  tooltip: 'Delete Account',
                  onPressed: onDelete,
                ),
            ],
          ),
        ),
      ),
    );
  }
}