import 'package:finance_tracker/data/accounts_class.dart';
import 'package:finance_tracker/utilities/account_form.dart';
import 'package:finance_tracker/utilities/accounts_tile.dart';
import 'package:finance_tracker/utilities/app_drawer.dart';
import 'package:flutter/material.dart';
import 'package:finance_tracker/data/account_provider.dart';
import 'package:provider/provider.dart';
import 'package:finance_tracker/data/recurring_transactions_provider.dart';
import 'package:finance_tracker/data/recurring_transactions_class.dart';

class AccountsPage extends StatefulWidget {
  const AccountsPage({super.key});

  @override
  State<AccountsPage> createState() =>
      _AccountsPageState();
}

class _AccountsPageState
    extends State<AccountsPage> {
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
            Provider.of<AccountProvider>(
              context,
              listen: false,
            ).fetchAccounts(),
            Provider.of<
              RecurringTransactionsProvider
            >(
              context,
              listen: false,
            ).fetchRecurringTransactions(), // <<< Fetch recurring
          ])
          .then((_) {
            if (mounted) {
              setState(() {
                _isLoading = false;
              });
            }
          })
          .catchError((error) {
            if (mounted) {
              setState(() {
                _isLoading = false;
              });
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(
                SnackBar(
                  content: Text(
                    'Error loading data: $error',
                  ),
                  backgroundColor:
                      Theme.of(
                        context,
                      ).colorScheme.error,
                ),
              );
            }
          });
    }
    _isInit = false;
    super.didChangeDependencies();
  }

  void _onReorder(
    int oldIndex,
    int newIndex,
    ) {
    final accountProvider =
        Provider.of<AccountProvider>(
          context,
          listen: false,
        );
    final List<Account> items = List.from(
      accountProvider.accounts,
    );

    if (newIndex > oldIndex) {
      newIndex -= 1;
    }
    final item = items.removeAt(oldIndex);
    items.insert(newIndex, item);
    accountProvider.updateAccountOrder(
      items,
    );
  }

  // Generates a window for the form to show up in
  void _showAccountForm([
    Account? accountToEdit,
  ]) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(20),
        ),
      ),
      builder: (sheetContext) {
        return AccountForm(
          existingAccount: accountToEdit,
        );
      },
    ).then((result) {
      if (result == true) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(
          SnackBar(
            content: Text(
              accountToEdit == null
                  ? 'Account Created!'
                  : 'Account Updated!',
            ),
            duration: const Duration(
              seconds: 2,
            ),
          ),
        );
      }
    });
  }

  //function to delete
  Future<void> _onDelete(
    Account accountToDelete,
  ) async {
    // 1. Null check ID (optional but good)
    if (accountToDelete.id == null) {
      print(
        "Error: Cannot delete account with null ID.",
      );
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(
          const SnackBar(
            content: Text(
              'Error: Invalid account data.',
            ),
          ),
        );
      }
      return;
    }

    // 2. Show Confirmation Dialog
    final currentContext = context;
    final bool?
    confirm = await showDialog<bool>(
      context: currentContext,
      builder:
          (ctx) => AlertDialog(
            title: const Text(
              'Confirm Deletion',
            ),
            content: Text(
              'Are you sure you want to delete the account "${accountToDelete.name}"?\nThis will also delete all associated transactions.',
            ),
            actions: [
              TextButton(
                child: const Text('Cancel'),
                onPressed:
                    () => Navigator.of(
                      ctx,
                    ).pop(
                      false,
                    ), // Return false on cancel
              ),
              TextButton(
                child: Text(
                  'Delete',
                  style: TextStyle(
                    color:
                        Theme.of(
                          currentContext,
                        ).colorScheme.error,
                  ),
                ),
                onPressed:
                    () => Navigator.of(
                      ctx,
                    ).pop(
                      true,
                    ), // Return true on confirm
              ),
            ],
          ),
    );

    // 3. Check Dialog Result (and if widget still mounted)
    if (confirm != true || !mounted) {
      print(
        "Deletion cancelled by user or widget unmounted.",
      );
      return; // Exit if user cancelled or widget gone
    }

    // 4. Proceed with Deletion if Confirmed
    final accountProvider =
        Provider.of<AccountProvider>(
          currentContext,
          listen: false,
        ); // Use stored context
    final bool success = await accountProvider.deleteAccount(accountToDelete.id!);


    // 5. Handle Final Result (check mounted again just in case)
    if (!mounted) return;

    if (success) {
      print("Delete successful.");
      ScaffoldMessenger.of(
        currentContext,
      ).showSnackBar(
        SnackBar(
          content: Text(
            '${accountToDelete.name} deleted successfully.',
          ),
          duration: const Duration(
            seconds: 2,
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(
        currentContext,
      ).showSnackBar(
        SnackBar(
          content: Text(
            'Failed to delete ${accountToDelete.name}. ${accountProvider.error ?? "Unknown error."}',
          ),
          backgroundColor:
              Theme.of(
                currentContext,
              ).colorScheme.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Accounts'),
      ),
      drawer: const AppDrawer(),
      body:
          _isLoading
              ? const Center(
                child:
                    CircularProgressIndicator(),
              )
              // Use Consumer2 to listen to *both* providers simultaneously
              : Consumer2<
                AccountProvider,
                RecurringTransactionsProvider
              >(
                builder: (
                  ctx,
                  accountProvider,
                  recurringProvider,
                  child,
                ) {
                  // Handle errors from either provider
                  if (accountProvider
                          .error !=
                      null) {
                    return Center(
                      child: Text(
                        'Account Error: ${accountProvider.error}',
                      ),
                    );
                  }
                  if (recurringProvider
                          .error !=
                      null) {
                    return Center(
                      child: Text(
                        'Recurring Tx Error: ${recurringProvider.error}',
                      ),
                    );
                  }

                  // Handle loading states (consider combined loading)
                  if ((accountProvider
                              .isLoading ||
                          recurringProvider
                              .isLoading) &&
                      accountProvider
                          .accounts
                          .isEmpty) {
                    return const Center(
                      child:
                          CircularProgressIndicator(),
                    );
                  }

                  if (!accountProvider
                          .isLoading &&
                      accountProvider
                          .accounts
                          .isEmpty) {
                    return const Center(
                      child: Text(
                        'No accounts yet. Add one using the + button!',
                      ),
                    );
                  }

                  // Data is ready
                  final accounts =
                      accountProvider
                          .accounts;
                  final balances =
                      accountProvider
                          .accountBalances;
                  // Get the full list of recurring transactions
                  final allRecurring =
                      recurringProvider
                          .recurringTransactions; // <<< Get all recurring

                  return ReorderableListView.builder(
                    itemCount:
                        accounts.length,
                    itemBuilder: (
                      context,
                      index,
                    ) {
                      final account =
                          accounts[index];
                      final balance =
                          balances[account
                              .id!] ??
                          0.0;

                      // --- Filter recurring transactions for this specific account ---
                      final associatedRecurring =
                          allRecurring.where((
                            rt,
                          ) {
                            // Check if the primary account matches OR if it's the destination of a transfer
                            return rt.accountId ==
                                    account
                                        .id ||
                                rt.transferToAccountId ==
                                    account
                                        .id;
                          }).toList(); // Convert the filtered Iterable to a List
                      // --- ---

                      return AccountsTile(
                        key: ValueKey(
                          account.id!,
                        ),
                        accountData: account,
                        currentBalance:
                            balance,

                        onEdit: () {
                          _showAccountForm(
                            account,
                          );
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
      floatingActionButton:
          FloatingActionButton(
            onPressed: () {
              _showAccountForm();
            },
            tooltip: 'Add Account',
            child: const Icon(Icons.add),
          ),
    );
  }
}
