// lib/data/account_class.dart
import 'dart:core';

import 'package:finance_tracker/data/enums.dart'; // Ensure DateTime is available

class Account {
  final int? id;
  final String name;
  final double initialBalance;
  final double interestRate;
  final Frequency? interestPeriod; // 'daily', 'monthly', 'yearly', or null
  final DateTime?
  nextInterestCreditDate; // New field: Last date interest was credited
  final DateTime createdAt;
  final int sortOrder;

  Account({
    this.id,
    required this.name,
    required this.initialBalance,
    this.interestRate = 0.0,
    this.interestPeriod,
    this.nextInterestCreditDate, // Initialize as nullable
    required this.createdAt,
    this.sortOrder = 0,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'initial_balance': initialBalance,
      'interest_rate': interestRate,
      'interest_period': interestPeriod?.name,
      'last_interest_credit_date': nextInterestCreditDate?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'sort_order': sortOrder,
    };
  }

  factory Account.fromMap(Map<String, dynamic> map) {
    // Handle nullable date string from DB
    final String? lastCreditDateString =
        map['last_interest_credit_date'] as String?;
    final String? periodString = map['interest_period'] as String?;
    Frequency? periodEnum;
    if (periodString != null) {
      periodEnum = Frequency.values.byName(periodString);
    }
    return Account(
      id: map['id'] as int?,
      name: map['name'] as String,
      initialBalance: map['initial_balance'] as double,
      interestRate: map['interest_rate'] as double? ?? 0.0,
      interestPeriod: periodEnum,
      // Parse string to DateTime only if it's not null
      nextInterestCreditDate:
          lastCreditDateString == null
              ? null
              : DateTime.parse(lastCreditDateString),
      createdAt: DateTime.parse(map['created_at'] as String),
      sortOrder: map['sort_order'] as int? ?? 0,
    );
  }

  Account copyWith({
    int? id,
    String? name,
    double? initialBalance,
    double? interestRate,
    Frequency? interestPeriod,
    bool setInterestPeriodNull = false,
    DateTime? nextInterestCreditDate,
    bool setnextInterestCreditDateNull = false, // Flag to explicitly nullify
    DateTime? createdAt,
    int? sortOrder,
  }) {
    return Account(
      id: id ?? this.id,
      name: name ?? this.name,
      initialBalance: initialBalance ?? this.initialBalance,
      interestRate: interestRate ?? this.interestRate,
      interestPeriod:
          setInterestPeriodNull
              ? null
              : (interestPeriod ?? this.interestPeriod),
      nextInterestCreditDate:
          setnextInterestCreditDateNull
              ? null
              : (nextInterestCreditDate ?? this.nextInterestCreditDate),
      createdAt: createdAt ?? this.createdAt,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }

  @override
  String toString() {
    return 'Account{id: $id, name: $name, initialBalance: $initialBalance, nextInterestCreditDate: $nextInterestCreditDate, sortOrder: $sortOrder, createdAt: $createdAt}';
  }
}
