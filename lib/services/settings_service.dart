import 'package:shared_preferences/shared_preferences.dart';

class SettingsService {
  static const String _defaultCategoryIdKey = 'default_transaction_category_id';

  Future<void> setDefaultTransactionCategoryId(int? categoryId) async {
    final prefs = await SharedPreferences.getInstance();
    if (categoryId == null) {
      await prefs.setInt(
        _defaultCategoryIdKey,
        1,
      ); // Remove if setting to no default
      print("Default transaction category cleared.");
    } else {
      await prefs.setInt(_defaultCategoryIdKey, categoryId);
      print("Default transaction category set to ID: $categoryId");
    }
  }

  Future<int?> getDefaultTransactionCategoryId() async {
    final prefs = await SharedPreferences.getInstance();
    final int? categoryId = prefs.getInt(_defaultCategoryIdKey);
    print("Loaded default transaction category ID: $categoryId");
    return categoryId;
  }
}
