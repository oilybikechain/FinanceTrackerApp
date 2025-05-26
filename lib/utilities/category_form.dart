import 'package:finance_tracker/data/category_class.dart';
import 'package:finance_tracker/services/category_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:provider/provider.dart';

class CategoryForm extends StatefulWidget {
  final Category? existingCategory;
  const CategoryForm({super.key, this.existingCategory});

  @override
  State<CategoryForm> createState() => _CategoryFormState();
}

class _CategoryFormState extends State<CategoryForm> {
  //Form Key
  final _formkey = GlobalKey<FormState>();

  //Controllers
  final _categoryNameController = TextEditingController();
  Color pickedColor = Color(0xFFB0BEC5);
  Color tempColor = Color(0xFFB0BEC5);

  bool _isEditMode = false;

  final List<Color> _presetColors = [
    // Pinks & Reds
    const Color(0xFFFFCDD2), // Light Pink
    const Color(0xFFF8BBD0), // Pink 100
    const Color(0xFFF48FB1), // Pink 200
    const Color(0xFFFFE0E0), // Very Light Red/Pink
    const Color(0xFFFFCBCB), // Lighter Coral Pink
    // Oranges & Yellows
    const Color(0xFFFFE0B2), // Light Orange (Peach)
    const Color(0xFFFFD180), // Orange Accent 100
    const Color(0xFFFFCC80), // Orange 200
    const Color(0xFFFFF9C4), // Light Yellow
    const Color(0xFFFFF59D), // Yellow 200
    // Greens
    const Color(0xFFC8E6C9), // Light Green
    const Color(0xFFA5D6A7), // Green 200
    const Color(0xFFDCE775), // Lime 300 (Pastel-ish)
    const Color(0xFFF0F4C3), // Very Light Lime
    const Color(0xFFCCFF90), // Light Green Accent 100 (Minty)
    // Blues
    const Color(0xFFBBDEFB), // Light Blue
    const Color(0xFF90CAF9), // Blue 200
    const Color(0xFFB3E5FC), // Light Blue 100
    const Color(0xFFB2EBF2), // Light Cyan
    const Color(0xFFA0E6FF), // Lighter Sky Blue
    // Purples & Violets
    const Color(0xFFD1C4E9), // Light Purple (Lavender)
    const Color(0xFFB39DDB), // Deep Purple 200
    const Color(0xFFE1BEE7), // Light Purple/Pink
    const Color(0xFFCE93D8), // Purple 200
    const Color(0xFFF3E5F5), // Very Light Purple (Lilac)
    // Neutrals & Greys (Pastel-like)
    const Color(0xFFCFD8DC), // Blue Grey 100
    const Color(0xFFB0BEC5), // Blue Grey 200 (You had this one!)
    const Color(0xFFD7CCC8), // Brown 100 (Light Taupe)
    const Color(0xFFEEEEEE), // Grey 200 (Very Light Grey)
    const Color(0xFFE0E0E0), // Grey 300 (Light Grey)
  ];

  Widget buildColorPicker() => ColorPicker(
    pickerColor: tempColor,
    onColorChanged: (color) => tempColor = color,
    enableAlpha: false,
    labelTypes: const [],
    pickerAreaHeightPercent: 0.7,
  );

