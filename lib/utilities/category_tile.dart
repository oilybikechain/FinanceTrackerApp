import 'package:finance_tracker/data/category_class.dart';
import 'package:flutter/material.dart';

class CategoryTile extends StatelessWidget {
  final Category categoryData;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const CategoryTile({
    super.key,
    required this.categoryData,
    this.onDelete,
    this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        child: ListTile(
          leading: Container(
            // Use leading for the color circle
            width: 24, // Fixed size for the color circle
            height: 24,
            decoration: BoxDecoration(
              // Use categoryData.color getter which handles null colorValue
              color: categoryData.color,
              shape: BoxShape.circle,
              border: Border.all(
                color: Theme.of(
                  context,
                ).dividerColor.withOpacity(0.5), // Softer border
                width: 1.0,
              ),
            ),
          ),
          title: Text(
            categoryData.name,
            style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w500),
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              categoryData.isSystemDefault == false
                  ? IconButton(
                    icon: Icon(
                      Icons.delete_outline,
                      size: 20,
                      color: colorScheme.error,
                    ),
                    tooltip: 'Delete Account',
                    onPressed: onDelete,
                  )
                  : SizedBox(),

              IconButton(
                icon: Icon(Icons.edit, size: 20, color: colorScheme.secondary),
                tooltip: 'Edit Account',
                onPressed: onEdit,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
