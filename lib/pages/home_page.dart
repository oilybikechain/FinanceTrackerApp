import 'package:finance_tracker/data/account_provider.dart';
import 'package:finance_tracker/data/accounts_class.dart';
import 'package:finance_tracker/data/enums.dart';
import 'package:finance_tracker/data/transactions_class.dart';
import 'package:finance_tracker/data/transactions_provider.dart';
import 'package:finance_tracker/utilities/app_drawer.dart';
import 'package:finance_tracker/utilities/transactions_form.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';




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
  /*
  Future<void> _onDelete(Transactions transactionToDelete) 
  async {
    if (transactionToDelete.id == null) {
      print("Error: Cannot delete account with null ID.");
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
              'Are you sure you want to delete the transaction "${transactionToDelete.description}"?\nThis will also delete all associated transactions.',
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
    final transactionsProvider =
        Provider.of<TransactionsProvider>(
          currentContext,
          listen: false,
        ); // Use stored context
    final bool success = await TransactionsProvider.deleteTransaction(transactionToDelete.id!);


    // 5. Handle Final Result (check mounted again just in case)
    if (!mounted) return;

    if (success) {
      print("Delete successful.");
      ScaffoldMessenger.of(
        currentContext,
      ).showSnackBar(
        SnackBar(
          content: Text(
            '${transactionToDelete.description} deleted successfully.',
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
            'Failed to delete ${transactionToDelete.description}. ${transactionsProvider.error ?? "Unknown error."}',
          ),
          backgroundColor:
              Theme.of(
                currentContext,
              ).colorScheme.error,
        ),
      );
    }
  }
  */

  static const int _allAccountsId = 0;
  int? _selectedAccountId = _allAccountsId;
  TimePeriod _selectedTimePeriod = TimePeriod.day;
  bool _isLoadingAccounts = false;
  List<Account> _accountsForDropdown = [];

  @override
  void initState () {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchAccountsForDropdown();
      _fetchTransactions();
    });
  }

  Future<void> _fetchAccountsForDropdown() async {
    if (!mounted) return;
    setState(() {
      _isLoadingAccounts = true;
    });
    try {
      final accountProvider = Provider.of<AccountProvider>(context, listen: false);
      if (accountProvider.accounts.isEmpty && !accountProvider.isLoading) {
         await accountProvider.fetchAccounts();
      }
       _accountsForDropdown = [
        Account(id: _allAccountsId, name: 'All', initialBalance: 0, createdAt: DateTime.now()),
        ...accountProvider.accounts
      ];
      if (_selectedAccountId == _allAccountsId && _accountsForDropdown.length > 1 && _accountsForDropdown.first.id != _allAccountsId) {
      } else if (_accountsForDropdown.isNotEmpty && _selectedAccountId == null) {
          _selectedAccountId = _accountsForDropdown.first.id;
      }
    } catch (e) {
      print("Error fetching accounts for dropdown: $e");
      // Handle error appropriately
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingAccounts = false;
        });
      }
    }
  }

  Future<void> _fetchTransactions() async {
    if (!mounted) return;
    final transactionsProvider = Provider.of<TransactionsProvider>(context, listen: false);

    List<int>? accountIdsToFetch;
    if (_selectedAccountId != null && _selectedAccountId != _allAccountsId) {
      accountIdsToFetch = [_selectedAccountId!];
    }
    DateTime now = DateTime.now();
    DateTime startDate;
    DateTime endDate = DateTime(now.year, now.month, now.day, 23, 59, 59, 999); 

    switch (_selectedTimePeriod) {
      case TimePeriod.day:
        startDate = DateTime(now.year, now.month, now.day); 
      case TimePeriod.week:
        startDate = now.subtract(Duration(days: now.weekday - 1)); 
        startDate = DateTime(startDate.year, startDate.month, startDate.day);
        break;
      case TimePeriod.month:
        startDate = DateTime(now.year, now.month, 1); 
        break;
      case TimePeriod.year:
        startDate = DateTime(now.year, 1, 1); 
        break;
    }

    print("Fetching transactions for Account ID(s): $accountIdsToFetch, Period: $_selectedTimePeriod, Start: $startDate, End: $endDate");
    await transactionsProvider.fetchTransactions(
      accountIds: accountIdsToFetch,
      startDate: startDate,
      endDate: endDate, // Fetch up to the end of the selected period's "today"
    );
  }

  @override
  Widget build(BuildContext context) {
    final transactionsProvider = Provider.of<TransactionsProvider>(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Homepage'),
      ),
      drawer: const AppDrawer(), // Use the reusable drawer widget here!
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                SizedBox(
                  width: 100,
                  child: _isLoadingAccounts
                      ? const SizedBox(height: 48, child: Center(child: SizedBox(width:24, height:24, child: CircularProgressIndicator(strokeWidth: 2,)))) // Small loading indicator
                      : DropdownButtonFormField<int>(
                          isExpanded: true, // Makes dropdown take full width of its Expanded parent
                          value: _selectedAccountId,
                          decoration: InputDecoration(
                            labelText: 'Account',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0), // Adjust padding
                          ),
                          // Use _accountsForDropdown from state
                          items: _accountsForDropdown.map((Account account) {
                            return DropdownMenuItem<int>(
                              value: account.id,
                              child: Text(
                                account.name,
                                overflow: TextOverflow.ellipsis, // Prevent long names from overflowing
                              ),
                            );
                          }).toList(),
                          onChanged: (int? newValue) {
                            if (newValue != null) {
                              setState(() {
                                _selectedAccountId = newValue;
                              });
                              _fetchTransactions(); // Re-fetch transactions when account changes
                            }
                          },
                          // No validator needed if "All Accounts" is always a valid selection
                        ),
                ),

                const Spacer(),

                // Adjust flex to balance with dropdown
                SizedBox(
                  width: 175,
                  child: SegmentedButton<TimePeriod>(
                      segments: const <ButtonSegment<TimePeriod>>[
                        ButtonSegment<TimePeriod>(value: TimePeriod.day, label: Text('D')),
                        ButtonSegment<TimePeriod>(value: TimePeriod.week, label: Text('W')),
                        ButtonSegment<TimePeriod>(value: TimePeriod.month, label: Text('M')),
                        ButtonSegment<TimePeriod>(value: TimePeriod.year, label: Text('Y')),
                      ],
                      selected: <TimePeriod>{_selectedTimePeriod}, // The selected value
                      onSelectionChanged: (Set<TimePeriod> newSelection) {
                        if (newSelection.isNotEmpty) { // Ensure a selection is made
                          setState(() {
                            _selectedTimePeriod = newSelection.first;
                          });
                          _fetchTransactions(); // Re-fetch transactions when period changes
                        }
                      },
                      multiSelectionEnabled: false,
                      showSelectedIcon: false,
                  ),
                )
              ],
            ), 
          ),
           const Divider(), // Separator

          // --- Display Fetched Transactions ---
          Expanded( // Use Expanded to make the list take remaining space
            child: transactionsProvider.isLoading
                ? const Center(child: CircularProgressIndicator())
                : transactionsProvider.transactions.isEmpty
                    ? const Center(child: Text('No transactions for this period.'))
                    : ListView.builder(
                        itemCount: transactionsProvider.transactions.length,
                        itemBuilder: (ctx, index) {
                          final transaction = transactionsProvider.transactions[index];
                          // TODO: Create a TransactionListTile widget
                          return ListTile(
                            title: Text(transaction.description ?? 'No Description'),
                            subtitle: Text(
                                'Account ID: ${transaction.accountId} - ${transaction.timestamp.toLocal().toString().substring(0, 10)}'
                            ),
                            trailing: Text(
                              '${transaction.amount < 0 ? "-" : ""}\$${transaction.amount.abs().toStringAsFixed(2)}',
                              style: TextStyle(
                                color: transaction.amount < 0 ? Colors.red : Colors.green,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            onTap: () => _showTransactionsForm(transaction), // For editing
                          );
                        },
                      ),
          ),
          // --- End Display Transactions ---
        ],
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