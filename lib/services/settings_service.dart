import 'package:shared_preferences/shared_preferences.dart';

class SettingsService {
  static const String _showChartsKey = 'show_charts_preference';
  static const String _changeToPieChartKey = 'chart_type_preference';
  static const String _darkModeToggle = 'dark_mode_preference';

  // --- Chart Visibility Preference ---
  Future<void> setShowChartsPreference(bool show) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_showChartsKey, show);
    print("Chart visibility preference saved: $show");
  }

  Future<bool> getShowChartsPreference() async {
    final prefs = await SharedPreferences.getInstance();
    // Default to true (show charts) if no preference is saved
    return prefs.getBool(_showChartsKey) ?? true;
  }

  // --- Chart Type Preference ---
  Future<void> setChartTypePreference(bool changeToPieChart) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(
      _changeToPieChartKey,
      changeToPieChart,
    ); // Store enum name as string
    print("Chart type preference saved: ${changeToPieChart}");
  }

  Future<bool> getChartTypePreference() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_changeToPieChartKey) ?? false;
  }

  Future<void> setDarkModeToggle(bool dark) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_darkModeToggle, dark);
    print("Chart visibility preference saved: $dark");
  }

  Future<bool> getDarkModeToggle() async {
    final prefs = await SharedPreferences.getInstance();
    // Default to true (show charts) if no preference is saved
    return prefs.getBool(_darkModeToggle) ?? true;
  }
}
