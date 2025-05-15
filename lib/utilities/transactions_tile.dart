import 'package:finance_tracker/data/enums.dart';
import 'package:finance_tracker/data/transactions_class.dart';
import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';

class TransactionsTile extends StatelessWidget {
  final Transactions transactionData;
  final VoidCallback onEdit;
  final Function(Transactions) onDelete;

  const TransactionsTile({
    super.key,
    required this.transactionData,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(right: 25.0, left: 25.0, top: 25.0),
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
        child: Container(
          padding: EdgeInsets.all(10),
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(8)),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Column(
                children: [
                  if (transactionData.type == TransactionType.income ||
                      transactionData.type == TransactionType.interest)
                    Text(
                      '+\$${transactionData.amount.toStringAsFixed(2)}',
                      style: TextStyle(color: Colors.green),
                    ),
                  if (transactionData.type == TransactionType.expense)
                    Text(
                      '-\$${transactionData.amount.toStringAsFixed(2)}',
                      style: TextStyle(color: Colors.red),
                    ),

                  SizedBox(height: 10),

                  Text("${transactionData.accountId}"),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
