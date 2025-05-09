import 'package:finance_tracker/data/transactions_class.dart';
import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';

class TransactionsTile extends StatelessWidget {
  final Transactions transactionData;
  final Function(BuildContext) onEdit;
  final Function(BuildContext) onDelete;
  
  const TransactionsTile({
    super.key,
    required this.transactionData,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme =
        Theme.of(context).textTheme;
    final colorScheme =
        Theme.of(context).colorScheme;


    return Padding(
      padding: const EdgeInsets.only(
        right: 25.0,
        left: 25.0,
        top: 25.0,
      ),
      child: Slidable(
        endActionPane: ActionPane(
          motion: StretchMotion(),  
          children: [
            SlidableAction(
              onPressed: onDelete,
              icon: Icons.delete,
              backgroundColor:
                  Colors.red.shade300,
            ),
            SlidableAction(
              onPressed: onEdit,
              icon: Icons.edit,
              backgroundColor: Colors.blueGrey,
            )

          ],
        ),
        child: Container(
          padding: EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color.fromARGB(
              255,
              94,
              94,
              94,
            ),
            borderRadius:
                BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              
            ],
          ),
        ),
      ),
    );
  }
}