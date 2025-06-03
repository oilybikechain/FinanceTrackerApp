import 'package:collection/collection.dart';
import 'package:finance_tracker/data/accounts_class.dart';
import 'package:finance_tracker/data/category_class.dart';
import 'package:finance_tracker/data/recurringTransactionsListItem.dart';
import 'package:finance_tracker/data/recurring_transactions_class.dart';
import 'package:finance_tracker/services/account_provider.dart';
import 'package:finance_tracker/services/category_provider.dart';
import 'package:finance_tracker/services/recurring_transactions_provider.dart';
import 'package:finance_tracker/utilities/app_drawer.dart';
import 'package:finance_tracker/utilities/recurring_transactions_form.dart';
import 'package:finance_tracker/utilities/recurring_transactions_tile.dart';
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

  void _showRecurringTransactionsForm([
    RecurringTransaction? recurringTransactionToEdit,
  ]) {
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

  Future<void> _onDelete(
    RecurringTransaction recurringTransactionToDelete,
  ) async {
    // 2. Show Confirmation Dialog
    final currentContext = context;
    final bool? confirm = await showDialog<bool>(
      context: currentContext,
      builder:
          (ctx) => AlertDialog(
            title: const Text('Confirm Deletion'),
            content: Text(
              'Are you sure you want to delete the recurring transaction: "${recurringTransactionToDelete.description}"?\nThis will not delete pass transactions',
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
    final recurringTransactionsprovider =
        Provider.of<RecurringTransactionsProvider>(
          currentContext,
          listen: false,
        ); // Use stored context
    final bool success = await recurringTransactionsprovider
        .deleteRecurringTransaction(recurringTransactionToDelete.id!);

    // 5. Handle Final Result (check mounted again just in case)
    if (!mounted) return;

    if (success) {
      print("Delete successful.");
      ScaffoldMessenger.of(currentContext).showSnackBar(
        SnackBar(
          content: Text(
            '${recurringTransactionToDelete.description} deleted successfully.',
          ),
          duration: const Duration(seconds: 2),
        ),
      );
    } else {
      ScaffoldMessenger.of(currentContext).showSnackBar(
        SnackBar(
          content: Text(
            'Failed to delete ${recurringTransactionToDelete.description}',
          ),
          backgroundColor: Theme.of(currentContext).colorScheme.error,
        ),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {});
  }

  Future<void> _fetchRecurringTransactionsData() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
    });

    final accountProvider = Provider.of<AccountProvider>(
      context,
      listen: false,
    );
    final recurringTransactionsProvider =
        Provider.of<RecurringTransactionsProvider>(context, listen: false);
    final categoryProvider = Provider.of<CategoryProvider>(
      context,
      listen: false,
    );

    try {
      if (accountProvider.accounts.isEmpty) {
        await accountProvider.fetchAccounts();
      }
      if (categoryProvider.categories.isEmpty && !categoryProvider.isLoading) {
        await categoryProvider.fetchCategories();
      }
      if (recurringTransactionsProvider.recurringTransactions.isEmpty) {
        await recurringTransactionsProvider.fetchRecurringTransactions();
      }
    } catch (e) {
      print("Error during initial page data load: $e");
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading page data: $e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false; // Stop loading
        });
      }
    }
  }

  List<RecurringTransactionsListItem> _buildDisplayList(
    List<RecurringTransaction> allRules,
    List<Account> allAccounts,
    List<Category> allCategories,
  ) {
    List<RecurringTransactionsListItem> items = [];

    // Separate rules
    final interestRules =
        allRules
            .where((rule) => rule.isInterestRule && rule.isSystemGenerated)
            .toList();
    final customRules =
        allRules
            .where((rule) => !rule.isInterestRule && !rule.isSystemGenerated)
            .toList();

    // Sort them (optional, e.g., by next due date or description)
    interestRules.sort((a, b) => a.nextDueDate.compareTo(b.nextDueDate));
    customRules.sort((a, b) => a.nextDueDate.compareTo(b.nextDueDate));

    // Add Interest section
    if (interestRules.isNotEmpty) {
      items.add(SeparatorItem("Interest Rules (System)"));
      for (var rule in interestRules) {
        final account = allAccounts.firstWhereOrNull(
          (acc) => acc.id == rule.accountId,
        );
        final category = allCategories.firstWhereOrNull(
          (cat) => cat.id == rule.categoryId,
        );
        final transferToAccount =
            rule.transferToAccountId != null
                ? allAccounts.firstWhereOrNull(
                  (acc) => acc.id == rule.transferToAccountId,
                )
                : null;

        items.add(
          RecurringTransactionItem(
            recurringTransactionData: rule,
            accountName: account?.name ?? 'Unknown Account',
            categoryForDisplay:
                category ??
                Category(
                  id: rule.categoryId,
                  name: 'Unknown Category',
                  colorValue: Colors.grey.value,
                ), // Fallback
            transferToAccountName: transferToAccount?.name,
          ),
        );
      }
    }

    // Add Custom section
    if (customRules.isNotEmpty) {
      items.add(SeparatorItem("Custom Recurring Rules"));
      for (var rule in customRules) {
        final account = allAccounts.firstWhereOrNull(
          (acc) => acc.id == rule.accountId,
        );
        final category = allCategories.firstWhereOrNull(
          (cat) => cat.id == rule.categoryId,
        );
        final transferToAccount =
            rule.transferToAccountId != null
                ? allAccounts.firstWhereOrNull(
                  (acc) => acc.id == rule.transferToAccountId,
                )
                : null;

        items.add(
          RecurringTransactionItem(
            recurringTransactionData: rule,
            accountName: account?.name ?? 'Unknown Account',
            categoryForDisplay:
                category ??
                Category(
                  id: rule.categoryId,
                  name: 'Cat. ID: ${rule.categoryId}',
                  colorValue: Colors.grey.value,
                ),
            transferToAccountName: transferToAccount?.name,
          ),
        );
      }
    }
    return items;
  }

  @override
  Widget build(BuildContext context) {
    final accountProvider = context.watch<AccountProvider>();
    final categoryProvider = context.watch<CategoryProvider>();
    final recurringTransactionsProvider =
        context.watch<RecurringTransactionsProvider>();
    final List<Category> categoryData = categoryProvider.categories;
    final List<Account> accountData = accountProvider.accounts;
    final List<RecurringTransaction> recurringTransactionData =
        recurringTransactionsProvider.recurringTransactions;
    final List<RecurringTransactionsListItem> displayItems = _buildDisplayList(
      recurringTransactionData,
      accountProvider.accounts,
      categoryProvider.categories,
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Recurring Transactions')),
      drawer: const AppDrawer(),

      body:
          displayItems.isEmpty
              ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('No recurring transactions set up.'),
                    const SizedBox(height: 10),
                    ElevatedButton(
                      onPressed: () => _showRecurringTransactionsForm(),
                      child: const Text('Add First Recurring Transaction'),
                    ),
                  ],
                ),
              )
              : ListView.builder(
                itemCount: displayItems.length,
                itemBuilder: (ctx, index) {
                  final item = displayItems[index];

                  if (item is SeparatorItem) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16.0,
                        vertical: 12.0,
                      ),
                      alignment: Alignment.centerLeft,
                      child: Text(
                        item.separatorName,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    );
                  } else if (item is RecurringTransactionItem) {
                    return RecurringTransactionsTile(
                      key: ValueKey(item.recurringTransactionData.id),
                      recurringTransactionData: item.recurringTransactionData,
                      accountName: item.accountName,
                      categoryTag: item.categoryForDisplay,
                      transferToAccountName: item.transferToAccountName,
                      onEdit: () {
                        _showRecurringTransactionsForm(
                          item.recurringTransactionData,
                        );
                      },
                      onDelete: (RecurringTransaction rt) {
                        _onDelete(rt);
                      },
                    );
                  }
                },
              ),

      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _showRecurringTransactionsForm();
        },
        tooltip: 'Add Account',
        child: const Icon(Icons.add),
      ),
    );
  }
}
