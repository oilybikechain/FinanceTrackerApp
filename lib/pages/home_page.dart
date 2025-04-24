import 'package:finance_tracker/utilities/app_drawer.dart';
import 'package:flutter/material.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
        // The AppBar automatically shows the hamburger icon when a drawer is present
      ),
      drawer: const AppDrawer(), // Use the reusable drawer widget here!
      body: const Center(
        child: Text('Home Page Content'),
      ),
    );
  }
}