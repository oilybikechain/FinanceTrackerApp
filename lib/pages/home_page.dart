import 'package:finance_tracker/utilities/app_drawer.dart';
import 'package:flutter/material.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Homepage'),
      ),
      drawer: const AppDrawer(), // Use the reusable drawer widget here!
      body: const Center(
        child: Text('HomePage'),
      ),
      floatingActionButton:
          FloatingActionButton(
            onPressed: () {
            },
            tooltip: 'Add Transaction',
            child: const Icon(Icons.add),
          ),
    );;
  }
}