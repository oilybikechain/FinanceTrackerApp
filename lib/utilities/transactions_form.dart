import 'package:finance_tracker/data/account_provider.dart';
import 'package:finance_tracker/data/accounts_class.dart';
import 'package:finance_tracker/data/transactions_provider.dart';
import 'package:flutter/material.dart';
import 'package:finance_tracker/data/transactions_class.dart';
import 'package:finance_tracker/data/recurring_transactions_class.dart';
import 'package:flutter/services.dart'; // For TextInputFormatters
import 'package:finance_tracker/data/enums.dart'; // Import your enums
import 'package:finance_tracker/data/transactions_provider.dart';
import 'package:provider/provider.dart';
import 'package:finance_tracker/data/recurring_transactions_provider.dart';
import 'package:intl/intl.dart';

//TODO, add support for changing date
class TransactionsForm extends StatefulWidget {
  final Transactions? existingTransaction;

  const TransactionsForm({super.key, this.existingTransaction});

  @override
  State<TransactionsForm> createState() => _TransactionsFormState();
}

class _TransactionsFormState extends State<TransactionsForm> {
  final _formkey = GlobalKey<FormState>();

  final _transactionDescriptionController = TextEditingController();

  final _amountController = TextEditingController();

  double _dollarValue = 0;
  double _centValue = 0;

  bool _isEditMode = false;
  DateTime _createdAt = DateTime.now();
  TransactionType? _selectedtransactionType;
  int? _selectedAccountId;

  @override
  void initState() {
    super.initState();

    final accountProvider = Provider.of<AccountProvider>(
      context,
      listen: false,
    );
    final accounts = accountProvider.accounts;

    if (widget.existingTransaction != null) {
      _isEditMode = true;
      final transaction = widget.existingTransaction!;

      _transactionDescriptionController.text = transaction.description;

      double initialAmount = transaction.amount.abs();

      _amountController.text = initialAmount.toString();

      _dollarValue = initialAmount.floorToDouble(); // Get the whole dollar part
      _centValue = ((initialAmount - _dollarValue) * 100);

      _selectedtransactionType = transaction.type;

      _selectedAccountId = transaction.accountId;

      _createdAt = transaction.timestamp;

      //TODO Add support for transfers and recurring transactions.
    } else {
      _amountController.text = "0.00";
      _selectedtransactionType = TransactionType.expense;
      _selectedAccountId = null;
      if (accounts.isNotEmpty) {
        _selectedAccountId = accounts.first.id;
      } else {
        _selectedAccountId = null;
      }
    }

    _amountController.addListener(_syncSlidersFromTextField);
  }

