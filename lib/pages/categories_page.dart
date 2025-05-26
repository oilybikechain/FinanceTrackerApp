import 'package:finance_tracker/data/category_class.dart';
import 'package:finance_tracker/services/category_provider.dart';
import 'package:finance_tracker/utilities/app_drawer.dart';
import 'package:finance_tracker/utilities/category_form.dart';
import 'package:finance_tracker/utilities/category_tile.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class CategoriesPage extends StatefulWidget {
  const CategoriesPage({super.key});

  @override
  State<CategoriesPage> createState() => _CategoriesPageState();
}

class _CategoriesPageState extends State<CategoriesPage> {
  bool _isInit = true;
  bool _isLoading = false;

  void _showCategoryForm([Category? categoryToEdit]) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return CategoryForm(existingCategory: categoryToEdit);
      },
    ).then((result) {
      if (result == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Category Created!'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    });
  }

  Future<void> _onDelete(Category categoryToDelete) async {
    // 2. Show Confirmation Dialog
    final currentContext = context;
    final bool? confirm = await showDialog<bool>(
      context: currentContext,
      builder:
          (ctx) => AlertDialog(
            title: const Text('Confirm Deletion'),
            content: Text(
              'Are you sure you want to delete the Category "${categoryToDelete.name}"?\nThis will change the transactions under this category to "General"',
            ),
            actions: [
              TextButton(
                child: const Text('Cancel'),
                onPressed:
                    () =>
                        Navigator.of(ctx).pop(false), // Return false on cancel
              ),
              TextButton(
                child: Text(
                  'Delete',
                  style: TextStyle(
                    color: Theme.of(currentContext).colorScheme.error,
                  ),
                ),
                onPressed:
                    () => Navigator.of(ctx).pop(true), // Return true on confirm
              ),
            ],
          ),
    );

    // 3. Check Dialog Result (and if widget still mounted)
    if (confirm != true || !mounted) {
      print("Deletion cancelled by user or widget unmounted.");
      return; // Exit if user cancelled or widget gone
    }

    // 4. Proceed with Deletion if Confirmed
    final categortyProvider = Provider.of<CategoryProvider>(
      currentContext,
      listen: false,
    ); // Use stored context
    final bool success = await categortyProvider.deleteCategory(
      categoryToDelete.id!,
    );

    // 5. Handle Final Result (check mounted again just in case)
    if (!mounted) return;

    if (success) {
      print("Delete successful.");
      ScaffoldMessenger.of(currentContext).showSnackBar(
        SnackBar(
          content: Text('${categoryToDelete.name} deleted successfully.'),
          duration: const Duration(seconds: 2),
        ),
      );
    } else {
      ScaffoldMessenger.of(currentContext).showSnackBar(
        SnackBar(
          content: Text('Failed to delete ${categoryToDelete.name}'),
          backgroundColor: Theme.of(currentContext).colorScheme.error,
        ),
      );
    }
  }

  @override
  void didChangeDependencies() {
    if (_isInit) {
      setState(() {
        _isLoading = true;
      });

      Provider.of<CategoryProvider>(
        context,
        listen: false,
      ).fetchCategories().then((_) {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      });
    }
    _isInit = false;
    super.didChangeDependencies();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Categories'),
        // The AppBar automatically shows the hamburger icon when a drawer is present
      ),
      drawer: const AppDrawer(), // Use the reusable drawer widget here!
      body: Consumer<CategoryProvider>(
        builder: (ctx, categoryProvider, child) {
          // Handle loading states (consider combined loading)

          // Data is ready
          final categoriesToView = categoryProvider.categories;

          return ListView.builder(
            itemCount: categoriesToView.length,
            itemBuilder: (context, index) {
              final categoryToDisplay = categoriesToView[index];

              return CategoryTile(
                key: ValueKey(categoryToDisplay.id!),
                categoryData: categoryToDisplay,

                onEdit: () {
                  _showCategoryForm(categoryToDisplay);
                },
                onDelete: () {
                  _onDelete(categoryToDisplay);
                },
              );
            },
          );
        },
      ),
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
