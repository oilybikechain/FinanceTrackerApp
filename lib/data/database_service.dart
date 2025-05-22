import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:finance_tracker/data/accounts_class.dart';
import 'package:finance_tracker/data/transactions_class.dart';
import 'package:finance_tracker/data/recurring_transactions_class.dart';
import 'package:finance_tracker/data/enums.dart';

class DatabaseService {
  // --- Singleton Setup ---
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  static Database? _database; // Cache the database instance

  // --- Database Initialization ---
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentsDirectory.path, 'finance_tracker_v1.db');
    print("Database path: $path"); // Debugging: print the path

    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  // --- Schema Creation (Runs ONLY if DB file doesn't exist) ---
  Future<void> _onCreate(Database db, int version) async {
    print("Creating database tables (version $version)...");
    Batch batch = db.batch();

    batch.execute('''
      CREATE TABLE accounts (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL UNIQUE,
          initial_balance REAL NOT NULL DEFAULT 0.0,
          interest_rate REAL DEFAULT 0.0,
          interest_period TEXT,
          last_interest_credit_date TEXT NULL, -- <<< ADDED FIELD
          created_at TEXT NOT NULL,
          sort_order INTEGER NOT NULL DEFAULT 0
      );
    ''');

    batch.execute('''
      CREATE TABLE transactions (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          account_id INTEGER NOT NULL,
          type TEXT NOT NULL, -- Stores TransactionType.name
          amount REAL NOT NULL,
          timestamp TEXT NOT NULL,
          description TEXT,
          transfer_peer_transaction_id INTEGER NULL,
          FOREIGN KEY (account_id) REFERENCES accounts(id) ON DELETE CASCADE
      );
    ''');
    batch.execute(
      'CREATE INDEX idx_transactions_account_timestamp ON transactions (account_id, timestamp);',
    );

    batch.execute('''
      CREATE TABLE recurring_transactions (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          account_id INTEGER NOT NULL,
          type TEXT NOT NULL, -- Stores RecurringTransactionType.name
          amount REAL NOT NULL,
          description TEXT,
          frequency TEXT NOT NULL, -- Stores Frequency.name
          start_date TEXT NOT NULL,
          next_due_date TEXT NOT NULL,
          end_date TEXT NULL,
          transfer_to_account_id INTEGER NULL,
          FOREIGN KEY (account_id) REFERENCES accounts(id) ON DELETE CASCADE,
          FOREIGN KEY (transfer_to_account_id) REFERENCES accounts(id) ON DELETE SET NULL
      );
    ''');

    await batch.commit(noResult: true);
    print("Database tables created!");
  }

  // --- Schema Migration (Runs when version number increases) ---
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    print("Upgrading database from version $oldVersion to $newVersion...");
  }

  // =====================================================================
  // CRUD Operations for Accounts
  // =====================================================================

  Future<int> insertAccount(Account account) async {
    Database db = await database;
    try {
      return await db.insert(
        'accounts',
        account.toMap()
          ..remove('id'), // Use toMap, remove ID for auto-increment
        conflictAlgorithm:
            ConflictAlgorithm
                .replace, // Or .fail if name must be unique on insert
      );
    } catch (e) {
      print("Error inserting account: $e");
      print("Account data: ${account.toMap()}");
      rethrow; // Re-throw the exception to be handled by the caller
    }
  }

  Future<List<Account>> getAccounts() async {
    Database db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'accounts',
      orderBy: 'sort_order ASC',
    );
    return List.generate(maps.length, (i) => Account.fromMap(maps[i]));
  }

  Future<Account?> getAccountById(int id) async {
    Database db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'accounts',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    return maps.isNotEmpty ? Account.fromMap(maps.first) : null;
  }

  Future<int> updateAccount(Account account) async {
    Database db = await database;
    return await db.update(
      'accounts',
      account.toMap(), // Use toMap to get all fields
      where: 'id = ?',
      whereArgs: [account.id],
    );
  }

  Future<void> updateAccountSortOrder(List<Account> orderedAccounts) async {
    Database db = await database;
    await db.transaction((txn) async {
      Batch batch = txn.batch();
      for (int i = 0; i < orderedAccounts.length; i++) {
        batch.update(
          'accounts',
          {'sort_order': i},
          where: 'id = ?',
          whereArgs: [orderedAccounts[i].id],
        );
      }
      await batch.commit(noResult: true);
    });
  }

  Future<int> deleteAccount(int id) async {
    Database db = await database;
    // Note: ON DELETE CASCADE will handle deleting related transactions.
    return await db.delete('accounts', where: 'id = ?', whereArgs: [id]);
  }

  // =====================================================================
  // CRUD Operations for Transactions
  // =====================================================================

  Future<int> insertTransaction(Transactions transaction) async {
    Database db = await database;
    try {
      return await db.insert(
        'transactions',
        transaction.toMap()..remove('id'), // Use toMap, remove ID
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (e) {
      print("Error inserting transaction: $e");
      print("Transaction data: ${transaction.toMap()}");
      rethrow;
    }
  }

  // Get transactions, optionally filtered by account(s) and date range
  Future<List<Transactions>> getTransactions({
    List<int>? accountIds, // Filter by specific accounts
    DateTime? startDate, // Inclusive start date
    DateTime? endDate, // Exclusive end date
    int? limit, // Optional limit for pagination/recent items
  }) async {
    Database db = await database;
    List<String> whereClauses = [];
    List<dynamic> whereArgs = [];

    if (accountIds != null && accountIds.isNotEmpty) {
      // Create placeholders for account IDs: (?, ?, ?)
      String placeholders = List.filled(accountIds.length, '?').join(', ');
      whereClauses.add('account_id IN ($placeholders)');
      whereArgs.addAll(accountIds);
    }

    if (startDate != null) {
      whereClauses.add('timestamp >= ?');
      // Store timestamps precisely with time component
      whereArgs.add(startDate.toIso8601String());
    }

    if (endDate != null) {
      whereClauses.add('timestamp < ?');
      // Store timestamps precisely with time component
      whereArgs.add(endDate.toIso8601String());
    }

    String? whereString =
        whereClauses.isNotEmpty ? whereClauses.join(' AND ') : null;

    final List<Map<String, dynamic>> maps = await db.query(
      'transactions',
      where: whereString,
      whereArgs: whereArgs.isNotEmpty ? whereArgs : null,
      orderBy: 'timestamp DESC', // Most recent first by default
      limit: limit,
    );

    return List.generate(maps.length, (i) => Transactions.fromMap(maps[i]));
  }

  Future<Transactions?> getTransactionById(int id) async {
    Database db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'transactions',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    return maps.isNotEmpty ? Transactions.fromMap(maps.first) : null;
  }

  Future<int> updateTransaction(Transactions transaction) async {
    Database db = await database;
    return await db.update(
      'transactions',
      transaction.toMap(),
      where: 'id = ?',
      whereArgs: [transaction.id],
    );
  }

  Future<int> deleteTransaction(int id) async {
    Database db = await database;
    return await db.delete('transactions', where: 'id = ?', whereArgs: [id]);
  }

  // Add specific query methods as needed, e.g., calculate balance:
  Future<double> getAccountBalance(int accountId) async {
    Database db = await database;
    // Use try-catch for robustness, though Provider should handle errors
    try {
      // Get initial balance safely
      final List<Map<String, dynamic>> accData = await db.query(
        'accounts',
        columns: ['initial_balance'],
        where: 'id = ?',
        whereArgs: [accountId],
        limit: 1,
      );
      // Use firstOrNull (from collection package, or implement manually)
      // or check isNotEmpty before accessing .first
      double initialBalance = 0.0;
      if (accData.isNotEmpty) {
        initialBalance =
            (accData.first['initial_balance'] as num?)?.toDouble() ?? 0.0;
      } else {
        // Handle case where account ID might be invalid (optional)
        print(
          "Warning: Account ID $accountId not found for balance calculation.",
        );
        // Consider throwing an error if an invalid ID is unexpected
        // throw Exception("Account not found: $accountId");
      }

      // Sum transaction amounts safely
      final List<Map<String, dynamic>> result = await db.rawQuery(
        'SELECT SUM(amount) as total FROM transactions WHERE account_id = ?',
        [accountId],
      );
      double sumAmount = (result.first['total'] as num?)?.toDouble() ?? 0.0;

      return initialBalance + sumAmount;
    } catch (e) {
      print("Error calculating balance for account $accountId: $e");
      rethrow; // Let the caller (Provider) handle it
    }
  }

  Future<double> getAccountBalanceAtDate(
    int accountId,
    DateTime endDate,
  ) async {
    Database db = await database;
    try {
      // 1. Get initial balance of the account
      final List<Map<String, dynamic>> accData = await db.query(
        'accounts',
        columns: ['initial_balance', 'created_at'], // Also fetch created_at
        where: 'id = ?',
        whereArgs: [accountId],
        limit: 1,
      );

      if (accData.isEmpty) {
        print(
          "Warning: Account ID $accountId not found for balance calculation at date.",
        );
        return 0.0; // Or throw Exception("Account not found: $accountId");
      }

      double initialBalance =
          (accData.first['initial_balance'] as num?)?.toDouble() ?? 0.0;
      DateTime accountCreatedAt = DateTime.parse(
        accData.first['created_at'] as String,
      );
      final DateTime normalizedEndDate = DateTime(
        endDate.year,
        endDate.month,
        endDate.day,
      );
      final DateTime normalizedCreatedAt = DateTime(
        accountCreatedAt.year,
        accountCreatedAt.month,
        accountCreatedAt.day,
      );

      if (normalizedEndDate.isBefore(normalizedCreatedAt)) {
        print(
          "Balance for Acc $accountId at $endDate: endDate is before creationDate ($accountCreatedAt). Balance is 0.",
        );
        return 0.00;
      }

      final String endDateString = endDate.toIso8601String();
      final String createdAtString = accountCreatedAt.toIso8601String();

      // Ensure we only sum transactions from the account creation date up to the specified endDate
      final List<Map<String, dynamic>> result = await db.rawQuery(
        '''
        SELECT SUM(amount) as total
        FROM transactions
        WHERE account_id = ?
          AND timestamp <= ?
          AND timestamp >= ?
        ''',
        [accountId, endDateString, createdAtString], // Order of args matters
      );

      double sumAmount = (result.first['total'] as num?)?.toDouble() ?? 0.0;

      print(
        "Balance for Acc $accountId at $endDateString: Initial=$initialBalance, SumTx=$sumAmount, Total=${initialBalance + sumAmount}",
      );
      return initialBalance + sumAmount;
    } catch (e) {
      print("Error calculating balance for account $accountId at $endDate: $e");
      rethrow;
    }
  }

  Future<Map<int, double>> getAllAccountBalances() async {
    Database db = await database;
    try {
      // This single query is much faster than calling getAccountBalance for each account.
      // LEFT JOIN ensures accounts with zero transactions are included.
      // IFNULL/COALESCE handles the SUM being NULL for accounts with zero transactions.
      final List<Map<String, dynamic>> results = await db.rawQuery('''
            SELECT
                a.id,
                a.initial_balance + IFNULL(SUM(t.amount), 0.0) as current_balance
            FROM accounts a
            LEFT JOIN transactions t ON a.id = t.account_id
            GROUP BY a.id
        ''');

      // Convert the List<Map> result into a Map<accountId, balance>
      final Map<int, double> balanceMap = {};
      for (var row in results) {
        // Ensure correct type casting
        int id = row['id'] as int;
        double balance = (row['current_balance'] as num?)?.toDouble() ?? 0.0;
        balanceMap[id] = balance;
      }
      return balanceMap;
    } catch (e) {
      print("Error fetching all account balances: $e");
      rethrow; // Let the caller (Provider) handle it
    }
  }

  Future<Map<int, double>> getAllAccountBalancesAtDate(DateTime endDate) async {
    Database db = await database;
    final Map<int, double> balanceMap = {};
    final String endDateString = endDate.toIso8601String();

    try {
      // 1. Get all accounts that were created ON OR BEFORE the endDate
      //    along with their initial balance and creation date.
      final List<Map<String, dynamic>> accountsData = await db.query(
        'accounts',
        columns: ['id', 'initial_balance', 'created_at'],
        where: 'created_at <= ?', // Only accounts that existed by endDate
        whereArgs: [
          endDateString,
        ], // Compare full datetime string for created_at
      );

      if (accountsData.isEmpty) {
        print("No accounts found created on or before $endDateString");
        return balanceMap; // Return empty map
      }

      // 2. For each such account, calculate its balance at endDate
      for (var accRow in accountsData) {
        int accountId = accRow['id'] as int;
        double initialBalance =
            (accRow['initial_balance'] as num?)?.toDouble() ?? 0.0;
        DateTime accountCreatedAt = DateTime.parse(
          accRow['created_at'] as String,
        );

        // --- Redundant Check (already filtered by query), but good for clarity or complex scenarios ---
        // Normalize dates for comparison (day-based)
        // final DateTime normalizedEndDate = DateTime(endDate.year, endDate.month, endDate.day);
        // final DateTime normalizedCreatedAt = DateTime(accountCreatedAt.year, accountCreatedAt.month, accountCreatedAt.day);
        //
        // if (normalizedEndDate.isBefore(normalizedCreatedAt)) {
        //   balanceMap[accountId] = 0.0; // Account didn't exist yet on this day
        //   print("Skipping balance for Acc $accountId at $endDate (before creation $accountCreatedAt), setting to 0");
        //   continue; // Skip to next account if using this explicit check
        // }
        // --- Since the main query `where: 'created_at <= ?'` already filters this,
        //     the above check might be redundant if `endDate` is always end-of-day.
        //     However, if `endDate` could be start-of-day, it's safer.
        //     For simplicity, let's rely on the initial query and proceed.

        final String startOfAccountLifeString =
            DateTime(
              accountCreatedAt.year,
              accountCreatedAt.month,
              accountCreatedAt.day,
            ).toIso8601String();

        final List<Map<String, dynamic>> transactionSumResult = await db
            .rawQuery(
              '''
          SELECT SUM(amount) as total
          FROM transactions
          WHERE account_id = ?
            AND timestamp <= ?
            AND timestamp >= ?
          ''',
              [accountId, endDateString, startOfAccountLifeString],
            );

        double sumAmount =
            (transactionSumResult.first['total'] as num?)?.toDouble() ?? 0.0;
        balanceMap[accountId] = initialBalance + sumAmount;
        print(
          "AllBalancesAtDate - Acc $accountId: Initial=$initialBalance, SumTx=$sumAmount, Balance=${balanceMap[accountId]}",
        );
      }
      return balanceMap;
    } catch (e) {
      print("Error fetching all account balances at date $endDate: $e");
      rethrow;
    }
  }

  // --- Add more complex queries: net change, income/expense totals etc. ---

  // =====================================================================
  // CRUD Operations for Recurring Transactions
  // =====================================================================

  Future<int> insertRecurringTransaction(RecurringTransaction recurring) async {
    Database db = await database;
    try {
      return await db.insert(
        'recurring_transactions',
        recurring.toMap()..remove('id'), // Use toMap, remove ID
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (e) {
      print("Error inserting recurring transaction: $e");
      print("Recurring data: ${recurring.toMap()}");
      rethrow;
    }
  }

  Future<List<RecurringTransaction>> getAllRecurringTransactions() async {
    Database db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'recurring_transactions',
      orderBy: 'next_due_date ASC',
    );
    return List.generate(
      maps.length,
      (i) => RecurringTransaction.fromMap(maps[i]),
    );
  }

  // Get recurring transactions due on or before a certain date
  Future<List<RecurringTransaction>> getDueRecurringTransactions(
    DateTime upToDate,
  ) async {
    Database db = await database;
    // Compare dates as strings 'YYYY-MM-DD'
    String dateString = upToDate.toIso8601String().substring(0, 10);
    final List<Map<String, dynamic>> maps = await db.query(
      'recurring_transactions',
      where: 'next_due_date <= ?',
      whereArgs: [dateString],
      orderBy: 'next_due_date ASC',
    );
    return List.generate(
      maps.length,
      (i) => RecurringTransaction.fromMap(maps[i]),
    );
  }

  Future<int> updateRecurringTransaction(RecurringTransaction recurring) async {
    Database db = await database;
    return await db.update(
      'recurring_transactions',
      recurring.toMap(),
      where: 'id = ?',
      whereArgs: [recurring.id],
    );
  }

  Future<int> deleteRecurringTransaction(int id) async {
    Database db = await database;
    return await db.delete(
      'recurring_transactions',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // --- Optional: Close the database ---
  Future<void> close() async {
    final db = await database;
    await db.close();
    _database = null; // Ensure re-initialization next time
    print("Database closed.");
  }
}
