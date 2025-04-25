import 'package:finance_tracker/data/accounts_class.dart';
import 'package:finance_tracker/utilities/accounts_tile.dart';
import 'package:finance_tracker/utilities/app_drawer.dart';
import 'package:flutter/material.dart';
import 'package:finance_tracker/data/account_provider.dart';
import 'package:provider/provider.dart';
import 'package:finance_tracker/data/accounts_class.dart';
import 'package:finance_tracker/data/recurring_transactions.dart';
import 'package:finance_tracker/data/recurring_transactions_class.dart';

class AccountsPage extends StatefulWidget {
  const AccountsPage({super.key});

  @override
  State<AccountsPage> createState() =>
      _AccountsPageState();
}

class _AccountsPageState extends State<AccountsPage> {
  bool _isInit = true;
  bool _isLoading = false;

  @override
  void didChangeDependencies() {
    if (_isInit) {
      setState(() {
        _isLoading = true;
      });
      // Fetch both accounts/balances AND recurring transactions
      // Use Future.wait for parallel fetching
      Future.wait([
        Provider.of<AccountProvider>(context, listen: false).fetchAccounts(),
        Provider.of<RecurringTransactionsProvider>(context, listen: false).fetchRecurringTransactions(), // <<< Fetch recurring
      ]).then((_) {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }).catchError((error) {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error loading data: $error'),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
      });
    }
    _isInit = false;
    super.didChangeDependencies();
  }

  void _onReorder(int oldIndex, int newIndex) {
    final accountProvider = Provider.of<AccountProvider>(context, listen: false);
    final List<Account> items = List.from(accountProvider.accounts);

    if (newIndex > oldIndex) {
      newIndex -= 1;
    }
    final item = items.removeAt(oldIndex);
    items.insert(newIndex, item);
    accountProvider.updateAccountOrder(items);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Accounts'),
      ),
      drawer: const AppDrawer(),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          // Use Consumer2 to listen to *both* providers simultaneously
          : Consumer2<AccountProvider, RecurringTransactionsProvider>(
              builder: (ctx, accountProvider, recurringProvider, child) {
                // Handle errors from either provider
                if (accountProvider.error != null) {
                  return Center(child: Text('Account Error: ${accountProvider.error}'));
                }
                 if (recurringProvider.error != null) {
                  return Center(child: Text('Recurring Tx Error: ${recurringProvider.error}'));
                }

                // Handle loading states (consider combined loading)
                if ((accountProvider.isLoading || recurringProvider.isLoading) && accountProvider.accounts.isEmpty) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!accountProvider.isLoading && accountProvider.accounts.isEmpty) {
                  return const Center(
                    child: Text('No accounts yet. Add one using the + button!'),
                  );
                }

                // Data is ready
                final accounts = accountProvider.accounts;
                final balances = accountProvider.accountBalances;
                // Get the full list of recurring transactions
                final allRecurring = recurringProvider.recurringTransactions; // <<< Get all recurring

                return ReorderableListView.builder(
                  itemCount: accounts.length,
                  itemBuilder: (context, index) {
                    final account = accounts[index];
                    final balance = balances[account.id!] ?? 0.0;

                    // --- Filter recurring transactions for this specific account ---
                    final associatedRecurring = allRecurring.where((rt) {
                      // Check if the primary account matches OR if it's the destination of a transfer
                      return rt.accountId == account.id || rt.transferToAccountId == account.id;
                    }).toList(); // Convert the filtered Iterable to a List
                    // --- ---

                    return AccountsTile(
                      key: ValueKey(account.id!),
                      accountData: account,
                      currentBalance: balance,
                      // --- Pass the filtered list to the tile ---
                      associatedRecurringTransactions: associatedRecurring.isNotEmpty ? associatedRecurring : null,
                      onEdit: () { /* TODO */ },
                      onDelete: () { /* TODO */ },
                    );
                  },
                  onReorder: _onReorder,
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () { /* TODO */ },
        tooltip: 'Add Account',
        child: const Icon(Icons.add),
      ),
    );
  }
}