  Widget buildColorSelector() => BlockPicker(
    pickerColor: pickedColor,
    availableColors: _presetColors,
    onColorChanged: (color) {
      setState(() {
        pickedColor = color;
      });
    },
    // --- CUSTOMIZE ITEM SIZE ---
    itemBuilder: (color, isCurrentColor, changeColor) {
      return GestureDetector(
        // Use GestureDetector for onTap
        onTap: changeColor, // This is the callback from BlockPicker
        child: Container(
          width: 30, // <<< DECREASED ITEM WIDTH
          height: 30, // <<< DECREASED ITEM HEIGHT
          margin: const EdgeInsets.all(3), // Smaller margin
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color,
            border:
                isCurrentColor
                    ? Border.all(
                      color: Theme.of(context).colorScheme.primary,
                      width: 4,
                    )
                    : null, // Border only if selected
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.15),
                blurRadius: 2,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          // Optional: Show a checkmark on selected
          // child: isCurrentColor
          //     ? Icon(Icons.check, color: useWhiteForeground(color) ? Colors.white : Colors.black, size: 16)
          //     : null,
        ),
      );
    },
    // --- ---
    // Optional: Customize layout for better density
    layoutBuilder: (context, colors, child) {
      return Wrap(
        spacing: 6.0, // Horizontal space between chips
        runSpacing: 6.0, // Vertical space between lines of chips
        children: colors.map((color) => child(color)).toList(),
      );
    },
  );

  void pickColor(BuildContext context) {
    tempColor = pickedColor;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (dialogContext) => AlertDialog(
            title: Text("Custom Colour"),
            content: SizedBox(
              height: MediaQuery.of(dialogContext).size.height * 0.4,
              width: double.maxFinite,
              child: Column(
                children: [
                  SingleChildScrollView(child: buildColorPicker()),
                  Row(
                    children: [
                      TextButton(
                        child: Text('Select'),
                        onPressed: () {
                          pickedColor = tempColor;

                          setState(() {});
                          Navigator.of(dialogContext).pop();
                          FocusScope.of(context).unfocus();
                        },
                      ),
                      SizedBox(width: 12),
                      TextButton(
                        onPressed: () {
                          Navigator.of(dialogContext).pop();
                          FocusScope.of(context).unfocus();
                        },
                        child: Text("Cancel"),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
    );
  }

  @override
  void initState() {
    super.initState();
    if (widget.existingCategory != null) {
      _isEditMode = true;
      final category = widget.existingCategory!; // We know it's not null here

      _categoryNameController.text = category.name;
      if (category.colorValue != null) {
        pickedColor = Color(
          category.colorValue!,
        ); // Set pickedColor from existing
      }
    } else {
      _isEditMode = false;
      pickedColor = _presetColors[0]; // Default to first preset
    }
  }

  @override
  void dispose() {
    _categoryNameController.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    final isValid = _formkey.currentState?.validate() ?? false;

    if (!isValid) {
      print('invalid Form');
      return;
    }

    final categoryName = _categoryNameController.text;
    final selectedColor = pickedColor;
    final int colorValueToSave = selectedColor.value;
    print(colorValueToSave.toString());

    final categoryProvider = Provider.of<CategoryProvider>(
      context,
      listen: false,
    );
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final theme = Theme.of(context);

    bool success = false;

    try {
      if (_isEditMode) {
        print("Updating category ID: ${widget.existingCategory!.id}");
        final updatedCategory = widget.existingCategory!.copyWith(
          name: categoryName,
          colorValue: colorValueToSave,
        );
        success = await categoryProvider.updateCategory(updatedCategory);
      } else {
        print("Creating new category: $categoryName");
        final newCategory = Category(
          name: categoryName,
          colorValue: colorValueToSave,
          isSystemDefault: false,
        );
        success = await categoryProvider.addCategory(newCategory);
      }
    } catch (e) {
      print("Error submitting category form: $e");
      success = false;
    }

    if (!mounted) {
      return;
    }

    if (success) {
      print("Category added successfully via provider.");
      navigator.pop(true);
    } else {
      print("Provider indicated failure or an error occurred.");
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            categoryProvider.error ??
                'Failed to add category. Please try again.',
          ),
          backgroundColor: theme.colorScheme.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: EdgeInsets.only(
        top: 60,
        left: 16,
        right: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Form(
        key: _formkey,
        child: Column(
          children: [
            Text(
              'Add New Category',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _categoryNameController,

              decoration: InputDecoration(
                labelText: 'Category Name',
                hintText: 'Groceries, Transport',
                border: OutlineInputBorder(),
              ),

              textInputAction: TextInputAction.done,

              textCapitalization: TextCapitalization.words,

              validator: (value) {
                if (value == null) {
                  return 'Please enter a category name.';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            Padding(
              padding: const EdgeInsets.only(left: 12, right: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start, // Align items
                crossAxisAlignment:
                    CrossAxisAlignment.center, // Vertically center
                children: [
                  Text(
                    "Picked Color:",
                    style:
                        textTheme
                            .titleMedium, // Slightly larger title for the section
                  ),
                  SizedBox(width: 20),
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: pickedColor, // Shows the currently selected color
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Theme.of(context).dividerColor,
                        width: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),

            Padding(
              padding: const EdgeInsets.only(left: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Text(
                    "Presets:",
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),

            buildColorSelector(),

            const SizedBox(height: 16),

            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                ElevatedButton(
                  onPressed: () => {pickColor(context)},
                  child: Text("Custom Color"),
                ),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('CANCEL'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _submitForm,
                  child: Text(_isEditMode ? 'EDIT CATEGORY' : 'ADD CATEGORY'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
