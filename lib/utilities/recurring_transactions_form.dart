import 'package:finance_tracker/data/accounts_class.dart';
import 'package:finance_tracker/data/category_class.dart';
import 'package:finance_tracker/data/enums.dart';
import 'package:finance_tracker/data/recurring_transactions_class.dart';
import 'package:finance_tracker/pages/recurring_transactions_page.dart';
import 'package:finance_tracker/services/account_provider.dart';
import 'package:finance_tracker/services/category_provider.dart';
import 'package:finance_tracker/services/recurring_transactions_provider.dart';
import 'package:finance_tracker/utilities/category_chip.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class RecurringTransactionsForm extends StatefulWidget {
  final RecurringTransaction? existingRecurringTransaction;

  const RecurringTransactionsForm({
    super.key,
    this.existingRecurringTransaction,
  });

  @override
  State<RecurringTransactionsForm> createState() =>
      _RecurringTransactionsFormState();
}

class _RecurringTransactionsFormState extends State<RecurringTransactionsForm> {
  final _formkey = GlobalKey<FormState>();

  final _transactionDescriptionController = TextEditingController();

  final _amountController = TextEditingController();

  //End date

  Frequency? _selectedRecurringTransactionPeriod;

  bool _isEditMode = false;
  DateTime _startDate = DateTime.now();
  DateTime? _endDate;
  TransactionType _selectedtransactionType = TransactionType.income;
  int? _selectedAccountId;
  int? _selectedDestinationAccountId;
  int _selectedCategoryId = 1;
  bool _isLoadingDefaults = false;

  //TODO
  @override
  void initState() {}

  Future<void> _submitForm() async {
    final isValid = _formkey.currentState?.validate() ?? false;

    if (!isValid) {
      print("form is invalid");
      //TODO Show message in snackbar
      return;
    }

    String description = _transactionDescriptionController.text.trim();
    final amount = double.tryParse(_amountController.text) ?? 0.0;
    final transactionType = _selectedtransactionType;
    final account = _selectedAccountId;
    final selectedCategoryId = _selectedCategoryId;
    final startDate = _startDate;
    final endDate = _endDate;
    final frequency = _selectedRecurringTransactionPeriod;
    final nextDueDate = _startDate;
    final transferCategoryId = 2;

    final recurringTransactionsProvider =
        Provider.of<RecurringTransactionsProvider>(context, listen: false);
    final navigator = Navigator.of(context); // Store Navigator
    final messenger = ScaffoldMessenger.of(context); // Store ScaffoldMessenger
    final theme = Theme.of(context);

    double finalAmount =
        (transactionType == TransactionType.income)
            ? amount.abs()
            : -amount.abs();

    if (description.isEmpty) {
      description =
          transactionType!.name[0].toUpperCase() +
          transactionType!.name.substring(1);
    }

    bool success = false;

    if (_isEditMode) {
      //TODO
    } else {
      if (_selectedtransactionType == TransactionType.transfer) {
        // --- Handle Transfer ---
        if (_selectedDestinationAccountId == null ||
            _selectedAccountId == _selectedDestinationAccountId) {
          if (mounted) {
            messenger.showSnackBar(
              const SnackBar(
                content: Text('Invalid source/destination for transfer.'),
              ),
            );
          }
          success = false;
          return;
        }
        print("Creating new Recurring Transfer");
        success = await recurringTransactionsProvider.addRecurringTransaction(
          RecurringTransaction(
            accountId: account!,
            type: transactionType,
            amount: amount,
            frequency: frequency!,
            startDate: startDate,
            nextDueDate: nextDueDate,
            categoryId: transferCategoryId,
            description: description,
            endDate: endDate,
            transferToAccountId: _selectedDestinationAccountId,
          ),
        );
      } else {
        print("Creating new Transaction");
        success = await recurringTransactionsProvider.addRecurringTransaction(
          RecurringTransaction(
            accountId: account!,
            type: transactionType,
            amount: amount,
            frequency: frequency!,
            startDate: startDate,
            nextDueDate: nextDueDate,
            categoryId: selectedCategoryId,
            description: description,
            endDate: endDate,
          ),
        );
      }
    }

    if (!mounted) {
      return;
    }

    if (success) {
      print("Operation successful, popping form.");
      navigator.pop(true);
    } else {
      print("Operation failed (provider returned false).");
      messenger.showSnackBar(
        SnackBar(
          content: Text('Operation failed.'),
          backgroundColor: theme.colorScheme.error,
        ),
      );
    }
  }

