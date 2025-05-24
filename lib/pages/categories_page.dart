import 'package:finance_tracker/utilities/app_drawer.dart';
import 'package:finance_tracker/utilities/category_form.dart';
import 'package:flutter/material.dart';

class CategoriesPage extends StatefulWidget {
  const CategoriesPage({super.key});

  @override
  State<CategoriesPage> createState() => _CategoriesPageState();
}

class _CategoriesPageState extends State<CategoriesPage> {
  void _showCategoryForm() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return CategoryForm();
      },
    );
    // .then(result) {
    //   if (result == true) {
    //     ScaffoldMessenger.of(context).showSnackBar(
    //       SnackBar(
    //         content: Text(
    //           'Category Created!',
    //         ),
    //         duration: const Duration(seconds: 2),
    //       ),
    //     );
    //   }
    // }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Categories'),
        // The AppBar automatically shows the hamburger icon when a drawer is present
      ),
      drawer: const AppDrawer(), // Use the reusable drawer widget here!
      body: const Center(child: Text('Categories Page')),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _showCategoryForm();
        },
        tooltip: 'Add Account',
        child: const Icon(Icons.add),
      ),
    );
  }
}
