import 'package:finance_tracker/data/accounts_class.dart';
import 'package:finance_tracker/utilities/account_form.dart';
import 'package:finance_tracker/utilities/accounts_tile.dart';
import 'package:finance_tracker/utilities/app_drawer.dart';
import 'package:flutter/material.dart';
import 'package:finance_tracker/data/account_provider.dart';
import 'package:provider/provider.dart';

class AccountsPage extends StatefulWidget {
  const AccountsPage({super.key});

  @override
  State<AccountsPage> createState() => _AccountsPageState();
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
      // --- Core Logic: Fetch only accounts and their balances ---
      Provider.of<AccountProvider>(context, listen: false)
          .fetchAccounts() // This method in provider should fetch accounts AND balances
          .then((_) {
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

  void _onReorder(int oldIndex, int newIndex) {
    final accountProvider = Provider.of<AccountProvider>(
      context,
      listen: false,
    );
    final List<Account> items = List.from(accountProvider.accounts);

    if (newIndex > oldIndex) {
      newIndex -= 1;
    }
    final item = items.removeAt(oldIndex);
    items.insert(newIndex, item);
    // Let provider handle DB update and notifying listeners
    accountProvider.updateAccountOrder(items);
  }

  // Generates a window for the form to show up in
  void _showAccountForm([Account? accountToEdit]) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return AccountForm(existingAccount: accountToEdit);
      },
    ).then((result) {
      if (result == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              accountToEdit == null ? 'Account Created!' : 'Account Updated!',
            ),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    });
  }

  //function to delete
  Future<void> _onDelete(Account accountToDelete) async {
    // 1. Null check ID (optional but good)
    if (accountToDelete.id == null) {
      print("Error: Cannot delete account with null ID.");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error: Invalid account data.')),
        );
      }
      return;
    }

    // 2. Show Confirmation Dialog
    final currentContext = context;
    final bool? confirm = await showDialog<bool>(
      context: currentContext,
      builder:
          (ctx) => AlertDialog(
            title: const Text('Confirm Deletion'),
            content: Text(
              'Are you sure you want to delete the account "${accountToDelete.name}"?\nThis will also delete all associated transactions.',
            ),
            actions: [
              TextButton(
                child: const Text('Cancel'),
                onPressed:
                    () =>
                        Navigator.of(ctx).pop(false), // Return false on cancel
              ),
              TextButton(
                child: Text(
                  'Delete',
                  style: TextStyle(
                    color: Theme.of(currentContext).colorScheme.error,
                  ),
                ),
                onPressed:
                    () => Navigator.of(ctx).pop(true), // Return true on confirm
              ),
            ],
          ),
    );

    // 3. Check Dialog Result (and if widget still mounted)
    if (confirm != true || !mounted) {
      print("Deletion cancelled by user or widget unmounted.");
      return; // Exit if user cancelled or widget gone
    }

    // 4. Proceed with Deletion if Confirmed
    final accountProvider = Provider.of<AccountProvider>(
      currentContext,
      listen: false,
    ); // Use stored context
    final bool success = await accountProvider.deleteAccount(
      accountToDelete.id!,
    );

    // 5. Handle Final Result (check mounted again just in case)
    if (!mounted) return;

    if (success) {
      print("Delete successful.");
      ScaffoldMessenger.of(currentContext).showSnackBar(
        SnackBar(
          content: Text('${accountToDelete.name} deleted successfully.'),
          duration: const Duration(seconds: 2),
        ),
      );
    } else {
      ScaffoldMessenger.of(currentContext).showSnackBar(
        SnackBar(
          content: Text('Failed to delete ${accountToDelete.name}'),
          backgroundColor: Theme.of(currentContext).colorScheme.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Accounts')),
      drawer: const AppDrawer(),
      body: Consumer<AccountProvider>(
        builder: (ctx, accountProvider, child) {
          // Handle loading states (consider combined loading)

          if (accountProvider.accounts.isEmpty) {
            return const Center(
              child: Text('No accounts yet. Add one using the + button!'),
            );
          }

          // Data is ready
          final accounts = accountProvider.accounts;
          final balances = accountProvider.accountBalances;

          return ReorderableListView.builder(
            itemCount: accounts.length,
            itemBuilder: (context, index) {
              final account = accounts[index];
              final balance = balances[account.id!] ?? 0.0;

              return AccountsTile(
                key: ValueKey(account.id!),
                accountData: account,
                currentBalance: balance,

                onEdit: () {
                  _showAccountForm(account);
                },
                onDelete: () {
                  _onDelete(account);
                },
              );
            },
            onReorder: _onReorder,
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _showAccountForm();
        },
        tooltip: 'Add Account',
        child: const Icon(Icons.add),
      ),
    );
  }
}
