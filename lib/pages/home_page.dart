import 'package:finance_tracker/data/account_provider.dart';
import 'package:finance_tracker/data/accounts_class.dart';
import 'package:finance_tracker/data/enums.dart';
import 'package:finance_tracker/data/transactions_class.dart';
import 'package:finance_tracker/data/transactions_provider.dart';
import 'package:finance_tracker/utilities/app_drawer.dart';
import 'package:finance_tracker/utilities/transactions_form.dart';
import 'package:finance_tracker/utilities/transactions_tile.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

typedef DateRange = ({DateTime start, DateTime end});

class _HomePageState extends State<HomePage> {
  void _showTransactionsForm([Transactions? transactionsToEdit]) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return TransactionsForm(existingTransaction: transactionsToEdit);
      },
    ).then((result) {
      if (result == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              transactionsToEdit == null
                  ? 'Transaction Created!'
                  : 'Transaction Updated!',
            ),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    });
  }

  Future<void> _onDelete(Transactions transactionToDelete) async {
    final currentContext = context;
    final transactionsProvider = Provider.of<TransactionsProvider>(
      currentContext,
      listen: false,
    );
    transactionsProvider.deleteTransaction(transactionToDelete.id!);
  }

  static const int _allAccountsId = 0;
  int? _selectedAccountId = _allAccountsId;
  TimePeriod _selectedTimePeriod = TimePeriod.day;
  bool _isLoadingAccounts = false;
  List<Account> _accountsForDropdown = [];
  DateTime _currentReferenceDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchAccountsForDropdown();
      _fetchTransactions();
    });
  }

  DateRange _getStartEndDate() {
    DateTime refDate = _currentReferenceDate;
    DateTime startDate;
    DateTime endDate;
    switch (_selectedTimePeriod) {
      case TimePeriod.day:
        startDate = DateTime(refDate.year, refDate.month, refDate.day);
        endDate = DateTime(
          refDate.year,
          refDate.month,
          refDate.day,
          23,
          59,
          59,
          999,
        );
        break;
      case TimePeriod.week:
        int currentWeekday = refDate.weekday;
        startDate = DateTime(
          refDate.year,
          refDate.month,
          refDate.day,
        ).subtract(Duration(days: currentWeekday - 1));
        endDate = startDate.add(
          Duration(
            days: 6,
            hours: 23,
            minutes: 59,
            seconds: 59,
            milliseconds: 999,
          ),
        );
        break;
      case TimePeriod.month:
        startDate = DateTime(refDate.year, refDate.month, 1);
        endDate = DateTime(refDate.year, refDate.month + 1, 0, 23, 59, 59, 999);
        break;
      case TimePeriod.year:
        startDate = DateTime(refDate.year, 1, 1);
        endDate = DateTime(refDate.year, 12, 31, 23, 59, 59, 999);
        break;
    }
    return (start: startDate, end: endDate);
  }

  Future<void> _fetchAccountsForDropdown() async {
    if (!mounted) return;
    setState(() {
      _isLoadingAccounts = true;
    });
    try {
      final accountProvider = Provider.of<AccountProvider>(
        context,
        listen: false,
      );
      if (accountProvider.accounts.isEmpty) {
        await accountProvider.fetchAccounts();
      }
      _accountsForDropdown = [
        Account(
          id: _allAccountsId,
          name: 'All',
          initialBalance: 0,
          createdAt: DateTime.now(),
        ),
        ...accountProvider.accounts,
      ];
      if (_selectedAccountId == _allAccountsId &&
          _accountsForDropdown.length > 1 &&
          _accountsForDropdown.first.id != _allAccountsId) {
      } else if (_accountsForDropdown.isNotEmpty &&
          _selectedAccountId == null) {
        _selectedAccountId = _accountsForDropdown.first.id;
      }
    } catch (e) {
      print("Error fetching accounts for dropdown: $e");
      // Handle error appropriately
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingAccounts = false;
        });
      }
    }
  }

  Future<void> _fetchTransactions() async {
    if (!mounted) return;
    final transactionsProvider = Provider.of<TransactionsProvider>(
      context,
      listen: false,
    );

    List<int>? accountIdsToFetch;
    if (_selectedAccountId != null && _selectedAccountId != _allAccountsId) {
      accountIdsToFetch = [_selectedAccountId!];
    }

    final dateRange = _getStartEndDate();
    final DateTime startDate = dateRange.start;
    final DateTime endDate = dateRange.end;

    print(
      "Fetching transactions for Account ID(s): $accountIdsToFetch, Period: $_selectedTimePeriod, Start: $startDate, End: $endDate",
    );
    await transactionsProvider.fetchTransactions(
      accountIds: accountIdsToFetch,
      startDate: startDate,
      endDate: endDate,
      periodForChart: _selectedTimePeriod,
    );
  }

  void _goNextPeriod() {
    setState(() {
      switch (_selectedTimePeriod) {
        case TimePeriod.day:
          _currentReferenceDate = _currentReferenceDate.add(
            const Duration(days: 1),
          );
          break;
        case TimePeriod.week:
          _currentReferenceDate = _currentReferenceDate.add(
            const Duration(days: 7),
          );
          break;
        case TimePeriod.month:
          _currentReferenceDate = DateTime(
            _currentReferenceDate.year,
            _currentReferenceDate.month + 1,
            1,
          );
          break;
        case TimePeriod.year:
          _currentReferenceDate = DateTime(
            _currentReferenceDate.year + 1,
            _currentReferenceDate.month,
            1,
          );
          break;
      }
    });
    _fetchTransactions();
  }

  void _goCurrentDate() {
    setState(() {
      _currentReferenceDate = DateTime.now();
    });
    _fetchTransactions();
  }

  void _goPreviousPeriod() {
    setState(() {
      switch (_selectedTimePeriod) {
        case TimePeriod.day:
          _currentReferenceDate = _currentReferenceDate.subtract(
            const Duration(days: 1),
          );
          break;
        case TimePeriod.week:
          _currentReferenceDate = _currentReferenceDate.subtract(
            const Duration(days: 7),
          );
          break;
        case TimePeriod.month:
          _currentReferenceDate = DateTime(
            _currentReferenceDate.year,
            _currentReferenceDate.month - 1,
            1,
          );
          break;
        case TimePeriod.year:
          _currentReferenceDate = DateTime(
            _currentReferenceDate.year - 1,
            _currentReferenceDate.month,
            1,
          );
          break;
      }
    });
    _fetchTransactions();
  }

  String _getDateRangeString() {
    final dateRange = _getStartEndDate();
    final DateTime periodStartDate = dateRange.start;
    final DateTime periodEndDate = dateRange.end;

    switch (_selectedTimePeriod) {
      case TimePeriod.day:
        // periodStartDate is already the specific day
        return DateFormat('EEE, MMM d, yyyy').format(periodStartDate);
      case TimePeriod.week:
        // periodStartDate is the Monday, periodEndDate is the Sunday
        if (periodStartDate.month == periodEndDate.month) {
          return '${DateFormat('MMM d').format(periodStartDate)} - ${DateFormat('d, yyyy').format(periodEndDate)}';
        } else if (periodStartDate.year == periodEndDate.year) {
          return '${DateFormat('MMM d').format(periodStartDate)} - ${DateFormat('MMM d, yyyy').format(periodEndDate)}';
        }
        return '${DateFormat('MMM d, yyyy').format(periodStartDate)} - ${DateFormat('MMM d, yyyy').format(periodEndDate)}';
      case TimePeriod.month:
        // periodStartDate is the 1st of the month
        return DateFormat('MMMM yyyy').format(periodStartDate);
      case TimePeriod.year:
        // periodStartDate is Jan 1st of the year
        return DateFormat('yyyy').format(periodStartDate);
    }
  }

  @override
  Widget build(BuildContext context) {
    final transactionsProvider = Provider.of<TransactionsProvider>(context);
    final accountProvider = context.watch<AccountProvider>();
    final List<ChartDataPoint> chartPoints = transactionsProvider.chartData;
    final double maxYValueForChart = transactionsProvider.maxChartYValue;
    final DateTime _now = DateTime.now();
    String currentDateRangeDisplay = _getDateRangeString();

    print(chartPoints);
    print(maxYValueForChart);

    return Scaffold(
      appBar: AppBar(title: const Text('Homepage')),
      drawer: const AppDrawer(), // Use the reusable drawer widget here!
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                SizedBox(
                  width: 100,
                  child:
                      _isLoadingAccounts
                          ? const SizedBox(
                            height: 48,
                            child: Center(
                              child: SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              ),
                            ),
                          ) // Small loading indicator
                          : DropdownButtonFormField<int>(
                            isExpanded:
                                true, // Makes dropdown take full width of its Expanded parent
                            value: _selectedAccountId,
                            decoration: InputDecoration(
                              labelText: 'Account',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12.0,
                                vertical: 8.0,
                              ), // Adjust padding
                            ),
                            // Use _accountsForDropdown from state
                            items:
                                _accountsForDropdown.map((Account account) {
                                  return DropdownMenuItem<int>(
                                    value: account.id,
                                    child: Text(
                                      account.name,
                                      overflow:
                                          TextOverflow
                                              .ellipsis, // Prevent long names from overflowing
                                    ),
                                  );
                                }).toList(),
                            onChanged: (int? newValue) {
                              if (newValue != null) {
                                setState(() {
                                  _selectedAccountId = newValue;
                                });
                                _fetchTransactions(); // Re-fetch transactions when account changes
                              }
                            },
                            // No validator needed if "All Accounts" is always a valid selection
                          ),
                ),

                const Spacer(),

                // Adjust flex to balance with dropdown
                SizedBox(
                  width: 175,
                  child: SegmentedButton<TimePeriod>(
                    segments: const <ButtonSegment<TimePeriod>>[
                      ButtonSegment<TimePeriod>(
                        value: TimePeriod.day,
                        label: Text('D'),
                      ),
                      ButtonSegment<TimePeriod>(
                        value: TimePeriod.week,
                        label: Text('W'),
                      ),
                      ButtonSegment<TimePeriod>(
                        value: TimePeriod.month,
                        label: Text('M'),
                      ),
                      ButtonSegment<TimePeriod>(
                        value: TimePeriod.year,
                        label: Text('Y'),
                      ),
                    ],
                    selected: <TimePeriod>{
                      _selectedTimePeriod,
                    }, // The selected value
                    onSelectionChanged: (Set<TimePeriod> newSelection) {
                      if (newSelection.isNotEmpty) {
                        // Ensure a selection is made
                        setState(() {
                          _selectedTimePeriod = newSelection.first;
                        });
                        _fetchTransactions(); // Re-fetch transactions when period changes
                      }
                    },
                    multiSelectionEnabled: false,
                    showSelectedIcon: false,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 15),

          Row(
            children: [
              Expanded(
                flex: 1,
                child: Align(
                  alignment: Alignment.centerRight,
                  child: IconButton(
                    icon: const Icon(Icons.chevron_left),
                    onPressed: _goPreviousPeriod, // Call navigation method
                    tooltip: 'Previous Period',
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: Align(
                  alignment: Alignment.centerRight,
                  child: SizedBox(width: 24),
                ),
              ),
              Expanded(
                flex: 3,
                child: Text(
                  currentDateRangeDisplay, // Display the formatted date range
                  textAlign: TextAlign.center,
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                ),
              ),
              Expanded(
                flex: 2,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child:
                      DateTime(
                                _currentReferenceDate.year,
                                _currentReferenceDate.month,
                                _currentReferenceDate.day,
                              ) !=
                              DateTime(_now.year, _now.month, _now.day)
                          ? IconButton(
                            onPressed: _goCurrentDate,
                            icon: const Icon(Icons.date_range),
                          )
                          : SizedBox(width: 24),
                ),
              ),
              Expanded(
                flex: 1,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: IconButton(
                    icon: const Icon(Icons.chevron_right),
                    onPressed: _goNextPeriod, // Call navigation method
                    tooltip: 'Next Period',
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 30),

          homepagebarchart(
            maxYValueForChart: maxYValueForChart,
            chartPoints: chartPoints,
          ),

          const Divider(height: 30),

          Expanded(
            // Use Expanded to make the list take remaining space
            child:
                transactionsProvider.transactions.isEmpty
                    ? const Center(
                      child: Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Text(
                          'No transactions found for the selected account and period.',
                          textAlign: TextAlign.center,
                        ),
                      ),
                    )
                    : ListView.builder(
                      itemCount: transactionsProvider.transactions.length,
                      itemBuilder: (ctx, index) {
                        final transaction =
                            transactionsProvider.transactions[index];

                        final Account associatedAccount = accountProvider
                            .accounts
                            .firstWhere(
                              (acc) => acc.id == transaction.accountId,
                            );

                        // --- Return your TransactionsTile widget ---
                        return TransactionsTile(
                          key: ValueKey(
                            transaction.id,
                          ), // Good for list performance
                          transactionData: transaction,
                          onEdit: () {
                            // Call the existing method to show the form for editing
                            _showTransactionsForm(transaction);
                          },
                          onDelete: (Transactions transactionToDelete) {
                            // Call the method to handle deletion
                            _onDelete(transactionToDelete);
                          },
                          accountName: associatedAccount.name,
                        );
                        // --- ---
                      },
                    ),
          ),
          // --- End Display Transactions ---
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _showTransactionsForm();
        },
        tooltip: 'Add Transaction',
        child: const Icon(Icons.add),
      ),
    );
    ;
  }
}

