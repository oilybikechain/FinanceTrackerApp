import 'enums.dart';

class Transactions {
  final int? id;
  final int accountId;
  final TransactionType type;
  final double amount;
  final DateTime timestamp;
  final String? description;
  final int categoryId;
  final int? transferPeerTransactionId;
  final int? recurringTransactionId;

  Transactions({
    this.id,
    required this.accountId,
    required this.type,
    required this.amount,
    required this.timestamp,
    this.description,
    required this.categoryId,
    this.transferPeerTransactionId,
    this.recurringTransactionId,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'account_id': accountId,
      'type': type.name,
      'amount': amount,
      'timestamp': timestamp.toIso8601String(),
      'description': description,
      'category_id': categoryId,
      'transfer_peer_transaction_id': transferPeerTransactionId,
      'recurring_transaction_id': recurringTransactionId,
    };
  }

  factory Transactions.fromMap(Map<String, dynamic> map) {
    return Transactions(
      id: map['id'] as int?,
      accountId: map['account_id'] as int,
      type:
          TransactionType.values.fromName(
            map['type'] as String?,
            defaultValue: TransactionType.expense,
          ) ??
          TransactionType.expense,
      amount: map['amount'] as double,
      timestamp: DateTime.parse(map['timestamp'] as String),
      description: map['description'] as String?,
      categoryId: map['category_id'] as int? ?? 1, // <<< ADDED
      transferPeerTransactionId: map['transfer_peer_transaction_id'] as int?,
      recurringTransactionId: map['recurring_transaction_id'] as int?,
    );
  }

  // --- copyWith method name and return type match class ---
  Transactions copyWith({
    // <--- Renamed return type
    int? id,
    int? accountId,
    TransactionType? type,
    double? amount,
    DateTime? timestamp,
    String? description,
    bool setDescriptionNull = false,
    int? categoryId,
    int? transferPeerTransactionId,
    bool setTransferPeerNull = false,
    int? recurringTransactionId,
    bool setRecurringTransactionIdNull = false,
  }) {
    // --- Return type matches class ---
    return Transactions(
      // <--- Renamed constructor call
      id: id ?? this.id,
      accountId: accountId ?? this.accountId,
      type: type ?? this.type,
      amount: amount ?? this.amount,
      timestamp: timestamp ?? this.timestamp,
      description:
          setDescriptionNull ? null : (description ?? this.description),
      categoryId: categoryId ?? 1,
      transferPeerTransactionId:
          setTransferPeerNull
              ? null
              : (transferPeerTransactionId ?? this.transferPeerTransactionId),
      recurringTransactionId:
          setRecurringTransactionIdNull
              ? null
              : (recurringTransactionId ?? this.recurringTransactionId),
    );
  }

  @override
  String toString() {
    // --- Update class name in string ---
    return 'Transactions{id: $id, accountId: $accountId, type: ${type.name}, amount: $amount, timestamp: $timestamp, categoryId: $categoryId, recurringId: $recurringTransactionId, transferPeerId: $transferPeerTransactionId}';
  }
}
