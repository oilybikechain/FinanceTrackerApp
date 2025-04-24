import 'package:finance_tracker/utilities/app_drawer.dart';
import 'package:flutter/material.dart';

class StatisticsPage extends StatelessWidget {
  const StatisticsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Statistics'),
        // The AppBar automatically shows the hamburger icon when a drawer is present
      ),
      drawer: const AppDrawer(), // Use the reusable drawer widget here!
      body: const Center(
        child: Text('Statistics'),
      ),
    );
  }
}