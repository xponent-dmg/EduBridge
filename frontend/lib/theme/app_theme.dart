import 'package:flutter/material.dart';

class AppTheme {
  // Primary colors
  static const Color primaryColor = Color(0xFF1E88E5); // Blue shade
  static const Color secondaryColor = Color(0xFF26A69A); // Teal shade
  static const Color accentColor = Color(0xFF7E57C2); // Purple accent

  // Neutral colors
  static const Color backgroundLight = Color(0xFFF5F7FA);
  static const Color backgroundDark = Color(0xFF121212);
  static const Color cardLight = Colors.white;
  static const Color cardDark = Color(0xFF1E1E1E);

  // Text colors
  static const Color textDark = Color(0xFF303030);
  static const Color textLight = Color(0xFFF5F5F5);
  static const Color textMuted = Color(0xFF757575);

  // Status colors
  static const Color success = Color(0xFF4CAF50);
  static const Color warning = Color(0xFFFFC107);
  static const Color error = Color(0xFFE53935);
  static const Color info = Color(0xFF2196F3);

  // Gradient colors
  static const List<Color> primaryGradient = [Color(0xFF1E88E5), Color(0xFF26A69A)];

  // Create light theme
  static ThemeData lightTheme() {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.light(
        primary: primaryColor,
        secondary: secondaryColor,
        tertiary: accentColor,
        background: backgroundLight,
        surface: cardLight,
        onSurface: textDark,
        onBackground: textDark,
        error: error,
      ),
      scaffoldBackgroundColor: backgroundLight,
      appBarTheme: const AppBarTheme(
        backgroundColor: primaryColor,
        foregroundColor: textLight,
        elevation: 0,
        centerTitle: true,
      ),
      cardTheme: CardTheme(
        color: cardLight,
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 0),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: textLight,
          elevation: 2,
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryColor,
          side: const BorderSide(color: primaryColor),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryColor,
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.grey.shade100,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: primaryColor, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: error, width: 2),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: error, width: 2),
        ),
      ),
      textTheme: const TextTheme(
        displayLarge: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: textDark),
        displayMedium: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: textDark),
        displaySmall: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: textDark),
        headlineLarge: TextStyle(fontSize: 22, fontWeight: FontWeight.w600, color: textDark),
        headlineMedium: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: textDark),
        headlineSmall: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: textDark),
        titleLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: textDark),
        titleMedium: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: textDark),
        titleSmall: TextStyle(fontSize: 14, fontWeight: FontWeight.normal, color: textDark),
        bodyLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.normal, color: textDark),
        bodyMedium: TextStyle(fontSize: 14, fontWeight: FontWeight.normal, color: textDark),
        bodySmall: TextStyle(fontSize: 12, fontWeight: FontWeight.normal, color: textMuted),
      ),
    );
  }

  // Create dark theme
  static ThemeData darkTheme() {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.dark(
        primary: primaryColor,
        secondary: secondaryColor,
        tertiary: accentColor,
        background: backgroundDark,
        surface: cardDark,
        onSurface: textLight,
        onBackground: textLight,
        error: error,
      ),
      scaffoldBackgroundColor: backgroundDark,
      appBarTheme: AppBarTheme(backgroundColor: cardDark, foregroundColor: textLight, elevation: 0, centerTitle: true),
      cardTheme: CardTheme(
        color: cardDark,
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 0),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: textLight,
          elevation: 2,
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryColor,
          side: const BorderSide(color: primaryColor),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryColor,
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.grey.shade800,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: primaryColor, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: error, width: 2),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: error, width: 2),
        ),
      ),
      textTheme: const TextTheme(
        displayLarge: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: textLight),
        displayMedium: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: textLight),
        displaySmall: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: textLight),
        headlineLarge: TextStyle(fontSize: 22, fontWeight: FontWeight.w600, color: textLight),
        headlineMedium: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: textLight),
        headlineSmall: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: textLight),
        titleLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: textLight),
        titleMedium: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: textLight),
        titleSmall: TextStyle(fontSize: 14, fontWeight: FontWeight.normal, color: textLight),
        bodyLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.normal, color: textLight),
        bodyMedium: TextStyle(fontSize: 14, fontWeight: FontWeight.normal, color: textLight),
        bodySmall: TextStyle(fontSize: 12, fontWeight: FontWeight.normal, color: Colors.grey.shade400),
      ),
    );
  }
}
