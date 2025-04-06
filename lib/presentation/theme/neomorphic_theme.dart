import 'package:flutter/material.dart';

class NeomorphicTheme {
  // Light theme colors
  static const Color lightPrimaryColor = Color(0xFF6C63FF);
  static const Color lightBackgroundColor = Color(0xFFF0F2F5);
  static const Color lightShadowColor = Color(0xFFD1D9E6);
  static const Color lightColor = Colors.white;
  static const Color lightTextColor = Color(0xFF2D3436);
  static const Color lightSecondaryTextColor = Color(0xFF636E72);

  // Dark theme colors
  static const Color darkPrimaryColor = Color(0xFF8B85FF);
  static const Color darkBackgroundColor = Color(0xFF1E1E2E);
  static const Color darkShadowColor = Color(0xFF0F0F1A);
  static const Color darkLightColor = Color(0xFF2A2A3A);
  static const Color darkTextColor = Color(0xFFE0E0E0);
  static const Color darkSecondaryTextColor = Color(0xFFB0B0B0);

  static BoxDecoration neomorphicDecoration({
    double borderRadius = 15,
    double blurRadius = 20,
    double offset = 10,
    bool isDark = false,
  }) {
    final backgroundColor = isDark ? darkBackgroundColor : lightBackgroundColor;
    final shadowColor = isDark ? darkShadowColor : lightShadowColor;
    final lightColor = isDark ? darkLightColor : NeomorphicTheme.lightColor;

    return BoxDecoration(
      color: backgroundColor,
      borderRadius: BorderRadius.circular(borderRadius),
      boxShadow: [
        BoxShadow(
          color: shadowColor.withOpacity(0.8),
          offset: Offset(offset, offset),
          blurRadius: blurRadius,
          spreadRadius: 1,
        ),
        BoxShadow(
          color: lightColor.withOpacity(0.9),
          offset: Offset(-offset, -offset),
          blurRadius: blurRadius,
          spreadRadius: 1,
        ),
      ],
    );
  }

  static BoxDecoration neomorphicButtonDecoration({
    double borderRadius = 15,
    double blurRadius = 20,
    double offset = 10,
    bool isDark = false,
  }) {
    final primaryColor = isDark ? darkPrimaryColor : lightPrimaryColor;
    final shadowColor = isDark ? darkShadowColor : lightShadowColor;
    final lightColor = isDark ? darkLightColor : NeomorphicTheme.lightColor;

    return BoxDecoration(
      color: primaryColor,
      borderRadius: BorderRadius.circular(borderRadius),
      boxShadow: [
        BoxShadow(
          color: shadowColor.withOpacity(0.8),
          offset: Offset(offset, offset),
          blurRadius: blurRadius,
          spreadRadius: 1,
        ),
        BoxShadow(
          color: lightColor.withOpacity(0.9),
          offset: Offset(-offset, -offset),
          blurRadius: blurRadius,
          spreadRadius: 1,
        ),
      ],
    );
  }

  static ThemeData get lightTheme => _createTheme(isDark: false);
  static ThemeData get darkTheme => _createTheme(isDark: true);

  static ThemeData _createTheme({required bool isDark}) {
    final primaryColor = isDark ? darkPrimaryColor : lightPrimaryColor;
    final backgroundColor = isDark ? darkBackgroundColor : lightBackgroundColor;
    final textColor = isDark ? darkTextColor : lightTextColor;
    final secondaryTextColor =
        isDark ? darkSecondaryTextColor : lightSecondaryTextColor;
    final lightColor = isDark ? darkLightColor : NeomorphicTheme.lightColor;

    return ThemeData(
      brightness: isDark ? Brightness.dark : Brightness.light,
      primaryColor: primaryColor,
      scaffoldBackgroundColor: backgroundColor,
      colorScheme: ColorScheme(
        brightness: isDark ? Brightness.dark : Brightness.light,
        primary: primaryColor,
        secondary: primaryColor,
        background: backgroundColor,
        surface: backgroundColor,
        onPrimary: lightColor,
        onSecondary: lightColor,
        onBackground: textColor,
        onSurface: textColor,
        error: Colors.red,
        onError: lightColor,
      ),
      textTheme: TextTheme(
        headlineLarge: TextStyle(
          color: textColor,
          fontSize: 28,
          fontWeight: FontWeight.bold,
        ),
        headlineMedium: TextStyle(
          color: textColor,
          fontSize: 24,
          fontWeight: FontWeight.bold,
        ),
        headlineSmall: TextStyle(
          color: textColor,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
        bodyLarge: TextStyle(
          color: textColor,
          fontSize: 16,
        ),
        bodyMedium: TextStyle(
          color: secondaryTextColor,
          fontSize: 14,
        ),
        bodySmall: TextStyle(
          color: secondaryTextColor,
          fontSize: 12,
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: backgroundColor,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: textColor,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
        iconTheme: IconThemeData(
          color: textColor,
        ),
      ),
      cardTheme: CardTheme(
        color: backgroundColor,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: backgroundColor,
        selectedItemColor: primaryColor,
        unselectedItemColor: secondaryTextColor,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      dialogTheme: DialogTheme(
        backgroundColor: backgroundColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: backgroundColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: primaryColor),
        ),
        labelStyle: TextStyle(color: secondaryTextColor),
        hintStyle: TextStyle(color: secondaryTextColor),
      ),
    );
  }
}
