import 'package:finance_tracker/data/recurring_transactions_class.dart';
import 'package:finance_tracker/services/recurring_transactions_provider.dart';
import 'package:finance_tracker/utilities/app_drawer.dart';
import 'package:finance_tracker/utilities/recurring_transactions_form.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class RecurringTransactionsPage extends StatefulWidget {
  const RecurringTransactionsPage({super.key});

  @override
  State<RecurringTransactionsPage> createState() =>
      _RecurringTransactionsPageState();
}

class _RecurringTransactionsPageState extends State<RecurringTransactionsPage> {
  bool _isInit = true;
  bool _isLoading = false;

  void _showCategoryForm([RecurringTransaction? recurringTransactionToEdit]) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return RecurringTransactionsForm(
          existingRecurringTransaction: recurringTransactionToEdit,
        );
      },
    ).then((result) {
      if (result == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                recurringTransactionToEdit != null
                    ? Text('Recurring Transaction Edited!')
                    : Text('Recurring Transaction Created!'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    });
  }

  @override
  void didChangeDependencies() {
    if (_isInit) {
      setState(() {
        _isLoading = true;
      });

      Provider.of<RecurringTransactionsProvider>(
        context,
        listen: false,
      ).fetchRecurringTransactions().then((_) {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      });
    }
    _isInit = false;
    super.didChangeDependencies();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Recurring Transactions')),
      drawer: const AppDrawer(),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _showCategoryForm();
        },
        tooltip: 'Add Account',
        child: const Icon(Icons.add),
      ),
    );
  }
}
