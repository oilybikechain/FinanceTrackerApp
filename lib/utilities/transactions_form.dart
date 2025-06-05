import 'package:finance_tracker/data/category_class.dart';
import 'package:finance_tracker/services/account_provider.dart';
import 'package:finance_tracker/data/accounts_class.dart';
import 'package:finance_tracker/services/category_provider.dart';
import 'package:finance_tracker/services/transactions_provider.dart';
import 'package:finance_tracker/utilities/category_chip.dart';
import 'package:flutter/material.dart';
import 'package:finance_tracker/data/transactions_class.dart';
import 'package:finance_tracker/data/recurring_transactions_class.dart';
import 'package:flutter/services.dart'; // For TextInputFormatters
import 'package:finance_tracker/data/enums.dart'; // Import your enums
import 'package:finance_tracker/services/transactions_provider.dart';
import 'package:provider/provider.dart';
import 'package:finance_tracker/services/recurring_transactions_provider.dart';
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
  double _maxDollarSliderValue = 100;

  bool _isEditMode = false;
  DateTime _transactionDateTime = DateTime.now();
  TransactionType? _selectedtransactionType;
  int? _selectedAccountId;
  int? _selectedDestinationAccountId;
  int _selectedCategoryId = 1;
  bool _isLoadingDefaults = false;
  Transactions? peerTransaction;

  @override
  void initState() {
    super.initState();
    _prefillFormData();
    _amountController.addListener(_syncSlidersFromTextField);
  }

  Future<void> _prefillFormData() async {
    final accountProvider = Provider.of<AccountProvider>(
      context,
      listen: false,
    );
    final categoryProvider = Provider.of<CategoryProvider>(
      context,
      listen: false,
    );
    final transactionsProvider = Provider.of<TransactionsProvider>(
      context,
      listen: false,
    );

    final accounts = accountProvider.accounts;
    List<Category> categories = categoryProvider.categories;

    if (categories.isEmpty && !categoryProvider.isLoading) {
      categoryProvider.fetchCategories();
      categories = categoryProvider.categories;
    }

    if (widget.existingTransaction != null) {
      if (widget.existingTransaction!.type == TransactionType.transfer) {
        //TODO}
      }

      _isEditMode = true;
      final transaction = widget.existingTransaction!;

      _transactionDescriptionController.text = transaction.description!;

      double initialAmount = transaction.amount.abs();

      _amountController.text = initialAmount.toString();

      _dollarValue = initialAmount.floorToDouble(); // Get the whole dollar part
      _centValue = ((initialAmount - _dollarValue) * 100).roundToDouble();

      _selectedtransactionType = transaction.type;

      _selectedAccountId = transaction.accountId;

      _transactionDateTime = transaction.timestamp;

      if (initialAmount > 100) {
        _maxDollarSliderValue = initialAmount;
      }

      _selectedCategoryId = transaction.categoryId;

      if (widget.existingTransaction!.type == TransactionType.transfer) {
        print(
          "Existing Transaction: ID=${widget.existingTransaction?.id}, Type=${widget.existingTransaction?.type}, PeerID=${widget.existingTransaction?.transferPeerTransactionId}",
        );
        peerTransaction = await transactionsProvider.fetchTransactionById(
          transactionId: widget.existingTransaction!.transferPeerTransactionId!,
        );
        _selectedDestinationAccountId = peerTransaction!.accountId;
      }
    } else {
      _amountController.text = "0.00";
      _selectedtransactionType = TransactionType.expense;

      if (accounts.isNotEmpty) {
        _selectedAccountId = accounts.first.id;
        _selectedDestinationAccountId = null;
      } else {
        _selectedAccountId = null;
        _selectedDestinationAccountId = null;
      }

      _selectedCategoryId = 1;
    }
    setState(() {});
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _transactionDateTime, // Pre-select current date
      firstDate: DateTime(2000), // Earliest selectable date
      lastDate: DateTime(2101), // Latest selectable date
    );
    if (pickedDate != null && pickedDate != _transactionDateTime) {
      setState(() {
        // Combine picked date with existing time
        _transactionDateTime = DateTime(
          pickedDate.year,
          pickedDate.month,
          pickedDate.day,
          _transactionDateTime.hour,
          _transactionDateTime.minute,
        );
      });
    }
  }

  // --- ADDED: Time Picker ---
  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(
        _transactionDateTime,
      ), // Pre-select current time
    );
    if (pickedTime != null) {
      setState(() {
        // Combine existing date with picked time
        _transactionDateTime = DateTime(
          _transactionDateTime.year,
          _transactionDateTime.month,
          _transactionDateTime.day,
          pickedTime.hour,
          pickedTime.minute,
        );
      });
    }
  }

  Future<void> _submitForm() async {
    final isValid = _formkey.currentState?.validate() ?? false;
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);

    if (!isValid) {
      print("form is invalid");
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Invalid source/destination for transfer.'),
        ),
      );
      return;
    }

    String description = _transactionDescriptionController.text.trim();
    final amount = double.tryParse(_amountController.text) ?? 0.0;
    final transactionType = _selectedtransactionType;
    final account = _selectedAccountId;
    final selectedCategoryId = _selectedCategoryId;
    final transactionTimestamp = _transactionDateTime;
    final transferCategoryId = 2;

    final transactionsProvider = Provider.of<TransactionsProvider>(
      context,
      listen: false,
    );
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
      if (_selectedtransactionType == TransactionType.transfer) {
        success = await transactionsProvider.updateTransfer(
          originalOutgoingTransactionId:
              widget
                  .existingTransaction!
                  .id!, // Pass the ID of the tx being edited
          newFromAccountId: account!,
          newToAccountId: _selectedDestinationAccountId!,
          newAmount: amount.abs(), // Send positive amount
          newTimestamp: transactionTimestamp,
          newDescription: description,
          newTransferCategoryId: 2,
        );
      } else {
        print("Updating account ID: ${widget.existingTransaction!.id}");
        final updatedTransaction = widget.existingTransaction!.copyWith(
          description: description,
          amount: finalAmount,
          accountId: account,
          type: transactionType,
          timestamp: transactionTimestamp,
          categoryId: selectedCategoryId,
        );
        // Await the result directly from the provider
        success = await transactionsProvider.updateTransaction(
          updatedTransaction,
        );
      }
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
        print("Creating new Transfer");
        success = await transactionsProvider.addTransfer(
          fromAccountId: _selectedAccountId!,
          toAccountId: _selectedDestinationAccountId!,
          amount: amount, // Pass positive amount, service handles sign
          timestamp: transactionTimestamp,
          description: description.isEmpty ? "Transfer" : description,
          transferCategoryId:
              transferCategoryId, // Use the "Transfer" category ID
        );
      } else {
        print("Creating new Transaction");
        final newTransaction = Transactions(
          description: description,
          amount: finalAmount,
          accountId: account!,
          type: transactionType!,
          timestamp: transactionTimestamp, // <<< USE SELECTED TIMESTAMP
          categoryId: selectedCategoryId,
        );
        // Await the result directly from the provider
        success = await transactionsProvider.addTransaction(newTransaction);
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
        if (newDollarValue > _maxDollarSliderValue) {
          _maxDollarSliderValue = newDollarValue;
          changed = true;
        }
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
        _dollarValue = 0;
        _centValue = 0;
        _maxDollarSliderValue = 100;
      });
    }
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
              _isEditMode ? "Edit Transaction" : 'Create New Transaction',
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

            IgnorePointer(
              ignoring: _isEditMode,
              child: Opacity(
                opacity: _isEditMode ? 0.6 : 1.0,
                child: SegmentedButton(
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
                    if (_selectedtransactionType != null)
                      _selectedtransactionType!,
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
                        if (_selectedtransactionType ==
                            TransactionType.expense) {
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
              ),
            ),

            const SizedBox(height: 20),

            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () => _selectDate(context),
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Date',
                        border: OutlineInputBorder(),
                        suffixIcon: Icon(Icons.calendar_today),
                      ),
                      child: Text(
                        DateFormat('dd MMM yyyy').format(_transactionDateTime),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: InkWell(
                    onTap: () => _selectTime(context),
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Time',
                        border: OutlineInputBorder(),
                        suffixIcon: Icon(Icons.access_time),
                      ),
                      child: Text(
                        DateFormat('hh:mm a').format(_transactionDateTime),
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            TextFormField(
              controller: _transactionDescriptionController,

              decoration: InputDecoration(
                labelText: 'Transaction Name',
                hintText: 'E.g. Food, Transport, will default to Category name',
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

            Text('Dollars: ${_dollarValue.toInt()}'),
            Slider(
              value: _dollarValue,
              min: 0,
              max: _maxDollarSliderValue,
              divisions: _maxDollarSliderValue.toInt(),
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
