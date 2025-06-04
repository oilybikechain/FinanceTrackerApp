import 'package:collection/collection.dart';
import 'package:finance_tracker/data/category_class.dart';
import 'package:finance_tracker/data/listitem_class.dart';
import 'package:finance_tracker/services/account_provider.dart';
import 'package:finance_tracker/data/accounts_class.dart';
import 'package:finance_tracker/data/enums.dart';
import 'package:finance_tracker/data/transactions_class.dart';
import 'package:finance_tracker/services/category_provider.dart';
import 'package:finance_tracker/services/recurring_transactions_provider.dart';
import 'package:finance_tracker/services/settings_service.dart';
import 'package:finance_tracker/services/transactions_provider.dart';
import 'package:finance_tracker/utilities/app_drawer.dart';
import 'package:finance_tracker/utilities/home_bar_chart.dart';
import 'package:finance_tracker/utilities/home_pie_chart.dart';
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
        _fetchPeriodEndBalance();
      }
    });
  }

  Future<void> _onDelete(Transactions transactionToDelete) async {
    final dateRange = _getStartEndDate();
    final DateTime endDate = dateRange.end;
    final currentContext = context;
    final transactionsProvider = Provider.of<TransactionsProvider>(
      currentContext,
      listen: false,
    );
    transactionsProvider.deleteTransaction(transactionToDelete.id!);
    final accountProvider = Provider.of<AccountProvider>(
      currentContext,
      listen: false,
    );

    //LAST UPDATED PROGRESS
    accountProvider.fetchAccountBalanceAtDate(_selectedAccountId!, endDate);
  }

  static const int _allAccountsId = 0;
  int? _selectedAccountId = _allAccountsId;
  TimePeriod _selectedTimePeriod = TimePeriod.day;
  List<Account> _accountsForDropdown = [];
  DateTime _currentReferenceDate = DateTime.now();
  bool _isPageLoading = false;
  bool _showCharts = false;
  bool _toggleToPieChart = false;
  final SettingsService _settingsService = SettingsService();
  bool _isInit = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadPreferences();
      _fetchHomePageData();
      _fetchPeriodEndBalance();
    });
  }

  // @override
  // void didChangeDependencies() {
  //   super.didChangeDependencies();
  //   if (_isInit) {
  //     _loadPreferences();
  //     _fetchHomePageData();
  //     _fetchPeriodEndBalance();
  //   }
  //   _isInit = false;
  // }

  Future<void> _loadPreferences() async {
    if (!mounted) return;
    _showCharts = await _settingsService.getShowChartsPreference();
    _toggleToPieChart = await _settingsService.getChartTypePreference();
    print(
      "Loaded preferences: showCharts=$_showCharts, chartType=$_toggleToPieChart",
    );
  }

  void _toggleChartVisibility() async {
    setState(() {
      _showCharts = !_showCharts;
    });
    await _settingsService.setShowChartsPreference(_showCharts);
    // No need to re-fetch data, just hiding/showing
  }

  void _togglePieChart() async {
    setState(() {
      _toggleToPieChart = !_toggleToPieChart;
    });
    await _settingsService.setChartTypePreference(_toggleToPieChart);
    // No need to re-fetch data, just hiding/showing
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

  Future<void> _fetchHomePageData() async {
    if (!mounted) return;

    setState(() {
      _isPageLoading = true;
    });

    final accountProvider = Provider.of<AccountProvider>(
      context,
      listen: false,
    );
    final transactionsProvider = Provider.of<TransactionsProvider>(
      context,
      listen: false,
    );
    final categoryProvider = Provider.of<CategoryProvider>(
      context,
      listen: false,
    );
    final recurringTransactionsProvider =
        Provider.of<RecurringTransactionsProvider>(context, listen: false);

    try {
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
      if (_accountsForDropdown.isNotEmpty &&
          (_selectedAccountId == null ||
              !_accountsForDropdown.any(
                (acc) => acc.id == _selectedAccountId,
              ))) {
        _selectedAccountId = _accountsForDropdown.first.id;
        print(
          "HomePage: Defaulted selected account to ID: $_selectedAccountId",
        );
      }

      if (categoryProvider.categories.isEmpty && !categoryProvider.isLoading) {
        print("HomePage: Categories are empty, fetching them now...");
        await categoryProvider.fetchCategories(); // <<< AWAIT THIS
        print(
          "HomePage: Categories fetched. Count: ${categoryProvider.categories.length}",
        );
      } else {
        print(
          "HomePage: Categories already loaded or loading. Count: ${categoryProvider.categories.length}",
        );
      }

      await recurringTransactionsProvider.processDueRecurringTransactions(
        DateTime.now(),
      );
      await recurringTransactionsProvider.processDueInterestTransactions(
        DateTime.now(),
      );

      final dateRange = _getStartEndDate();

      List<int>? accountIdsToFetch;

      if (_selectedAccountId != null && _selectedAccountId != _allAccountsId) {
        accountIdsToFetch = [_selectedAccountId!];
      }

      print(
        "HomePage: Fetching transactions with current filters. Categories available: ${categoryProvider.categories.isNotEmpty}",
      );
      await transactionsProvider.fetchTransactions(
        accountIds: accountIdsToFetch,
        startDate: dateRange.start,
        endDate: dateRange.end,
        periodForChart: _selectedTimePeriod,
        allCategories: categoryProvider.categories,
      );
    } catch (e) {
      print("Error during initial page data load: $e");
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading page data: $e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isPageLoading = false; // Stop loading
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
    final categoryProvider = Provider.of<CategoryProvider>(
      context,
      listen: false,
    );

    if (categoryProvider.categories.isEmpty && !categoryProvider.isLoading) {
      await categoryProvider.fetchCategories();
    }

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
      allCategories: categoryProvider.categories,
    );
  }

  Future<void> _fetchPeriodEndBalance() async {
    if (!mounted) return;
    List<int>? accountIdsToFetch;
    if (_selectedAccountId != null && _selectedAccountId != _allAccountsId) {
      accountIdsToFetch = [_selectedAccountId!];
    }

    final dateRange = _getStartEndDate();
    final DateTime endDate = dateRange.end;

    final accountProvider = Provider.of<AccountProvider>(
      context,
      listen: false,
    );
    await accountProvider.fetchAccountBalanceAtDate(
      _selectedAccountId!,
      endDate,
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
    _fetchPeriodEndBalance();
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
    _fetchPeriodEndBalance();
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

  List<ListItem> _buildTransactionsDisplay(
    List<Transactions> transactionsToDisplay,
    List<Account> allAccounts,
    List<Category> allCategories,
  ) {
    List<ListItem> displayItems = [];
    if (transactionsToDisplay.isNotEmpty) {
      DateTime? lastDate;
      for (var transaction in transactionsToDisplay) {
        // Assuming transactions are sorted newest first
        final transactionDate = DateTime(
          // Normalize to just date part for comparison
          transaction.timestamp.toLocal().year,
          transaction.timestamp.toLocal().month,
          transaction.timestamp.toLocal().day,
        );

        if (lastDate == null || lastDate != transactionDate) {
          displayItems.add(
            DateSeparatorItem(transactionDate),
          ); // Add date header
          lastDate = transactionDate;
        }

        final associatedAccount = allAccounts.firstWhereOrNull(
          (acc) => acc.id == transaction.accountId,
        );
        final associatedCategory =
            allCategories.firstWhereOrNull(
              (cat) => cat.id == transaction.categoryId,
            ) ??
            allCategories.firstWhere((cat) => cat.id == 1);

        displayItems.add(
          TransactionItem(
            transaction,
            associatedAccount?.name ?? 'Unknown Account',
            associatedCategory,
          ),
        );
      }
    }
    return displayItems;
  }

  @override
  Widget build(BuildContext context) {
    final transactionsProvider = context.watch<TransactionsProvider>();
    final accountProvider = context.watch<AccountProvider>();
    final List<ChartDataPoint> chartPoints = transactionsProvider.chartData;
    final double maxYValueForChart = transactionsProvider.maxChartYValue;
    final DateTime _now = DateTime.now();
    String currentDateRangeDisplay = _getDateRangeString();
    final double? selectedAccountPeriodEndBalance =
        accountProvider.periodEndBalance;
    final bool isLoadingPeriodEndBalance =
        accountProvider.isPeriodEndBalanceLoading;
    final bool isAccountCreated = accountProvider.isAccountCreatedByPeriodEnd;
    final double totalIncome = transactionsProvider.totalIncomeForPeriod;
    final double totalExpense = transactionsProvider.totalExpenseForPeriod;
    final double netChange = transactionsProvider.netChangeForPeriod;
    final categoryProvider = context.watch<CategoryProvider>();
    final List<Category> categoryData = categoryProvider.categories;
    final List<Account> accountData = accountProvider.accounts;
    final pieChartIncomeData = transactionsProvider.incomePieData;
    final pieChartExpenseData = transactionsProvider.expensePieData;
    final List<ListItem> displayItems = _buildTransactionsDisplay(
      transactionsProvider.transactions,
      accountData,
      categoryData,
    );

    print(chartPoints);
    print(maxYValueForChart);
    print(selectedAccountPeriodEndBalance);

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
                  child: DropdownButtonFormField<int>(
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
                        _fetchTransactions();
                        _fetchPeriodEndBalance();
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
                        _fetchPeriodEndBalance();
                      }
                    },
                    multiSelectionEnabled: false,
                    showSelectedIcon: false,
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(
              vertical: 8.0,
              horizontal: 12.0,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Expanded(
                  child:
                      !isAccountCreated
                          ? Column(
                            children: [
                              Text(
                                'Account not',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              Text(
                                'created yet',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                            ],
                          )
                          : Column(
                            children: [
                              Text(
                                'Balance:',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              Text(
                                selectedAccountPeriodEndBalance != null
                                    ? selectedAccountPeriodEndBalance < 0
                                        ? '-\$${selectedAccountPeriodEndBalance.abs().toStringAsFixed(2)}'
                                        : '\$${selectedAccountPeriodEndBalance.toStringAsFixed(2)}'
                                    : '\$0.00',
                                style: Theme.of(
                                  context,
                                ).textTheme.titleMedium?.copyWith(
                                  color:
                                      selectedAccountPeriodEndBalance == null
                                          ? Colors.grey
                                          : (selectedAccountPeriodEndBalance < 0
                                              ? Colors.red
                                              : Colors.green),
                                ),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                            ],
                          ),
                ),

                Expanded(
                  child: Column(
                    children: [
                      Text(
                        "Income:",
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      Text(
                        '\$${totalIncome.toStringAsFixed(2)}',
                        style: Theme.of(
                          context,
                        ).textTheme.titleMedium?.copyWith(color: Colors.green),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        "Expense:",
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      Text(
                        '-\$${totalExpense.toStringAsFixed(2)}',
                        style: Theme.of(
                          context,
                        ).textTheme.titleMedium?.copyWith(color: Colors.red),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        "Net: ",
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      Text(
                        netChange < 0
                            ? '-\$${netChange.abs().toStringAsFixed(2)}'
                            : '\$${netChange.toStringAsFixed(2)}',
                        style:
                            netChange > 0
                                ? Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(color: Colors.green)
                                : Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(color: Colors.red),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

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
                flex: 1,
                child: Align(
                  alignment: Alignment.centerRight,
                  child: IconButton(
                    icon: Icon(
                      _showCharts ? Icons.visibility_off : Icons.visibility,
                    ),
                    onPressed: _toggleChartVisibility, // Call navigation method
                    tooltip: _showCharts ? 'Hide Charts' : 'Show Charts',
                  ),
                ),
              ),
              Expanded(
                flex: 1,
                child: Align(
                  alignment: Alignment.centerRight,
                  child: IconButton(
                    icon: Icon(
                      _toggleToPieChart
                          ? Icons.bar_chart_rounded
                          : Icons.pie_chart,
                    ),
                    onPressed: _togglePieChart, // Call navigation method
                    tooltip:
                        _toggleToPieChart
                            ? 'Show Bar Charts'
                            : 'Show Pie Chart',
                  ),
                ),
              ),
              Expanded(
                flex: 5,
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

          _showCharts
              ? _toggleToPieChart
                  ? Row(
                    children: [
                      homePieChart(
                        title: 'Expenses',
                        pieData: pieChartExpenseData,
                        totalValue: totalExpense,
                      ),

                      homePieChart(
                        title: 'Income',
                        pieData: pieChartIncomeData,
                        totalValue: totalIncome,
                      ),
                    ],
                  )
                  : homePageBarChart(
                    maxYValueForChart: maxYValueForChart,
                    chartPoints: chartPoints,
                  )
              : SizedBox.shrink(),

          // _showCharts ? Divider(height: 1) : SizedBox.shrink(),
          Expanded(
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
                      itemCount: displayItems.length,
                      itemBuilder: (ctx, index) {
                        final item = displayItems[index];

                        if (item is DateSeparatorItem) {
                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16.0,
                              vertical: 8.0,
                            ),

                            alignment: Alignment.centerLeft,
                            child: Text(
                              DateFormat(
                                'EEE, dd MMM yyyy',
                              ).format(item.date), // e.g., Mon, 25 Dec 2023
                              style: Theme.of(context).textTheme.titleSmall
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                          );
                          // --- ---
                        } else if (item is TransactionItem) {
                          // --- Build TransactionsTile Widget ---
                          return TransactionsTile(
                            key: ValueKey(item.transaction.id),
                            transactionData: item.transaction,
                            accountName: item.accountName,
                            categoryTag: item.categoryForDisplay!,
                            onEdit: () {
                              _showTransactionsForm(item.transaction);
                            },
                            onDelete: (Transactions txToDelete) {
                              _onDelete(txToDelete);
                            },
                          );
                        }
                        // final transaction =
                        //     transactionsProvider.transactions[index];

                        // final Account associatedAccount = accountProvider
                        //     .accounts
                        //     .firstWhere(
                        //       (acc) => acc.id == transaction.accountId,
                        //     );
                        // final Category associatedCategory = categoryData
                        //     .firstWhere(
                        //       (cat) => cat.id == transaction.categoryId,
                        //     );

                        // // --- Return your TransactionsTile widget ---
                        // return TransactionsTile(
                        //   key: ValueKey(
                        //     transaction.id,
                        //   ), // Good for list performance
                        //   transactionData: transaction,
                        //   onEdit: () {
                        //     // Call the existing method to show the form for editing
                        //     _showTransactionsForm(transaction);
                        //   },
                        //   onDelete: (Transactions transactionToDelete) {
                        //     // Call the method to handle deletion
                        //     _onDelete(transactionToDelete);
                        //   },
                        //   accountName: associatedAccount.name,
                        //   categoryTag: associatedCategory,
                        // );
                        // // --- ---
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
  }
}
