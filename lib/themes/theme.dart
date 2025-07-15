// lib/themes.dart
import 'package:flutter/material.dart';
// Optional: import 'package:google_fonts/google_fonts.dart'; // Uncomment if using Google Fonts

// --- Core Color Definitions ---
const Color primaryLight = Color.fromARGB(255, 168, 142, 103);
const Color secondaryLight = Color(0xFF4FC3F7);
const Color backgroundLight = Color(
  0xFFF2F2F7,
); // Intended for Scaffold background
const Color surfaceLight = Colors.white; // Intended for Cards, AppBars, Dialogs
const Color onPrimaryLight = Colors.white;
const Color onSecondaryLight = Colors.black;
// const Color onBackgroundLight = Colors.black; // Keep for reference, but use onSurfaceLight
const Color onSurfaceLight =
    Colors.black; // Primary text color on light surfaces/backgrounds
const Color errorLight = Colors.redAccent;

const Color primaryDark = Color(0xFF0A84FF);
const Color secondaryDark = Color(0xFF64D2FF);
const Color backgroundDark = Color(
  0xFF000000,
); // Intended for Scaffold background
const Color surfaceDark = Color(
  0xFF1C1C1E,
); // Intended for Cards, AppBars, Dialogs
const Color onPrimaryDark = Colors.white;
const Color onSecondaryDark = Colors.black;
// const Color onBackgroundDark = Colors.white; // Keep for reference, but use onSurfaceDark
const Color onSurfaceDark =
    Colors.white; // Primary text color on dark surfaces/backgrounds
const Color errorDark = Color(0xFFFF453A);

// --- Light Theme Definition ---

// Define the ColorScheme without deprecated fields
const ColorScheme lightColorScheme = ColorScheme.light(
  primary: primaryLight,
  secondary: secondaryLight,
  surface: surfaceLight, // Use surface for component backgrounds
  error: errorLight,
  onPrimary: onPrimaryLight,
  onSecondary: onSecondaryLight,
  onSurface: onSurfaceLight, // Use onSurface for text on components/background
  onError: Colors.white,
  brightness: Brightness.light,
  // No 'background' or 'onBackground' here
);

// Define the full ThemeData for light mode
final ThemeData lightMode = ThemeData(
  brightness: Brightness.light,
  colorScheme: lightColorScheme,

  // Set scaffold background using our defined constant
  scaffoldBackgroundColor: backgroundLight, // Correct: Use the constant

  appBarTheme: AppBarTheme(
    backgroundColor:
        lightColorScheme.surface, // Correct: Use surface for AppBar
    foregroundColor: lightColorScheme.onSurface,
    elevation: 1.0,
    iconTheme: IconThemeData(color: lightColorScheme.primary),
    titleTextStyle: TextStyle(
      color: lightColorScheme.onSurface,
      fontSize: 20,
      fontWeight: FontWeight.w600,
      // fontFamily: GoogleFonts.lato().fontFamily,
    ),
  ),

  // Update TextTheme to use onSurface
  textTheme: ThemeData.light().textTheme.apply(
    bodyColor: lightColorScheme.onSurface, // Correct: Use onSurface
    displayColor: lightColorScheme.onSurface, // Correct: Use onSurface
    // fontFamily: GoogleFonts.lato().fontFamily,
  ),

  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: lightColorScheme.primary,
      foregroundColor: lightColorScheme.onPrimary,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    ),
  ),
  textButtonTheme: TextButtonThemeData(
    style: TextButton.styleFrom(foregroundColor: lightColorScheme.primary),
  ),
  outlinedButtonTheme: OutlinedButtonThemeData(
    style: OutlinedButton.styleFrom(
      foregroundColor: lightColorScheme.primary,
      side: BorderSide(
        color: lightColorScheme.primary.withAlpha((0.5 * 255).round()),
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    ),
  ),

  cardTheme: CardTheme(
    color: lightColorScheme.surface,
    elevation: 2.0,
    margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
  ),

  floatingActionButtonTheme: FloatingActionButtonThemeData(
    backgroundColor: lightColorScheme.secondary,
    foregroundColor: lightColorScheme.onSecondary,
  ),

  inputDecorationTheme: InputDecorationTheme(
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide(
        color: lightColorScheme.primary.withAlpha((0.3 * 255).round()),
      ),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide(
        color: lightColorScheme.primary.withAlpha((0.3 * 255).round()),
      ),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide(color: lightColorScheme.primary, width: 2.0),
    ),
    labelStyle: TextStyle(
      color: lightColorScheme.onSurface.withAlpha((0.7 * 255).round()),
    ),
  ),

  visualDensity: VisualDensity.adaptivePlatformDensity,
);

