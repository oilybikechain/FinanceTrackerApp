import 'package:finance_tracker/data/account_provider.dart';
import 'package:finance_tracker/data/accounts_class.dart';
import 'package:finance_tracker/data/enums.dart';
import 'package:finance_tracker/data/transactions_class.dart';
import 'package:finance_tracker/data/transactions_provider.dart';
import 'package:finance_tracker/utilities/app_drawer.dart';
import 'package:finance_tracker/utilities/transactions_form.dart';
import 'package:finance_tracker/utilities/transactions_tile.dart';
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
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return TransactionsForm(existingTransaction: transactionsToEdit);
      },
    ).then((result) {
      if (result == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              transactionsToEdit == null
                  ? 'Transaction Created!'
                  : 'Transaction Updated!',
            ),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    });
  }

  Future<void> _onDelete(Transactions transactionToDelete) async {
    final currentContext = context;
    final transactionsProvider = Provider.of<TransactionsProvider>(
      currentContext,
      listen: false,
    );
    transactionsProvider.deleteTransaction(transactionToDelete.id!);
  }

  static const int _allAccountsId = 0;
  int? _selectedAccountId = _allAccountsId;
  TimePeriod _selectedTimePeriod = TimePeriod.day;
  bool _isLoadingAccounts = false;
  List<Account> _accountsForDropdown = [];

  @override
  void initState() {
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
      final accountProvider = Provider.of<AccountProvider>(
        context,
        listen: false,
      );
      if (accountProvider.accounts.isEmpty) {
        await accountProvider.fetchAccounts();
      }
      _accountsForDropdown = [
        Account(
          id: _allAccountsId,
          name: 'All',
          initialBalance: 0,
          createdAt: DateTime.now(),
        ),
        ...accountProvider.accounts,
      ];
      if (_selectedAccountId == _allAccountsId &&
          _accountsForDropdown.length > 1 &&
          _accountsForDropdown.first.id != _allAccountsId) {
      } else if (_accountsForDropdown.isNotEmpty &&
          _selectedAccountId == null) {
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
    final transactionsProvider = Provider.of<TransactionsProvider>(
      context,
      listen: false,
    );

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

    print(
      "Fetching transactions for Account ID(s): $accountIdsToFetch, Period: $_selectedTimePeriod, Start: $startDate, End: $endDate",
    );
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
      appBar: AppBar(title: const Text('Homepage')),
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
                  child:
                      _isLoadingAccounts
                          ? const SizedBox(
                            height: 48,
                            child: Center(
                              child: SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              ),
                            ),
                          ) // Small loading indicator
                          : DropdownButtonFormField<int>(
                            isExpanded:
                                true, // Makes dropdown take full width of its Expanded parent
                            value: _selectedAccountId,
                            decoration: InputDecoration(
                              labelText: 'Account',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12.0,
                                vertical: 8.0,
                              ), // Adjust padding
                            ),
                            // Use _accountsForDropdown from state
                            items:
                                _accountsForDropdown.map((Account account) {
                                  return DropdownMenuItem<int>(
                                    value: account.id,
                                    child: Text(
                                      account.name,
                                      overflow:
                                          TextOverflow
                                              .ellipsis, // Prevent long names from overflowing
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
                      ButtonSegment<TimePeriod>(
                        value: TimePeriod.day,
                        label: Text('D'),
                      ),
                      ButtonSegment<TimePeriod>(
                        value: TimePeriod.week,
                        label: Text('W'),
                      ),
                      ButtonSegment<TimePeriod>(
                        value: TimePeriod.month,
                        label: Text('M'),
                      ),
                      ButtonSegment<TimePeriod>(
                        value: TimePeriod.year,
                        label: Text('Y'),
                      ),
                    ],
                    selected: <TimePeriod>{
                      _selectedTimePeriod,
                    }, // The selected value
                    onSelectionChanged: (Set<TimePeriod> newSelection) {
                      if (newSelection.isNotEmpty) {
                        // Ensure a selection is made
                        setState(() {
                          _selectedTimePeriod = newSelection.first;
                        });
                        _fetchTransactions(); // Re-fetch transactions when period changes
                      }
                    },
                    multiSelectionEnabled: false,
                    showSelectedIcon: false,
                  ),
                ),
              ],
            ),
          ),
          const Divider(), // Separator
          // --- Display Fetched Transactions ---
          Expanded(
            // Use Expanded to make the list take remaining space
            child:
                transactionsProvider.transactions.isEmpty
                    ? const Center(
                      child: Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Text(
                          'No transactions found for the selected account and period.',
                          textAlign: TextAlign.center,
                        ),
                      ),
                    )
                    : ListView.builder(
                      itemCount: transactionsProvider.transactions.length,
                      itemBuilder: (ctx, index) {
                        final transaction =
                            transactionsProvider.transactions[index];
                        // --- Return your TransactionsTile widget ---
                        return TransactionsTile(
                          key: ValueKey(
                            transaction.id,
                          ), // Good for list performance
                          transactionData: transaction,
                          onEdit: () {
                            // Call the existing method to show the form for editing
                            _showTransactionsForm(transaction);
                          },
                          onDelete: (Transactions transactionToDelete) {
                            // Call the method to handle deletion
                            _onDelete(transactionToDelete);
                          },
                        );
                        // --- ---
                      },
                    ),
          ),
          // --- End Display Transactions ---
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _showTransactionsForm();
        },
        tooltip: 'Add Transaction',
        child: const Icon(Icons.add),
      ),
    );
    ;
  }
}
