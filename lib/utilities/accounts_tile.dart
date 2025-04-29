import 'package:finance_tracker/data/accounts_class.dart';
import 'package:finance_tracker/data/recurring_transactions_class.dart';
import 'package:flutter/material.dart';

class AccountsTile extends StatelessWidget {
  final Account accountData;
  final double currentBalance;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const AccountsTile({
    super.key,
    required this.accountData,
    required this.currentBalance,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme =
        Theme.of(context).textTheme;
    final colorScheme =
        Theme.of(context).colorScheme;

    String subtitleText =
        'Balance: \$${currentBalance.toStringAsFixed(2)}';
    if (accountData.interestRate > 0.0 && accountData.interestPeriod != null) {
      subtitleText +=
          '\nInterest: ${accountData.interestRate.toStringAsFixed(1)}%';
      subtitleText += '\nInterest Credited: ${accountData.interestPeriod![0].toUpperCase() + accountData.interestPeriod!.substring(1)}';
    }

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 12.0,
        vertical: 6.0,
      ),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius:
              BorderRadius.circular(8),
        ),
        child: ListTile(
          contentPadding:
              const EdgeInsets.symmetric(
                vertical: 8.0,
                horizontal: 16.0,
              ),
          title: Text(
            accountData.name,
            style: textTheme.titleMedium
                ?.copyWith(
                  fontWeight:
                      FontWeight.w600,
                ),
          ),
          subtitle: Column(
            // Use a Column in the subtitle to stack info
            crossAxisAlignment:
                CrossAxisAlignment.start,
            mainAxisSize:
                MainAxisSize
                    .min, // Keep column height minimal
            children: [
              // Display balance and interest info
              Text(
                subtitleText,
                style: textTheme.bodyMedium
                    ?.copyWith(
                      color: colorScheme
                          .onSurface
                          .withAlpha(200),
                    ),
              ),
            ],
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (onEdit != null)
                IconButton(
                  icon: Icon(
                    Icons.edit,
                    size: 20,
                    color:
                        colorScheme
                            .secondary,
                  ),
                  tooltip: 'Edit Account',
                  onPressed: onEdit,
                ),
              if (onDelete != null)
                IconButton(
                  icon: Icon(
                    Icons.delete_outline,
                    size: 20,
                    color: colorScheme.error,
                  ),
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
