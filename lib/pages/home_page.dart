import 'package:finance_tracker/data/transactions_class.dart';
import 'package:finance_tracker/utilities/app_drawer.dart';
import 'package:finance_tracker/utilities/transactions_form.dart';
import 'package:flutter/material.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  void _showTransactionsForm([Transactions? transactionsToEdit]) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(20),
        ),
      ),
      builder: (sheetContext) {
        return TransactionsForm(
          existingTransaction: transactionsToEdit,
        );
      },
    ).then((result) {
      if (result == true) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(
          SnackBar(
            content: Text(
              transactionsToEdit == null
                  ? 'Transaction Created!'
                  : 'Transaction Updated!',
            ),
            duration: const Duration(
              seconds: 2,
            ),
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Homepage'),
      ),
      drawer: const AppDrawer(), // Use the reusable drawer widget here!
      body: const Center(
        child: Text('HomePage'),
      ),
      floatingActionButton:
          FloatingActionButton(
            onPressed: () {
              _showTransactionsForm();
            },
            tooltip: 'Add Transaction',
            child: const Icon(Icons.add),
          ),
    );;
  }
}