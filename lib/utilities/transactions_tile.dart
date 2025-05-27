import 'package:finance_tracker/data/category_class.dart';
import 'package:finance_tracker/data/enums.dart';
import 'package:finance_tracker/data/transactions_class.dart';
import 'package:finance_tracker/utilities/category_chip.dart';
import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:intl/intl.dart';

class TransactionsTile extends StatelessWidget {
  final Transactions transactionData;
  final VoidCallback onEdit;
  final Function(Transactions) onDelete;
  final String accountName;
  final Category categoryTag;

  const TransactionsTile({
    super.key,
    required this.transactionData,
    required this.onEdit,
    required this.onDelete,
    required this.accountName,
    required this.categoryTag,
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
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 12, horizontal: 20),
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

                    SizedBox(height: 6),

                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          accountName,
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
                  ],
                ),

                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisSize:
                      MainAxisSize.min, // Column takes minimum vertical space
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Text(
                      transactionData.description!,
                      style: Theme.of(context).textTheme.titleMedium,
                      textAlign: TextAlign.left,
                    ),
                    Text(
                      formattedDate,
                      textAlign: TextAlign.left,
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                    Text(
                      formattedTime,
                      textAlign: TextAlign.left,
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),

        //   child: ListTile(
        //     contentPadding: const EdgeInsets.symmetric(
        //       vertical: 6,
        //       horizontal: 16.0,
        //     ),

        //     dense: true,

        //     title: Text(
        //       amountText,
        //       style: Theme.of(
        //         context,
        //       ).textTheme.titleLarge!.copyWith(color: amountColor),
        //     ),
        //     subtitle: Padding(
        //       padding: const EdgeInsets.only(top: 8.0),
        //       child: Row(
        //         mainAxisSize: MainAxisSize.min,
        //         children: [
        //           Text(
        //             accountName,
        //             style: Theme.of(context).textTheme.titleLarge,
        //           ),
        //           SizedBox(width: 5),
        //           CategoryChip(
        //             category: categoryTag,
        //             isSelected: false,
        //             onSelected: (nill) {},
        //           ),
        //         ],
        //       ),
        //     ),
        //     trailing: Align(
        //       alignment: Alignment.topRight,
        //       child: Column(
        //         crossAxisAlignment: CrossAxisAlignment.end,
        //         mainAxisSize:
        //             MainAxisSize.min, // Column takes minimum vertical space
        //         mainAxisAlignment: MainAxisAlignment.start,
        //         children: [
        //           Text(
        //             transactionData.description!,
        //             style: Theme.of(context).textTheme.titleMedium,
        //             textAlign: TextAlign.left,
        //           ),
        //           Text(
        //             formattedDate,
        //             textAlign: TextAlign.left,
        //             style: Theme.of(context).textTheme.labelMedium,
        //           ),
        //           Text(
        //             formattedTime,
        //             textAlign: TextAlign.left,
        //             style: Theme.of(context).textTheme.labelMedium,
        //           ),
        //         ],
        //       ),
        //     ),
        //   ),
      ),
    );
  }
}