class homepagebarchart extends StatelessWidget {
  const homepagebarchart({
    super.key,
    required this.maxYValueForChart,
    required this.chartPoints,
  });

  final double maxYValueForChart;
  final List<ChartDataPoint> chartPoints;

  @override
  Widget build(BuildContext context) {
    double chartwidth = chartPoints.length * 50;
    final screenwidth = MediaQuery.of(context).size.width;
    if (chartwidth < screenwidth) {
      chartwidth = screenwidth;
    }
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Container(
        height: 200,
        width: chartwidth,
        child: BarChart(
          BarChartData(
            maxY: maxYValueForChart,
            minY: 0,
            groupsSpace: 50,
            gridData: FlGridData(show: false),
            barGroups:
                chartPoints.asMap().entries.map((entry) {
                  int index = entry.key;
                  ChartDataPoint dataPoint = entry.value;

                  return BarChartGroupData(
                    x: index,
                    barRods: [
                      BarChartRodData(
                        toY: dataPoint.income,
                        color: Colors.green,
                      ),
                      BarChartRodData(
                        toY: dataPoint.expense,
                        color: Colors.red,
                      ),
                    ],
                  );
                }).toList(),
            titlesData: FlTitlesData(
              show: true,
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 50,
                  getTitlesWidget: (double value, TitleMeta meta) {
                    final int pointIndex = value.toInt();
                    ChartDataPoint? currentPoint;
                    currentPoint = chartPoints[pointIndex];

                    if (currentPoint == null) {
                      return SideTitleWidget(meta: meta, child: const Text(''));
                    }
                    String periodLabel = currentPoint.label;
                    double netChangeValue = currentPoint.netChange;
                    String netChangeString = '';
                    Color netChangeColor = Colors.grey;

                    if (netChangeValue != 0) {
                      netChangeColor =
                          netChangeValue >= 0 ? Colors.green : Colors.red;
                      String netChangeSign = netChangeValue >= 0 ? '+' : '-';
                      netChangeString =
                          '$netChangeSign\$${netChangeValue.abs().toStringAsFixed(0)}';
                    }

                    return SideTitleWidget(
                      meta: meta,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(periodLabel),
                          Text(
                            netChangeString,
                            style: TextStyle(color: netChangeColor),
                          ),
                        ],
                      ),
                    );
                    // String text = '';
                    // if (value.toInt() >= 0 &&
                    //     value.toInt() < chartPoints.length) {
                    //   text = chartPoints[value.toInt()].label;
                    // }
                    // return SideTitleWidget(
                    //   meta: meta,
                    //   child: Text(text, style: const TextStyle(fontSize: 10)),
                    // );
                  },
                ),
              ),
              leftTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              topTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              rightTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
            ),
            barTouchData: BarTouchData(
              enabled: true,
              touchTooltipData: BarTouchTooltipData(
                getTooltipColor: (group) => Colors.transparent,
                tooltipPadding: EdgeInsets.zero,
                tooltipMargin: 0,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
