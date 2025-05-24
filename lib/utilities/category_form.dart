import 'package:finance_tracker/services/category_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:provider/provider.dart';

class CategoryForm extends StatefulWidget {
  const CategoryForm({super.key});

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

  Widget buildColorPicker() => ColorPicker(
    pickerColor: tempColor,
    enableAlpha: false,
    labelTypes: [],
    onColorChanged: (color) => tempColor = color,
  );

  Widget buildColorSelector() => BlockPicker(
    pickerColor: pickedColor,
    availableColors: [
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
    ],
    onColorChanged: (color) {
      pickedColor = color;
      setState(() {});
    },
  );

  void pickColor(BuildContext context) {
    tempColor = pickedColor;
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text("Custom Colour"),
            content: Column(
              children: [
                buildColorPicker(),
                Row(
                  children: [
                    TextButton(
                      child: Text('Select'),
                      onPressed: () {
                        pickedColor = tempColor;
                        setState(() {});
                        Navigator.of(context).pop();
                      },
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text("Cancel"),
                    ),
                  ],
                ),
              ],
            ),
          ),
    );
  }

  @override
  void dispose() {
    _categoryNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: EdgeInsets.only(
        top: 50,
        left: 15,
        right: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Form(
        key: _formkey,
        child: ListView(
          children: [
            Text(
              // Assuming you want a title for the form
              'Add New Category',
              style: textTheme.headlineSmall,
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

            ElevatedButton.icon(
              onPressed: () => pickColor(context),
              label: Text("Click for custom colour"),
              icon: Icon(Icons.circle, color: pickedColor),
            ),

            buildColorSelector(),
          ],
        ),
      ),
    );
  }
}
