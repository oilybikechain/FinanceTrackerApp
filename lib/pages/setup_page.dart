import 'package:flutter/material.dart';
import 'accounts_page.dart';
import 'categories_page.dart';
import 'recurring_transactions_page.dart';

class SetupPage extends StatefulWidget {
  const SetupPage({super.key});

  @override
  State<SetupPage> createState() => _SetupPageState();
}

class _SetupPageState extends State<SetupPage> {
  int _selectedIndex = 0;
  static final List<Widget> _widgetOptions = <Widget>[
    AccountsPage(),
    CategoriesPage(),
    RecurringTransactionsPage(),
  ];

  void _onIteptapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(child: _widgetOptions.elementAt(_selectedIndex)),
      bottomNavigationBar: BottomNavigationBar(
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.account_balance),
            label: "Accounts",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.category_outlined),
            label: "Categories",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.repeat),
            label: "Recurring Transactions",
          ),
        ],
        currentIndex: _selectedIndex,
        onTap: _onIteptapped,
      ),
    );
  }
}
