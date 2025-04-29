import 'package:finance_tracker/data/account_provider.dart';
import 'package:finance_tracker/data/recurring_transactions_provider.dart';
import 'package:finance_tracker/data/transactions_provider.dart';
import 'package:finance_tracker/pages/accounts_page.dart';
import 'package:finance_tracker/pages/home_page.dart';
import 'package:finance_tracker/pages/statistics_page.dart';
import 'package:finance_tracker/themes/theme_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => ThemeProvider()),
        ChangeNotifierProvider(create: (context) => AccountProvider()),
        ChangeNotifierProvider(create: (context) => TransactionsProvider()),
        ChangeNotifierProvider(create: (context) => RecurringTransactionsProvider()),
        ],
        child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: HomePage(),
      theme: Provider.of<ThemeProvider>(context).themeData,
      routes: {
        '/homepage':(context) => HomePage(),
        '/accountspage':(context) => AccountsPage(),
        '/statisticspage':(context) => StatisticsPage(),
      },
    );
  }
}
