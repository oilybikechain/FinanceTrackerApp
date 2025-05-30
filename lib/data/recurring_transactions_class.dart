import 'enums.dart'; // Your enums

class RecurringTransaction {
  final int? id;
  final int accountId;
  final RecurringTransactionType type;
  final double amount;
  final String? description;
  final Frequency frequency;
  final DateTime startDate;
  final DateTime nextDueDate;
  final DateTime? endDate;
  final int? transferToAccountId;
  final int categoryId; // <<< ADDED: Required foreign key to categories table
  final bool isInterestRule;
  final bool isSystemGenerated;

  RecurringTransaction({
    this.id,
    required this.accountId,
    required this.type,
    required this.amount,
    this.description,
    required this.frequency,
    required this.startDate,
    required this.nextDueDate,
    required this.categoryId, // <<< ADDED: Make it required
    this.endDate,
    this.transferToAccountId,
    this.isInterestRule = false,
    this.isSystemGenerated = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'account_id': accountId,
      'type': type.name,
      'amount': amount,
      'description': description,
      'frequency': frequency.name,
      'start_date': startDate.toIso8601String().substring(0, 10),
      'next_due_date': nextDueDate.toIso8601String().substring(0, 10),
      'end_date': endDate?.toIso8601String().substring(0, 10),
      'transfer_to_account_id': transferToAccountId,
      'category_id': categoryId, // <<< ADDED
      'is_interest_rule': isInterestRule ? 1 : 0,
      'is_system_generated': isSystemGenerated ? 1 : 0,
    };
  }

  factory RecurringTransaction.fromMap(Map<String, dynamic> map) {
    return RecurringTransaction(
      id: map['id'] as int?,
      accountId: map['account_id'] as int,
      type:
          RecurringTransactionType.values.fromName(map['type'] as String?) ??
          RecurringTransactionType.expense,
      amount: map['amount'] as double,
      description: map['description'] as String?,
      frequency:
          Frequency.values.fromName(map['frequency'] as String?) ??
          Frequency.monthly,
      startDate: DateTime.parse(map['start_date'] as String),
      nextDueDate: DateTime.parse(map['next_due_date'] as String),
      endDate:
          map['end_date'] == null
              ? null
              : DateTime.parse(map['end_date'] as String),
      transferToAccountId: map['transfer_to_account_id'] as int?,
      categoryId: map['category_id'] as int? ?? 1,
      isInterestRule: (map['is_interest_rule'] as int? ?? 0) == 1,
      isSystemGenerated: (map['is_system_generated'] as int? ?? 0) == 1,
    );
  }

  RecurringTransaction copyWith({
    int? id,
    int? accountId,
    RecurringTransactionType? type,
    double? amount,
    String? description,
    bool setDescriptionNull = false,
    Frequency? frequency,
    DateTime? startDate,
    DateTime? nextDueDate,
    DateTime? endDate,
    bool setEndDateNull = false,
    int? transferToAccountId,
    bool setTransferToAccountIdNull = false,
    int? categoryId, // <<< ADDED
    bool? isInterestRule,
    bool? isSystemGenerated,
  }) {
    return RecurringTransaction(
      id: id ?? this.id,
      accountId: accountId ?? this.accountId,
      type: type ?? this.type,
      amount: amount ?? this.amount,
      description:
          setDescriptionNull ? null : (description ?? this.description),
      frequency: frequency ?? this.frequency,
      startDate: startDate ?? this.startDate,
      nextDueDate: nextDueDate ?? this.nextDueDate,
      endDate: setEndDateNull ? null : (endDate ?? this.endDate),
      transferToAccountId:
          setTransferToAccountIdNull
              ? null
              : (transferToAccountId ?? this.transferToAccountId),
      categoryId: categoryId ?? this.categoryId, // <<< ADDED
      isInterestRule: isInterestRule ?? this.isInterestRule,
      isSystemGenerated: isSystemGenerated ?? this.isSystemGenerated,
    );
  }

  @override
  String toString() {
    return 'RecurringTransaction{id: $id, type: ${type.name}, categoryId: $categoryId, amount: $amount, frequency: ${frequency.name}, nextDue: $nextDueDate}';
  }
}
