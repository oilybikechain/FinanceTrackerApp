import 'package:flutter/material.dart';
import 'package:finance_tracker/data/category_class.dart';
import 'package:finance_tracker/services/database_service.dart';
import 'package:finance_tracker/services/settings_service.dart'; // For default transaction category preference

class CategoryProvider with ChangeNotifier {
  final DatabaseService _dbService = DatabaseService();
  final SettingsService _settingsService =
      SettingsService(); // For default category

  List<Category> _categories = [];
  bool _isLoading = false;
  String? _error;

  List<Category> get categories => _categories;
  bool get isLoading => _isLoading;
  String? get error => _error; // Getter for error messages

  // To store the user's preferred default category object (not just ID)
  Category? _userDefaultTransactionCategory;
  Category? get userDefaultTransactionCategory =>
      _userDefaultTransactionCategory;

  CategoryProvider() {
    // Fetch categories and then the user's default preference when provider is created
    _initializeCategoriesAndDefault();
  }

  Future<void> _initializeCategoriesAndDefault() async {
    await fetchCategories(); // Load all categories
    await loadUserDefaultTransactionCategory(); // Then load user's preference
  }

  Future<void> fetchCategories() async {
    _isLoading = true;
    _error = null;
    // No initial notifyListeners for loading, let UI decide based on data
    try {
      _categories = await _dbService.getCategories();
      print("CategoryProvider: Fetched ${_categories.length} categories.");
    } catch (e) {
      print("Error fetching categories: $e");
      _error = "Failed to load categories.";
      _categories = [];
    } finally {
      _isLoading = false;
      notifyListeners(); // Notify after fetching or error
    }
  }

  // Load the user's preferred default category (object)
  Future<void> loadUserDefaultTransactionCategory() async {
    final int? defaultId =
        await _settingsService.getDefaultTransactionCategoryId();
    if (defaultId != null && _categories.isNotEmpty) {
      _userDefaultTransactionCategory = _categories.firstWhere(
        (cat) => cat.id == defaultId,
      );
    } else {
      _userDefaultTransactionCategory = null;
    }
    // If no user default, or it's invalid, try to set "General" as a fallback for UI hint
    if (_userDefaultTransactionCategory == null && _categories.isNotEmpty) {
      _userDefaultTransactionCategory = _categories.firstWhere(
        (cat) => cat.name.toLowerCase() == 'general' && cat.isSystemDefault,
        orElse: () => _categories.first, // Absolute fallback
      );
    }
    notifyListeners(); // Notify about change in default category (if any)
    print(
      "CategoryProvider: User default transaction category: ${_userDefaultTransactionCategory?.name}",
    );
  }

  // Set user's default transaction category preference
  Future<void> setUserDefaultTransactionCategory(Category? category) async {
    await _settingsService.setDefaultTransactionCategoryId(category?.id);
    _userDefaultTransactionCategory = category; // Update local state
    notifyListeners();
    print("CategoryProvider: User default set to: ${category?.name}");
  }

  Future<bool> addCategory(String name, Color color) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    if (_categories.any(
      (cat) => cat.name.toLowerCase() == name.trim().toLowerCase(),
    )) {
      _error = "Category '$name' already exists.";
      _isLoading = false;
      notifyListeners();
      return false;
    }

    try {
      final newCategory = Category(name: name.trim(), colorValue: color.value);
      int id = await _dbService.insertCategory(newCategory);
      if (id > 0) {
        await fetchCategories(); // Re-fetch to get the new list including the ID and keep sorted
        return true; // Success
      }
      _error = "Failed to save category to database.";
      _isLoading = false;
      notifyListeners();
      return false; // DB insert failed
    } catch (e) {
      print("Error adding category: $e");
      _error = "An error occurred while adding the category.";
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateCategory(Category category) async {
    // ... (implement similarly: call _dbService.updateCategory, then fetchCategories)
    // Handle potential name conflicts if name is changed to an existing one.
    // Prevent editing name of system default categories.
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      if (category.isSystemDefault) {
        // Check if it's a system default
        // Find original category from DB to see if name is being changed
        Category? originalCategory = await _dbService.getCategoryById(
          category.id!,
        );
        if (originalCategory != null &&
            originalCategory.name != category.name) {
          _error = "Cannot change the name of a default category.";
          _isLoading = false;
          notifyListeners();
          return false;
        }
      }

      int rowsAffected = await _dbService.updateCategory(category);
      if (rowsAffected > 0) {
        await fetchCategories();
        return true;
      }
      _error = "Failed to update category.";
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      print("Error updating category: $e");
      if (e.toString().toLowerCase().contains("unique constraint failed")) {
        _error = "Category name '${category.name}' already exists.";
      } else {
        _error = "An error occurred while updating category.";
      }
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteCategory(int id) async {
    // ... (implement similarly: call _dbService.deleteCategory, then fetchCategories)
    // _dbService.deleteCategory already prevents deleting system defaults.
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      // Check if this category is the user's default
      final currentDefaultId =
          await _settingsService.getDefaultTransactionCategoryId();
      if (currentDefaultId == id) {
        await _settingsService.setDefaultTransactionCategoryId(
          null,
        ); // Clear default
        _userDefaultTransactionCategory = null; // Update local state
      }

      int rowsAffected = await _dbService.deleteCategory(id);
      if (rowsAffected > 0) {
        await fetchCategories(); // This will also re-evaluate the fallback default if needed
        return true;
      }
      _error =
          "Category not found or could not be deleted (might be a default category).";
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      print("Error deleting category: $e");
      _error = "An error occurred while deleting category.";
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
}