  Future<void> _selectStartDate(BuildContext context) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _startDate, // Pre-select current date
      firstDate: DateTime(2000), // Earliest selectable date
      lastDate: DateTime(2101), // Latest selectable date
    );
    if (pickedDate != null && pickedDate != _startDate) {
      setState(() {
        // Combine picked date with existing time
        _startDate = DateTime(
          pickedDate.year,
          pickedDate.month,
          pickedDate.day,
        );
      });
    }
  }

  Future<void> _selectEndDate(BuildContext context) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _endDate ?? _startDate.add(const Duration(days: 1)),
      firstDate: _startDate,
      lastDate: DateTime(2101),
    );
    if (pickedDate != null) {
      setState(() {
        _endDate = DateTime(pickedDate.year, pickedDate.month, pickedDate.day);
      });
    }
  }

  @override
  void dispose() {
    print("Disposing TransactionsForm controllers");
    _transactionDescriptionController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final accounts =
        Provider.of<AccountProvider>(context, listen: false).accounts;
    final categoryProvider = context.watch<CategoryProvider>();
    final categories = categoryProvider.categories;

    return Padding(
      padding: EdgeInsets.only(
        top: 50,
        left: 15,
        right: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Form(
        key: _formkey,
        child: ListView(
          children: [
            Text(
              _isEditMode
                  ? "Edit Recurring Transaction"
                  : 'Create New Recurring Transaction',
              style: textTheme.headlineSmall,
            ),

            const SizedBox(height: 20),

            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: DropdownButtonFormField<int>(
                    value: _selectedAccountId,
                    decoration: const InputDecoration(
                      labelText: 'Account',
                      border: OutlineInputBorder(),
                    ),

                    items:
                        accounts.map((Account account) {
                          return DropdownMenuItem<int>(
                            value: account.id,
                            child: Text(account.name),
                          );
                        }).toList(),

                    onChanged: (int? newValue) {
                      setState(() {
                        _selectedAccountId = newValue;
                      });
                    },

                    validator: (value) {
                      if (value == null) {
                        return 'Please select an account.';
                      }
                      return null;
                    },
                  ),
                ),

                Expanded(
                  flex: 1,
                  child:
                      _selectedtransactionType == TransactionType.transfer
                          ? Icon(Icons.arrow_right_alt, size: 50)
                          : SizedBox(width: 50),
                ),

                Expanded(
                  flex: 2,
                  child:
                      _selectedtransactionType == TransactionType.transfer
                          ? DropdownButtonFormField<int>(
                            value: _selectedDestinationAccountId,
                            decoration: const InputDecoration(
                              labelText: 'Account',
                              border: OutlineInputBorder(),
                            ),

                            items:
                                accounts
                                    .where(
                                      (account) =>
                                          account.id != _selectedAccountId,
                                    )
                                    .map((Account account) {
                                      return DropdownMenuItem<int>(
                                        value: account.id,
                                        child: Text(account.name),
                                      );
                                    })
                                    .toList(),
                            onChanged: (int? newValue) {
                              setState(() {
                                _selectedDestinationAccountId = newValue;
                              });
                            },
                            validator: (value) {
                              if (_selectedtransactionType ==
                                      TransactionType.transfer &&
                                  value == null) {
                                return 'Select destination account.';
                              }
                              if (_selectedtransactionType ==
                                      TransactionType.transfer &&
                                  value == _selectedAccountId) {
                                return 'Cannot transfer to the same account.';
                              }
                              return null;
                            },
                          )
                          : SizedBox(width: 30),
                ),
              ],
            ),

            const SizedBox(height: 20),

            SegmentedButton(
              segments: const <ButtonSegment<TransactionType>>[
                ButtonSegment(
                  value: TransactionType.expense,
                  label: Text('Expense'),
                ),
                ButtonSegment(
                  value: TransactionType.transfer,
                  label: Text("Transfer"),
                ),
                ButtonSegment(
                  value: TransactionType.income,
                  label: Text("Income"),
                ),
              ],

              selected: <TransactionType>{
                if (_selectedtransactionType != null) _selectedtransactionType!,
              },

              onSelectionChanged: (Set<TransactionType> newSelection) {
                setState(() {
                  _selectedtransactionType = newSelection.first;
                });
              },

              style: ButtonStyle(
                backgroundColor: WidgetStateProperty.resolveWith<Color?>((
                  Set<WidgetState> states,
                ) {
                  if (states.contains(WidgetState.selected)) {
                    if (_selectedtransactionType == TransactionType.expense) {
                      return Colors.red;
                    } else if (_selectedtransactionType ==
                        TransactionType.income) {
                      return Colors.green;
                    } else if (_selectedtransactionType ==
                        TransactionType.transfer) {
                      return Colors.blue;
                    }
                  }
                  return null; // Use default background color otherwise (usually transparent or theme-based)
                }),
                foregroundColor: WidgetStateProperty.resolveWith<Color?>((
                  Set<WidgetState> states,
                ) {
                  final theme = Theme.of(context);

                  return theme.colorScheme.onSurface;
                }),
              ),
            ),

            const SizedBox(height: 20),

            Text("Next recurring transaction date:"),

            const SizedBox(height: 20),

            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () => _selectStartDate(context),
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Date',
                        border: OutlineInputBorder(),
                        suffixIcon: Icon(Icons.calendar_today),
                      ),
                      child: Text(DateFormat('dd MM yyyy').format(_startDate)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: InkWell(
                    onTap: () => _selectEndDate(context),
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: '(Optional) End Date',
                        border: OutlineInputBorder(),
                        suffixIcon: Icon(Icons.calendar_today),
                      ),
                      child: Text(
                        _endDate != null
                            ? DateFormat('dd MM yyyy').format(_endDate!)
                            : '',
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            DropdownButtonFormField<Frequency>(
              value:
                  _selectedRecurringTransactionPeriod, // Current selected value from state
              decoration: const InputDecoration(
                labelText: 'Transaction frequency', // Label for the dropdown
                border: OutlineInputBorder(),
              ),
              // Create dropdown items from the Frequency enum values
              items:
                  Frequency.values.map((frequency) {
                    return DropdownMenuItem(
                      value: frequency, // The enum value itself
                      // Display user-friendly text (e.g., capitalize 'daily' to 'Daily')
                      child: Text(
                        frequency.name[0].toUpperCase() +
                            frequency.name.substring(1),
                      ),
                    );
                  }).toList(),
              // Update the state variable when a new item is selected
              onChanged: (Frequency? newValue) {
                setState(() {
                  _selectedRecurringTransactionPeriod = newValue;
                });
              },
              // Make selection required ONLY if the rate is > 0 (i.e., if dropdown is visible)
              validator: (value) {
                if (value == null) {
                  return 'Please select a recurring transaction frequency period.';
                }
                return null; // Valid
              },
            ),

            const SizedBox(height: 20),

            TextFormField(
              controller: _transactionDescriptionController,

              decoration: InputDecoration(
                labelText: 'Recurring Transaction Name',
                hintText: 'E.g. Salary, phone plan',
                border: OutlineInputBorder(),
              ),

              textInputAction: TextInputAction.next,

              validator: (value) {
                return null;
              },
            ),

            const SizedBox(height: 20),

            TextFormField(
              controller: _amountController,
              decoration: const InputDecoration(
                prefixText: '\$',
                border: OutlineInputBorder(),
                hintText: '0.00',
              ),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
              ],
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter an amount.';
                }
                final amount = double.tryParse(value);
                if (amount == null) {
                  return 'Please enter a valid number.';
                }
                if (amount <= 0) {
                  // Ensure amount is positive (sign handled by type?)
                  return 'Amount must be positive.';
                }
                return null; // Valid
              },
            ),

            _selectedtransactionType == TransactionType.transfer
                ? SizedBox.shrink()
                : Padding(
                  // Add overall padding for the category section
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Category:",
                        style: textTheme.titleSmall,
                      ), // Section label
                      const SizedBox(height: 8),

                      Wrap(
                        spacing: 8.0, // Horizontal space between chips
                        runSpacing: 8.0, // Vertical space between rows of chips
                        children:
                            categoryProvider.categories.map((
                              Category category,
                            ) {
                              bool isSelected =
                                  category.id == _selectedCategoryId;
                              return CategoryChip(
                                category: category,
                                isSelected: isSelected,
                                onSelected: (int? selectedId) {
                                  // When a chip is selected, update the state
                                  setState(() {
                                    _selectedCategoryId = selectedId!;
                                  });
                                },
                              );
                            }).toList(),
                      ),
                    ],
                  ),
                ),

            const SizedBox(height: 20),

            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  child: const Text('Cancel'),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),

                const SizedBox(width: 8),

                ElevatedButton(
                  onPressed: _submitForm,

                  child: Text(
                    _isEditMode ? 'Save Changes' : 'Create Transaction',
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20), // Extra padding at bottom
          ],
        ),
      ),
    );
  }
}
