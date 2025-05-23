import 'package:finance_tracker/data/enums.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:finance_tracker/data/transactions_class.dart';
import 'package:finance_tracker/services/database_service.dart';
import 'package:collection/collection.dart';

class ChartDataPoint {
  final double x;
  final double income;
  final double expense;
  final String label;
  final double netChange;

  ChartDataPoint({
    required this.x,
    required this.income,
    required this.expense,
    required this.label,
    required this.netChange,
  });
}

class TransactionsProvider with ChangeNotifier {
  final DatabaseService _dbService = DatabaseService();

  //State Variables
  List<int>? _currentAccountIds;
  DateTime? _currentStartDate;
  DateTime? _currentEndDate;
  int? _currentLimit;
  TimePeriod? _currentPeriodForChart;
  double _totalIncomeForPeriod = 0.0;
  double _totalExpenseForPeriod = 0.0;
  double _netChangeForPeriod = 0.0;
  double _maxChartYValue = 100.0;
  List<ChartDataPoint> _chartData = [];
  List<Transactions> _transactions = [];

  //Getters
  double get maxChartYValue => _maxChartYValue;
  List<ChartDataPoint> get chartData => _chartData;
  List<Transactions> get transactions => _transactions;
  double get totalIncomeForPeriod => _totalIncomeForPeriod;
  double get totalExpenseForPeriod => _totalExpenseForPeriod;
  double get netChangeForPeriod => _netChangeForPeriod;

  int _getWeekOfMonth(DateTime date) {
    final localDate = date.toLocal();
    final firstDayOfMonth = DateTime(localDate.year, localDate.month, 1);
    final dayOfMonth = localDate.day;
    return ((dayOfMonth - 1) / 7).floor() + 1;
  }

  Future<void> fetchTransactions({
    List<int>? accountIds,
    DateTime? startDate,
    DateTime? endDate,
    int? limit,
    TimePeriod? periodForChart,
  }) async {
    _currentAccountIds = accountIds;
    _currentStartDate = startDate;
    _currentEndDate = endDate;
    _currentLimit = limit;
    _currentPeriodForChart = periodForChart;

    try {
      _transactions = await _dbService.getTransactions(
        accountIds: accountIds,
        startDate: startDate,
        endDate: endDate,
        limit: limit,
      );
      print("BUG ${startDate}, ${endDate}, ${periodForChart}");
      if (startDate != null && endDate != null && periodForChart != null) {
        _prepareChartData(_transactions, periodForChart, startDate, endDate);
      } else {
        _chartData = [];
        _maxChartYValue = 100.0;
      }
      _calculatePeriodSummaries();
    } catch (e) {
      print("Error fetching transactions: $e");
      _transactions = [];
    } finally {
      notifyListeners();
    }
  }

