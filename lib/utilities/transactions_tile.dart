import 'package:finance_tracker/data/transactions_class.dart';
import 'package:flutter/material.dart';

class TransactionsTile extends StatelessWidget {
  final Transactions transactionData;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  
  const TransactionsTile({
    super.key,
    required this.transactionData,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return const Placeholder();
  }
}