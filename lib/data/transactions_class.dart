// lib/data/transactions_class.dart
import 'enums.dart'; // Import the enums

// --- RENAMED CLASS ---
class Transactions { // <--- Renamed
  final int? id;
  final int accountId;
  final TransactionType type;
  final double amount;
  final DateTime timestamp;
  final String? description;
  final int? transferPeerTransactionId;

  // --- Constructor name matches class ---
  Transactions({ // <--- Renamed
    this.id,
    required this.accountId,
    required this.type,
    required this.amount,
    required this.timestamp,
    this.description,
    this.transferPeerTransactionId,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'account_id': accountId,
      'type': type.name,
      'amount': amount,
      'timestamp': timestamp.toIso8601String(),
      'description': description,
      'transfer_peer_transaction_id': transferPeerTransactionId,
    };
  }

  // --- Factory constructor name matches class ---
  factory Transactions.fromMap(Map<String, dynamic> map) { // <--- Renamed
    final transactionType = TransactionType.values.fromName(
      map['type'] as String?,
      defaultValue: TransactionType.expense
    ) ?? TransactionType.expense;

    // --- Return type matches class ---
    return Transactions( // <--- Renamed
      id: map['id'] as int?,
      accountId: map['account_id'] as int,
      type: transactionType,
      amount: map['amount'] as double,
      timestamp: DateTime.parse(map['timestamp'] as String),
      description: map['description'] as String?,
      transferPeerTransactionId: map['transfer_peer_transaction_id'] as int?,
    );
  }

  // --- copyWith method name and return type match class ---
  Transactions copyWith({ // <--- Renamed return type
    int? id,
    int? accountId,
    TransactionType? type,
    double? amount,
    DateTime? timestamp,
    String? description,
    bool setDescriptionNull = false,
    int? transferPeerTransactionId,
    bool setTransferPeerNull = false,
  }) {
    // --- Return type matches class ---
    return Transactions( // <--- Renamed constructor call
      id: id ?? this.id,
      accountId: accountId ?? this.accountId,
      type: type ?? this.type,
      amount: amount ?? this.amount,
      timestamp: timestamp ?? this.timestamp,
      description: setDescriptionNull ? null : (description ?? this.description),
      transferPeerTransactionId: setTransferPeerNull ? null : (transferPeerTransactionId ?? this.transferPeerTransactionId),
    );
  }

  @override
  String toString() {
    // --- Update class name in string ---
    return 'Transactions{id: $id, accountId: $accountId, type: ${type.name}, amount: $amount, timestamp: $timestamp}'; // <--- Renamed
  }
}