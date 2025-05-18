import 'package:finance_tracker/data/enums.dart';
import 'package:finance_tracker/data/transactions_class.dart';
import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:intl/intl.dart';

class TransactionsTile extends StatelessWidget {
  final Transactions transactionData;
  final VoidCallback onEdit;
  final Function(Transactions) onDelete;
  final String accountName;

  const TransactionsTile({
    super.key,
    required this.transactionData,
    required this.onEdit,
    required this.onDelete,
    required this.accountName,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    String amountText = "nill";
    Color amountColor = Colors.black;
    final String formattedDate = DateFormat(
      'dd MMM yyyy',
    ).format(transactionData.timestamp.toLocal()); // e.g., 25 Dec 2023
    final String formattedTime = DateFormat(
      'hh:mm a',
    ).format(transactionData.timestamp.toLocal());

    if (transactionData.type == TransactionType.income ||
        transactionData.type == TransactionType.interest) {
      amountText = '+\$${transactionData.amount.abs().toStringAsFixed(2)}';
      amountColor = Colors.green;
    } else if (transactionData.type == TransactionType.expense) {
      amountText = '-\$${transactionData.amount.abs().toStringAsFixed(2)}';
      amountColor = const Color.fromARGB(255, 255, 69, 69);
    }

    return Padding(
      padding: const EdgeInsets.only(),
      child: Slidable(
        endActionPane: ActionPane(
          motion: StretchMotion(),
          children: [
            SlidableAction(
              onPressed: (BuildContext slidableContext) {
                onDelete(transactionData);
              },
              icon: Icons.delete,
              backgroundColor: Colors.red.shade300,
            ),
            SlidableAction(
              onPressed: (BuildContext slidableContext) {
                onEdit();
              },
              icon: Icons.edit,
              backgroundColor: Colors.blueGrey,
            ),
          ],
        ),
        child: Card(
          elevation: 0,
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(
              vertical: 8.0,
              horizontal: 16.0,
            ),

            title: Text(
              amountText,
              style: TextStyle(color: amountColor, fontSize: 20),
            ),
            subtitle: Text(accountName, style: TextStyle(fontSize: 14)),
            trailing: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  transactionData.description,
                  style: TextStyle(fontSize: 15),
                  textAlign: TextAlign.left,
                ),
                Text(formattedDate, textAlign: TextAlign.left),
                Text(formattedTime, textAlign: TextAlign.left),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
