import 'package:flutter/material.dart';
import 'package:finance_tracker/data/transactions_class.dart';
import 'package:finance_tracker/data/recurring_transactions_class.dart';
import 'package:flutter/services.dart'; // For TextInputFormatters
import 'package:finance_tracker/data/enums.dart'; // Import your enums
import 'package:finance_tracker/data/transactions_provider.dart';
import 'package:provider/provider.dart';
import 'package:finance_tracker/data/recurring_transactions_provider.dart';
import 'package:intl/intl.dart';

class TransactionsForm
    extends StatefulWidget {
  final Transactions? existingTransaction;

  const TransactionsForm({
    super.key,
    this.existingTransaction,
  });

  @override
  State<TransactionsForm> createState() =>
      _TransactionsFormState();
}

class _TransactionsFormState
    extends State<TransactionsForm> {
  final _formkey = GlobalKey<FormState>();

  final _transactionDescription =
      TextEditingController();

  final _amountController = TextEditingController();

  double _dollarValue = 0;
  double _centValue = 0;

  bool _isEditMode = false;
  DateTime _createdAt = DateTime.now();
  TransactionType? _transactionType;
  int _transactionAccountId = 1;

  @override
  void initState() {
    super.initState();

    if (widget.existingTransaction != null) {
      _isEditMode = true;
      final transaction =
          widget.existingTransaction!;

      _transactionDescription.text =
          transaction.description;
        
      double initialAmount = transaction.amount.abs();

      _amountController.text =
          transaction.amount.toString(2);

      _dollarValue = initialAmount.floorToDouble(); // Get the whole dollar part
      _centValue = ((initialAmount - _dollarValue) * 100);

      _transactionType = transaction.type;

      _transactionAccountId =
          transaction.id!;

      _createdAt = transaction.timestamp;
      //TODO fetch account name and fill up the box
      //TODO Add support for transfers and recurring transactions.
    } else {
      _amountController.text = "0.00";
    }

    _amountController.addListener(_syncSlidersFromTextField);
  }

  Future<void>  _submitForm() async {
    //TODO
  }

  @override
  void dispose() {
    //TODO
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
    final textTheme =
        Theme.of(context).textTheme;
    final colorScheme =
        Theme.of(context).colorScheme;

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
                  ? "Edit Transaction"
                  : 'Create New Transaction',
              style: textTheme.headlineSmall,
            ),

            const SizedBox(height: 20),

            TextFormField(
              controller: _transactionDescription,

              decoration: InputDecoration(
                labelText: 'Transaction Name',
                hintText:
                    'E.g. Food, Transport',
                border: OutlineInputBorder(),
              ),

              textInputAction:
                  TextInputAction.next,

              validator: (value) {
                if (value == null ||
                    value.trim().isEmpty) {
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
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
              ],
              validator: (value) {
                if (val)
              },
            )

            Slider(value: , onChanged: onChanged),

            TextFormField(
              controller:
                  _initialBalanceController,
              decoration: InputDecoration(
                labelText: 'Initial Balance',
                hintText: '0.00',
                prefixText: '\$ ',
                border: OutlineInputBorder(),
              ),

              //Only allow numbers and decimals
              keyboardType:
                  const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(
                  RegExp(r'^\d+\.?\d{0,2}'),
                ),
              ],

              textInputAction:
                  TextInputAction.next,

              validator: (value) {
                if (value == null ||
                    value.isEmpty) {
                  _initialBalanceController
                      .text = "0";
                }
                if (value != null &&
                    value.isNotEmpty &&
                    double.tryParse(value) ==
                        null) {
                  return 'Please enter a valid number.';
                }
                return null; // Return null if valid
              },
            ),

            const SizedBox(height: 20),

            TextFormField(
              controller:
                  _interestRateController,

              decoration: const InputDecoration(
                labelText:
                    'Annual Interest Rate (%)',
                hintText: '0.0',
                suffixText: '%',
                border: OutlineInputBorder(),
              ),

              keyboardType:
                  const TextInputType.numberWithOptions(
                    decimal: true,
                  ),

              inputFormatters: [
                FilteringTextInputFormatter.allow(
                  RegExp(r'^\d+\.?\d{0,2}'),
                ),
              ],

              textInputAction:
                  TextInputAction.next,
              validator: (value) {
                if (value == null ||
                    value.isEmpty) {
                  return null;
                }

                if (double.tryParse(value) ==
                    null) {
                  return 'Please enter a valid number.';
                }

                return null;
              },
              onChanged:
                  (value) => setState(() {}),
            ),

            const SizedBox(height: 20),

            if (showInterestPeriod) // Only show dropdown if rate > 0
              DropdownButtonFormField<
                Frequency
              >(
                value:
                    _selectedInterestPeriod, // Current selected value from state
                decoration: const InputDecoration(
                  labelText:
                      'Interest Period', // Label for the dropdown
                  border:
                      OutlineInputBorder(),
                ),
                // Create dropdown items from the Frequency enum values
                items:
                    Frequency.values.map((
                      frequency,
                    ) {
                      return DropdownMenuItem(
                        value:
                            frequency, // The enum value itself
                        // Display user-friendly text (e.g., capitalize 'daily' to 'Daily')
                        child: Text(
                          frequency.name[0]
                                  .toUpperCase() +
                              frequency.name
                                  .substring(
                                    1,
                                  ),
                        ),
                      );
                    }).toList(),
                // Update the state variable when a new item is selected
                onChanged: (
                  Frequency? newValue,
                ) {
                  setState(() {
                    _selectedInterestPeriod =
                        newValue;
                  });
                },
                // Make selection required ONLY if the rate is > 0 (i.e., if dropdown is visible)
                validator: (value) {
                  if (showInterestPeriod &&
                      value == null) {
                    return 'Please select an interest period.';
                  }
                  return null; // Valid
                },
              ),

            if (showInterestPeriod)
              const SizedBox(height: 24),

            Row(
              mainAxisAlignment:
                  MainAxisAlignment.end,
              children: [
                TextButton(
                  child: const Text(
                    'Cancel',
                  ),
                  onPressed: () {
                    Navigator.of(
                      context,
                    ).pop();
                  },
                ),
                const SizedBox(width: 8),

                ElevatedButton(
                  onPressed: _submitForm,

                  child: Text(
                    _isEditMode
                        ? 'Save Changes'
                        : 'Create Account',
                  ),
                ),
              ],
            ),
            const SizedBox(
              height: 20,
            ), // Extra padding at bottom
          ],
        ),
      ),
    );
  }
}
