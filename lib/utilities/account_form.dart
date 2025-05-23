import 'package:flutter/material.dart';
import 'package:finance_tracker/data/accounts_class.dart';
import 'package:finance_tracker/data/recurring_transactions_class.dart';
import 'package:flutter/services.dart'; // For TextInputFormatters
import 'package:finance_tracker/data/enums.dart'; // Import your enums
import 'package:finance_tracker/services/account_provider.dart';
import 'package:provider/provider.dart';
import 'package:finance_tracker/services/recurring_transactions_provider.dart';
import 'package:intl/intl.dart';

class AccountForm extends StatefulWidget {
  final Account? existingAccount;

  const AccountForm({super.key, this.existingAccount});

  @override
  State<AccountForm> createState() => _AccountFormState();
}

class _AccountFormState extends State<AccountForm> {
  //Form Key
  final _formkey = GlobalKey<FormState>();

  //Controllers
  final _nameController = TextEditingController();
  final _initialBalanceController = TextEditingController();
  final _interestRateController = TextEditingController();

  //Other Variables
  bool _isEditMode = false;
  DateTime _createdAt = DateTime.now();

  // Enum for selected frequency
  Frequency? _selectedInterestPeriod;

  // init state method: What happens when it detects an initial account
  @override
  void initState() {
    //Must call super.initState whenever initState is being overridden
    super.initState();

    //If initialAccount is detected it means the form is in edit mode
    if (widget.existingAccount != null) {
      _isEditMode = true;
      final account = widget.existingAccount!;

      //Prefill controllers with existing account data
      _nameController.text = account.name;

      _initialBalanceController.text = account.initialBalance.toStringAsFixed(
        2,
      );

      if (account.interestRate > 0) {
        _interestRateController.text = account.interestRate.toStringAsFixed(2);
      }

      if (account.interestPeriod != null) {
        _selectedInterestPeriod = Frequency.values.fromName(
          account.interestPeriod,
        );
      }

      _createdAt = account.createdAt;
    }
  }

  //Method to save
  Future<void> _submitForm() async {
    print("Save button pressed!");
    //Check if form is valid
    final isValid = _formkey.currentState?.validate() ?? false;

    if (!isValid) {
      print("form is invalid");
      return;
      //TODO pop up for invalid form
    }

    print("Form is valid, proceeding to save...");

    // 3. Prepare data (as before)
    final name = _nameController.text;
    final initialBalance =
        double.tryParse(_initialBalanceController.text) ?? 0.0;
    final interestRate = double.tryParse(_interestRateController.text) ?? 0.0;
    final String? interestPeriodString =
        (interestRate > 0 && _selectedInterestPeriod != null)
            ? _selectedInterestPeriod!.name
            : null;

    // 4. Store context-dependent objects BEFORE await
    // This prevents using 'context' after an async gap, which is unsafe.
    final accountProvider = Provider.of<AccountProvider>(
      context,
      listen: false,
    );
    final navigator = Navigator.of(context); // Store Navigator
    final messenger = ScaffoldMessenger.of(context); // Store ScaffoldMessenger
    final theme = Theme.of(context); // Store Theme

    // Variable to hold the result from the provider call
    bool success = false;

    // 5. Call the appropriate provider method (NO outer try-catch here)
    if (_isEditMode) {
      print("Updating account ID: ${widget.existingAccount!.id}");
      final updatedAccount = widget.existingAccount!.copyWith(
        name: name,
        // Don't update initialBalance or createdAt in edit mode usually
        interestRate: interestRate,
        interestPeriod: interestPeriodString,
        setInterestPeriodNull:
            interestRate <= 0 || _selectedInterestPeriod == null,
      );
      // Await the result directly from the provider
      success = await accountProvider.updateAccount(updatedAccount);
    } else {
      print("Creating new account");
      final newAccount = Account(
        name: name,
        initialBalance: initialBalance,
        createdAt: _createdAt,
        interestRate: interestRate,
        interestPeriod: interestPeriodString,
      );
      // Await the result directly from the provider
      success = await accountProvider.addAccount(newAccount);
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

  //Method to delete controllers
  @override
  void dispose() {
    print("Disposing AccountForm controllers");
    _nameController.dispose();
    _initialBalanceController.dispose();
    _interestRateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final bool showInterestPeriod =
        (double.tryParse(_interestRateController.text) ?? 0) > 0;

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
              _isEditMode ? "Edit Account" : 'Create New Account',
              style: textTheme.headlineSmall,
            ),

            const SizedBox(height: 20),

            TextFormField(
              controller: _nameController,

              decoration: InputDecoration(
                labelText: 'Account Name',
                hintText: 'E.g. Savings, Spendings',
                border: OutlineInputBorder(),
              ),

              textInputAction: TextInputAction.next,

              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter an account name.';
                }
                return null;
              },
            ),

            const SizedBox(height: 20),

            TextFormField(
              controller: _initialBalanceController,
              decoration: InputDecoration(
                labelText: 'Initial Balance',
                hintText: '0.00',
                prefixText: '\$ ',
                border: OutlineInputBorder(),
              ),

              //Only allow numbers and decimals
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
              ],

              textInputAction: TextInputAction.next,

              validator: (value) {
                if (value == null || value.isEmpty) {
                  _initialBalanceController.text = "0";
                }
                if (value != null &&
                    value.isNotEmpty &&
                    double.tryParse(value) == null) {
                  return 'Please enter a valid number.';
                }
                return null; // Return null if valid
              },
            ),

            const SizedBox(height: 20),

            TextFormField(
              controller: _interestRateController,

              decoration: const InputDecoration(
                labelText: 'Annual Interest Rate (%)',
                hintText: '0.0',
                suffixText: '%',
                border: OutlineInputBorder(),
              ),

              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),

              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
              ],

              textInputAction: TextInputAction.next,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return null;
                }

                if (double.tryParse(value) == null) {
                  return 'Please enter a valid number.';
                }

                return null;
              },
              onChanged: (value) => setState(() {}),
            ),

            const SizedBox(height: 20),

            if (showInterestPeriod) // Only show dropdown if rate > 0
              DropdownButtonFormField<Frequency>(
                value:
                    _selectedInterestPeriod, // Current selected value from state
                decoration: const InputDecoration(
                  labelText: 'Interest Period', // Label for the dropdown
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
                    _selectedInterestPeriod = newValue;
                  });
                },
                // Make selection required ONLY if the rate is > 0 (i.e., if dropdown is visible)
                validator: (value) {
                  if (showInterestPeriod && value == null) {
                    return 'Please select an interest period.';
                  }
                  return null; // Valid
                },
              ),

            if (showInterestPeriod) const SizedBox(height: 24),

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

                  child: Text(_isEditMode ? 'Save Changes' : 'Create Account'),
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
