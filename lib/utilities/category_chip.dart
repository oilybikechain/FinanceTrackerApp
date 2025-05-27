// lib/widgets/category_chip.dart (Create this new file)
import 'package:flutter/material.dart';
import '../data/category_class.dart'; // Adjust import if your Category class is elsewhere

class CategoryChip extends StatelessWidget {
  final Category category;
  final bool isSelected;
  final ValueChanged<int?> onSelected; // Passes the category ID when selected

  const CategoryChip({
    super.key,
    required this.category,
    required this.isSelected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final Color chipBackgroundColor =
        isSelected
            ? theme.colorScheme.primaryContainer
            : theme.colorScheme.surfaceVariant.withOpacity(0.7);
    final Color chipForegroundColor =
        isSelected
            ? theme.colorScheme.onPrimaryContainer
            : theme.colorScheme.onSurfaceVariant;
    final Color streakColor =
        category.color; // Use category.color (which should be a Color object)

    return Material(
      // Use Material for InkWell splash effects
      color: Colors.transparent, // Material itself is transparent
      child: InkWell(
        onTap: () {
          onSelected(category.id); // Call the callback with the category's ID
        },
        borderRadius: BorderRadius.circular(
          8.0,
        ), // Match the Card's border radius
        child: Card(
          // Use Card for elevation and defined shape
          elevation: 0,
          margin: const EdgeInsets.all(
            1.0,
          ), // Small margin so border doesn't touch splash
          color: chipBackgroundColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8.0),
            side:
                isSelected
                    ? BorderSide(color: theme.colorScheme.primary, width: 1.5)
                    : BorderSide(
                      color: theme.dividerColor.withOpacity(0.5),
                      width: 1.0,
                    ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min, // Make Row take minimum space
            children: [
              // Color Streak
              Container(
                width: 6.0, // Width of the color streak
                height:
                    26.0, // Make it roughly the height of the chip content (adjust)
                decoration: BoxDecoration(
                  color: streakColor,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(
                      7.0,
                    ), // Slightly less than Card's radius
                    bottomLeft: Radius.circular(7.0),
                  ),
                ),
              ),
              // Text Label
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 6.0,
                  vertical: 4.0,
                ),
                child: Text(
                  category.name,
                  style: TextStyle(
                    fontWeight:
                        isSelected ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