  void _prepareChartData(
    List<Transactions> transactions,
    TimePeriod period,
    DateTime VstartDate,
    DateTime VendDate,
  ) {
    List<ChartDataPoint> newChartData = [];
    double currentMaxY = 0.0;
    print(
      "_prepareChartData: Received ${transactions.length} transactions. Period: $period, Start: $VstartDate, End: $VendDate",
    );

    if (transactions.isEmpty) {
      _chartData = [];
      _maxChartYValue = 100.0;
      notifyListeners();
      print(
        "_prepareChartData: Transactions list is empty. Chart data cleared.",
      );
      return;
    }

    Map<dynamic, List<Transactions>> groupedTransactions;

    switch (period) {
      case TimePeriod.day:
        double dailyIncome = 0;
        double dailyExpense = 0;
        for (var tx in transactions) {
          if (tx.amount > 0) dailyIncome += tx.amount;
          if (tx.amount < 0) dailyExpense += tx.amount.abs();
        }
        double dailyNetChange = dailyIncome - dailyExpense;
        newChartData.add(
          ChartDataPoint(
            x: 0,
            income: dailyIncome,
            expense: dailyExpense,
            label: 'Today',
            netChange: dailyNetChange,
          ),
        );

        currentMaxY = dailyIncome > dailyExpense ? dailyIncome : dailyExpense;
        break;

      case TimePeriod.week:
        groupedTransactions = groupBy(
          transactions,
          (Transactions tx) => tx.timestamp.toLocal().weekday,
        );
        List<String> weekdays = [
          "Mon",
          "Tue",
          "Wed",
          "Thu",
          "Fri",
          "Sat",
          "Sun",
        ];
        for (int i = 1; i <= 7; i++) {
          double income = 0;
          double expense = 0;
          if (groupedTransactions.containsKey(i)) {
            for (var tx in groupedTransactions[i]!) {
              if (tx.amount > 0) income += tx.amount;
              if (tx.amount < 0) expense += tx.amount.abs();
            }
          }
          double weeklyNetChange = income - expense;
          newChartData.add(
            ChartDataPoint(
              x: i.toDouble() - 1,
              income: income,
              expense: expense,
              label: weekdays[i - 1],
              netChange: weeklyNetChange,
            ),
          );
          if (income > currentMaxY) currentMaxY = income;
          if (expense > currentMaxY) currentMaxY = expense;
        }

        break;

      case TimePeriod.month:
        groupedTransactions = groupBy(
          transactions,
          (Transactions tx) => _getWeekOfMonth(tx.timestamp),
        );
        final lastDayOfMonth = DateTime(
          VstartDate.year,
          VstartDate.month + 1,
          0,
        );
        final maxWeekNumber = _getWeekOfMonth(lastDayOfMonth);

        for (int weekNum = 1; weekNum <= maxWeekNumber; weekNum++) {
          double income = 0;
          double expense = 0;
          if (groupedTransactions.containsKey(weekNum)) {
            for (var tx in groupedTransactions[weekNum]!) {
              if (tx.amount > 0) income += tx.amount;
              if (tx.amount < 0) expense += tx.amount.abs();
            }
          }
          int startDayOfWeekInMonth = ((weekNum - 1) * 7) + 1;
          int endDayOfWeekInMonth = startDayOfWeekInMonth + 6;
          if (endDayOfWeekInMonth > lastDayOfMonth.day) {
            endDayOfWeekInMonth = lastDayOfMonth.day;
          }
          double monthlyNetChange = income - expense;
          newChartData.add(
            ChartDataPoint(
              x: weekNum.toDouble() - 1,
              income: income,
              expense: expense,
              label: '$startDayOfWeekInMonth - $endDayOfWeekInMonth',
              netChange: monthlyNetChange,
            ),
          );
          if (income > currentMaxY) currentMaxY = income;
          if (expense > currentMaxY) currentMaxY = expense;
        }
        break;

      case TimePeriod.year:
        groupedTransactions = groupBy(
          transactions,
          (Transactions tx) => tx.timestamp.toLocal().month,
        );
        List<String> months = [
          "Jan",
          "Feb",
          "Mar",
          "Apr",
          "May",
          "Jun",
          "Jul",
          "Aug",
          "Sep",
          "Oct",
          "Nov",
          "Dec",
        ];
        for (int i = 1; i <= 12; i++) {
          double income = 0;
          double expense = 0;
          if (groupedTransactions.containsKey(i)) {
            for (var tx in groupedTransactions[i]!) {
              if (tx.amount > 0) income += tx.amount;
              if (tx.amount < 0) expense += tx.amount.abs();
            }
          }
          double yearlyNetChange = income - expense;
          newChartData.add(
            ChartDataPoint(
              x: i.toDouble() - 1,
              income: income,
              expense: expense,
              label: months[i - 1],
              netChange: yearlyNetChange,
            ),
          );
          if (income > currentMaxY) currentMaxY = income;
          if (expense > currentMaxY) currentMaxY = expense;
        }
        break;
    }
    _chartData = newChartData;
    _maxChartYValue = currentMaxY;
  }

  void _calculatePeriodSummaries() {
    double income = 0.0;
    double expense = 0.0;

    for (final transaction in _transactions) {
      if (transaction.amount > 0) {
        income += transaction.amount;
      } else if (transaction.amount < 0) {
        expense += transaction.amount.abs();
      }
    }

    _totalIncomeForPeriod = income;
    _totalExpenseForPeriod = expense;
    _netChangeForPeriod = income - expense;
  }

  Future<bool> addTransaction(Transactions transaction) async {
    try {
      int id = await _dbService.insertTransaction(transaction);
      final newTransaction = transaction.copyWith(id: id);

      _transactions.insert(0, newTransaction);
      await fetchTransactions(
        accountIds: _currentAccountIds,
        startDate: _currentStartDate,
        endDate: _currentEndDate,
        limit: _currentLimit,
        periodForChart: _currentPeriodForChart,
      );

      notifyListeners();

      return true;
    } catch (e) {
      print("Error adding transaction: $e");
      return false;
    }
  }

  Future<bool> updateTransaction(Transactions transaction) async {
    try {
      await _dbService.updateTransaction(transaction);

      final index = _transactions.indexWhere((t) => t.id == transaction.id);
      if (index != -1) {
        _transactions[index] = transaction;
        _transactions.sort(
          (a, b) => b.timestamp.compareTo(a.timestamp),
        ); // Descending
        await fetchTransactions(
          accountIds: _currentAccountIds,
          startDate: _currentStartDate,
          endDate: _currentEndDate,
          limit: _currentLimit,
          periodForChart: _currentPeriodForChart,
        );
        notifyListeners();
      }
      return true;
    } catch (e) {
      print("Error updating transaction: $e");
      return false;
    }
  }

  // Delete a transaction
  Future<bool> deleteTransaction(int id) async {
    try {
      await _dbService.deleteTransaction(id);
      _transactions.removeWhere((t) => t.id == id);
      await fetchTransactions(
        accountIds: _currentAccountIds,
        startDate: _currentStartDate,
        endDate: _currentEndDate,
        limit: _currentLimit,
        periodForChart: _currentPeriodForChart,
      );

      notifyListeners();
      return true;
    } catch (e) {
      print("Error deleting transaction: $e");
      return false;
    }
  }
}
