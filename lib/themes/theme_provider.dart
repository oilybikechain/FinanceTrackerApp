import 'package:finance_tracker/services/settings_service.dart';
import 'package:finance_tracker/themes/theme.dart';
import 'package:flutter/material.dart';

class ThemeProvider with ChangeNotifier {
  final SettingsService _settingsService = SettingsService();
  late ThemeData _themeData;

  ThemeProvider() {
    _themeData = darkMode;
    _loadThemePreference();
  }

  ThemeData get themeData => _themeData;

  Future<void> _loadThemePreference() async {
    bool isDarkModeSaved = await _settingsService.getDarkModeToggle();
    _themeData = isDarkModeSaved ? darkMode : lightMode;
    print(
      "ThemeProvider: Loaded theme preference. Is dark mode: $isDarkModeSaved",
    );
    notifyListeners(); // Notify after theme is loaded
  }

  void toggleTheme() {
    ThemeData newTheme;
    if (_themeData == lightMode) {
      newTheme = darkMode;
    } else {
      newTheme = lightMode;
    }

    if (_themeData != newTheme) {
      // Check if theme actually changed
      _themeData = newTheme;
      bool isNowDarkMode = (newTheme == darkMode);
      _settingsService.setDarkModeToggle(
        isNowDarkMode,
      ); // Save the new preference
      print(
        "ThemeProvider: Theme toggled. Is dark mode: $isNowDarkMode. Saved.",
      );
      notifyListeners();
    }
  }
}