// --- Dark Theme Definition ---

// Define the ColorScheme without deprecated fields
const ColorScheme darkColorScheme = ColorScheme.dark(
  primary: primaryDark,
  secondary: secondaryDark,
  surface: surfaceDark, // Use surface for component backgrounds
  error: errorDark,
  onPrimary: onPrimaryDark,
  onSecondary: onSecondaryDark,
  onSurface: onSurfaceDark, // Use onSurface for text on components/background
  onError: Colors.black,
  brightness: Brightness.dark,
  // No 'background' or 'onBackground' here
);

// Define the full ThemeData for dark mode
final ThemeData darkMode = ThemeData(
  brightness: Brightness.dark,
  colorScheme: darkColorScheme,

  // Set scaffold background using our defined constant
  scaffoldBackgroundColor: backgroundDark, // Correct: Use the constant

  appBarTheme: AppBarTheme(
    backgroundColor: darkColorScheme.surface, // Correct: Use surface for AppBar
    foregroundColor: darkColorScheme.onSurface,
    elevation: 1.0,
    iconTheme: IconThemeData(color: darkColorScheme.primary),
    titleTextStyle: TextStyle(
      color: darkColorScheme.onSurface,
      fontSize: 20,
      fontWeight: FontWeight.w600,
      // fontFamily: GoogleFonts.lato().fontFamily,
    ),
  ),

  // Update TextTheme to use onSurface
  textTheme: ThemeData.dark().textTheme.apply(
    bodyColor: darkColorScheme.onSurface, // Correct: Use onSurface
    displayColor: darkColorScheme.onSurface, // Correct: Use onSurface
    // fontFamily: GoogleFonts.lato().fontFamily,
  ),

  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: darkColorScheme.primary,
      foregroundColor: darkColorScheme.onPrimary,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    ),
  ),
  textButtonTheme: TextButtonThemeData(
    style: TextButton.styleFrom(foregroundColor: darkColorScheme.primary),
  ),
  outlinedButtonTheme: OutlinedButtonThemeData(
    style: OutlinedButton.styleFrom(
      foregroundColor: darkColorScheme.primary,
      side: BorderSide(
        color: darkColorScheme.primary.withAlpha((0.7 * 255).round()),
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    ),
  ),

  cardTheme: CardTheme(
    color: darkColorScheme.surface,
    elevation: 2.0,
    margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
  ),

  floatingActionButtonTheme: FloatingActionButtonThemeData(
    backgroundColor: darkColorScheme.secondary,
    foregroundColor: darkColorScheme.onSecondary,
  ),

  inputDecorationTheme: InputDecorationTheme(
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide(
        color: darkColorScheme.primary.withAlpha((0.3 * 255).round()),
      ),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide(
        color: darkColorScheme.primary.withAlpha((0.3 * 255).round()),
      ),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide(color: darkColorScheme.primary, width: 2.0),
    ),
    labelStyle: TextStyle(
      color: darkColorScheme.onSurface.withAlpha((0.7 * 255).round()),
    ),
    hintStyle: TextStyle(
      color: darkColorScheme.onSurface.withAlpha((0.5 * 255).round()),
    ),
  ),

  visualDensity: VisualDensity.adaptivePlatformDensity,
);
