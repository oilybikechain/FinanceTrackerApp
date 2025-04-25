// lib/data/recurring_transaction_class.dart
import 'enums.dart'; // Import the enums

class RecurringTransaction {
  final int? id;
  final int accountId;
  final RecurringTransactionType type; // Changed from String to Enum
  final double amount;
  final String? description;
  final Frequency frequency; // Changed from String to Enum
  final DateTime startDate;
  final DateTime nextDueDate;
  final DateTime? endDate;
  final int? transferToAccountId;

  RecurringTransaction({
    this.id,
    required this.accountId,
    required this.type, // Requires enum value
    required this.amount,
    this.description,
    required this.frequency, // Requires enum value
    required this.startDate,
    required this.nextDueDate,
    this.endDate,
    this.transferToAccountId,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'account_id': accountId,
      'type': type.name, // Store enum name as string
      'amount': amount,
      'description': description,
      'frequency': frequency.name, // Store enum name as string
      'start_date': startDate.toIso8601String().substring(0, 10),
      'next_due_date': nextDueDate.toIso8601String().substring(0, 10),
      'end_date': endDate?.toIso8601String().substring(0, 10),
      'transfer_to_account_id': transferToAccountId,
    };
  }

  factory RecurringTransaction.fromMap(Map<String, dynamic> map) {
     // Parse enums from DB strings
    final recurringType = RecurringTransactionType.values.fromName(
      map['type'] as String?,
      defaultValue: RecurringTransactionType.expense // Choose a sensible default
    ) ?? RecurringTransactionType.expense;

     final freq = Frequency.values.fromName(
      map['frequency'] as String?,
      defaultValue: Frequency.monthly // Choose a sensible default
    ) ?? Frequency.monthly;


    return RecurringTransaction(
      id: map['id'] as int?,
      accountId: map['account_id'] as int,
      type: recurringType, // Use parsed enum
      amount: map['amount'] as double,
      description: map['description'] as String?,
      frequency: freq, // Use parsed enum
      startDate: DateTime.parse(map['start_date'] as String),
      nextDueDate: DateTime.parse(map['next_due_date'] as String),
      endDate: map['end_date'] == null ? null : DateTime.parse(map['end_date'] as String),
      transferToAccountId: map['transfer_to_account_id'] as int?,
    );
  }

  RecurringTransaction copyWith({
    int? id,
    int? accountId,
    RecurringTransactionType? type, // Changed to enum
    double? amount,
    String? description,
    bool setDescriptionNull = false,
    Frequency? frequency, // Changed to enum
    DateTime? startDate,
    DateTime? nextDueDate,
    DateTime? endDate,
    bool setEndDateNull = false,
    int? transferToAccountId,
    bool setTransferToAccountIdNull = false,
  }) {
    return RecurringTransaction(
      id: id ?? this.id,
      accountId: accountId ?? this.accountId,
      type: type ?? this.type,
      amount: amount ?? this.amount,
      description: setDescriptionNull ? null : (description ?? this.description),
      frequency: frequency ?? this.frequency,
      startDate: startDate ?? this.startDate,
      nextDueDate: nextDueDate ?? this.nextDueDate,
      endDate: setEndDateNull ? null : (endDate ?? this.endDate),
      transferToAccountId: setTransferToAccountIdNull ? null : (transferToAccountId ?? this.transferToAccountId),
    );
  }

   @override
  String toString() {
    return 'RecurringTransaction{id: $id, accountId: $accountId, type: ${type.name}, amount: $amount, frequency: ${frequency.name}, nextDue: $nextDueDate}';
  }
}