  Future<void> _submitForm() async {
    final isValid = _formkey.currentState?.validate() ?? false;

    if (!isValid) {
      print("form is invalid");
      //TODO Show message in snackbar
      return;
    }

    final description = _transactionDescriptionController.text;
    final amount = double.tryParse(_amountController.text) ?? 0.0;
    final transactionType = _selectedtransactionType;
    final account = _selectedAccountId;

    final transactionsProvider = Provider.of<TransactionsProvider>(
      context,
      listen: false,
    );
    final navigator = Navigator.of(context); // Store Navigator
    final messenger = ScaffoldMessenger.of(context); // Store ScaffoldMessenger
    final theme = Theme.of(context);
    double finalAmount =
        (transactionType == TransactionType.income ||
                transactionType == TransactionType.interest)
            ? amount.abs()
            : -amount.abs();

    bool success = false;

    if (_isEditMode) {
      print("Updating account ID: ${widget.existingTransaction!.id}");
      final updatedTransaction = widget.existingTransaction!.copyWith(
        description: description,
        amount: finalAmount,
        accountId: account,
        type: transactionType,
      );
      // Await the result directly from the provider
      success = await transactionsProvider.updateTransaction(
        updatedTransaction,
      );
    } else {
      print("Creating new Transaction");
      final newTransaction = Transactions(
        description: description,
        amount: finalAmount,
        accountId: account!,
        type: transactionType!,
        timestamp: _createdAt,
      );
      // Await the result directly from the provider
      success = await transactionsProvider.addTransaction(newTransaction);
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

  @override
  void dispose() {
    print("Disposing TransactionsForm controllers");
    _transactionDescriptionController.dispose();
    _amountController.removeListener(_syncSlidersFromTextField);
    _amountController.dispose();
    super.dispose();
  }

  void _updateTextFieldFromSliders() {
    double totalAmount = _dollarValue + (_centValue / 100.0);
    _amountController.removeListener(_syncSlidersFromTextField);
    _amountController.text = totalAmount.toStringAsFixed(2);
    _amountController.addListener(_syncSlidersFromTextField);
  }

  //Method to update sliders FROM text field
  void _syncSlidersFromTextField() {
    double? amountFromText = double.tryParse(_amountController.text);
    if (amountFromText != null) {
      amountFromText = amountFromText.abs();
      double newDollarValue = amountFromText.floorToDouble();
      double newCentValue = ((amountFromText - newDollarValue) * 100);

      if (newCentValue >= 0 && newCentValue <= 99) {
        bool changed = false;
        if (_dollarValue != newDollarValue) {
          _dollarValue = newDollarValue;
          changed = true;
        }
        if (_centValue != newCentValue) {
          _centValue = newCentValue;
          changed = true;
        }

        if (changed) {
          setState(() {});
        }
      }
    } else {
      setState(() {
        _dollarValue = 99;
        _centValue = 99;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final accounts =
        Provider.of<AccountProvider>(context, listen: false).accounts;

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
              _isEditMode ? "Edit Transaction" : 'Create New Transaction',
              style: textTheme.headlineSmall,
            ),

            const SizedBox(height: 20),

            DropdownButtonFormField<int>(
              // Specify type as int (for account ID)
              value:
                  _selectedAccountId, // Bind to state variable holding the ID
              decoration: const InputDecoration(
                labelText: 'Account',
                border: OutlineInputBorder(),
              ),
              // Create items from the accounts list fetched from the provider
              items:
                  accounts.map((Account account) {
                    // Iterate over Account objects
                    return DropdownMenuItem<int>(
                      value:
                          account
                              .id, // The value of the item is the account's ID
                      child: Text(
                        account.name,
                      ), // The text shown is the account's name
                    );
                  }).toList(), // Convert the mapped items to a List
              // Update state when user selects a different account
              onChanged: (int? newValue) {
                setState(() {
                  _selectedAccountId = newValue;
                });
              },
              // Validation: Ensure an account is selected
              validator: (value) {
                if (value == null) {
                  return 'Please select an account.';
                }
                return null; // Valid
              },
            ),

            const SizedBox(height: 20),

            SegmentedButton(
              segments: const <ButtonSegment<TransactionType>>[
                ButtonSegment(
                  value: TransactionType.expense,
                  label: Text('Expense'),
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
                  _selectedtransactionType = newSelection.firstOrNull;
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
                    }
                  }
                  return null; // Use default background color otherwise (usually transparent or theme-based)
                }),

                foregroundColor: WidgetStateProperty.resolveWith<Color?>((
                  Set<WidgetState> states,
                ) {
                  final theme = Theme.of(context);
                  if (states.contains(WidgetState.selected)) {
                    if (_selectedtransactionType == TransactionType.expense) {
                      return Colors.black;
                    } else if (_selectedtransactionType ==
                        TransactionType.income) {
                      return Colors.black;
                    }
                  }
                  return theme.colorScheme.onSurface;
                }),
              ),
            ),

            const SizedBox(height: 20),

            TextFormField(
              controller: _transactionDescriptionController,

              decoration: InputDecoration(
                labelText: 'Transaction Name',
                hintText: 'E.g. Food, Transport',
                border: OutlineInputBorder(),
              ),

              textInputAction: TextInputAction.next,

              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a transaction name.';
                }
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

            Text('Dollars: ${_dollarValue.toInt()}'),
            Slider(
              value: _dollarValue,
              min: 0,
              max: 100,
              divisions: 100,
              label: _dollarValue.round().toString(),
              onChanged: (newValue) {
                setState(() {
                  _dollarValue = newValue.floorToDouble();
                });
                _updateTextFieldFromSliders();
              },
            ),

            const SizedBox(height: 8),

            Text('Cents: ${_centValue.toInt()}'),

            Slider(
              value: _centValue,
              min: 0,
              max: 99,
              divisions: 99,
              label: _centValue.round().toString(),
              onChanged: (newValue) {
                setState(() {
                  _centValue = newValue.roundToDouble();
                });

                _updateTextFieldFromSliders();
              },
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
