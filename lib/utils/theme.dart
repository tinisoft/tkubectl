import 'package:flutter/material.dart';

class AppTheme {
  // Console color palette
  static const Color consoleBlack = Color(0xFF0D1117);
  static const Color consoleGray = Color(0xFF161B22);
  static const Color consoleLightGray = Color(0xFF21262D);
  static const Color consoleGreen = Color(0xFF3FB950);
  static const Color consoleBlue = Color(0xFF39C5CF); // Teal/Cyan instead of blue
  static const Color consoleTeal = Color(0xFF56D4DD); // Lighter teal
  static const Color consoleYellow = Color(0xFFD29922);
  static const Color consoleRed = Color(0xFFF85149);
  static const Color consoleWhite = Color(0xFFF0F6FC);
  static const Color consoleMutedWhite = Color(0xFFB1BAC4);
  static const Color consoleDarkGray = Color(0xFF30363D);

  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      primarySwatch: Colors.blue,
      scaffoldBackgroundColor: consoleBlack,

      // AppBar theme
      appBarTheme: const AppBarTheme(
        backgroundColor: consoleGray,
        foregroundColor: consoleWhite,
        elevation: 0,
        titleTextStyle: TextStyle(
          fontFamily: 'JetBrains Mono',
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: consoleWhite,
        ),
      ),

      // Text theme with monospace font
      textTheme: const TextTheme(
        displayLarge: TextStyle(fontFamily: 'JetBrains Mono', color: consoleWhite),
        displayMedium: TextStyle(fontFamily: 'JetBrains Mono', color: consoleWhite),
        displaySmall: TextStyle(fontFamily: 'JetBrains Mono', color: consoleWhite),
        headlineLarge: TextStyle(fontFamily: 'JetBrains Mono', color: consoleWhite, fontWeight: FontWeight.bold),
        headlineMedium: TextStyle(fontFamily: 'JetBrains Mono', color: consoleWhite, fontWeight: FontWeight.bold),
        headlineSmall: TextStyle(fontFamily: 'JetBrains Mono', color: consoleWhite, fontWeight: FontWeight.bold),
        titleLarge: TextStyle(fontFamily: 'JetBrains Mono', color: consoleWhite, fontWeight: FontWeight.w600),
        titleMedium: TextStyle(fontFamily: 'JetBrains Mono', color: consoleWhite, fontWeight: FontWeight.w500),
        titleSmall: TextStyle(fontFamily: 'JetBrains Mono', color: consoleWhite, fontWeight: FontWeight.w500),
        bodyLarge: TextStyle(fontFamily: 'JetBrains Mono', color: consoleWhite),
        bodyMedium: TextStyle(fontFamily: 'JetBrains Mono', color: consoleWhite),
        bodySmall: TextStyle(fontFamily: 'JetBrains Mono', color: consoleMutedWhite),
        labelLarge: TextStyle(fontFamily: 'JetBrains Mono', color: consoleWhite),
        labelMedium: TextStyle(fontFamily: 'JetBrains Mono', color: consoleWhite),
        labelSmall: TextStyle(fontFamily: 'JetBrains Mono', color: consoleMutedWhite),
      ),

      // Card theme
      cardTheme: const CardThemeData(
        color: consoleGray,
        elevation: 2,
        margin: EdgeInsets.all(8),
      ),

      // Input decoration theme
      inputDecorationTheme: const InputDecorationTheme(
        filled: true,
        fillColor: consoleLightGray,
        border: OutlineInputBorder(
          borderSide: BorderSide(color: consoleMutedWhite),
        ),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: consoleMutedWhite),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: consoleGreen, width: 2),
        ),
        labelStyle: TextStyle(color: consoleMutedWhite, fontFamily: 'JetBrains Mono'),
        hintStyle: TextStyle(color: consoleMutedWhite, fontFamily: 'JetBrains Mono'),
      ),

      // Button themes
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: consoleGreen,
          foregroundColor: consoleBlack,
          textStyle: const TextStyle(fontFamily: 'JetBrains Mono'),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: consoleGreen,
          side: const BorderSide(color: consoleGreen),
          textStyle: const TextStyle(fontFamily: 'JetBrains Mono'),
        ),
      ),

      // Dropdown theme
      dropdownMenuTheme: const DropdownMenuThemeData(
        textStyle: TextStyle(fontFamily: 'JetBrains Mono', color: consoleWhite),
      ),

      // Dialog theme
      dialogTheme: const DialogThemeData(
        backgroundColor: consoleGray,
        titleTextStyle: TextStyle(
          fontFamily: 'JetBrains Mono',
          color: consoleWhite,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
        contentTextStyle: TextStyle(
          fontFamily: 'JetBrains Mono',
          color: consoleWhite,
        ),
      ),

      // Data table theme
      dataTableTheme: const DataTableThemeData(
        headingTextStyle: TextStyle(
          fontFamily: 'JetBrains Mono',
          color: consoleWhite,
          fontWeight: FontWeight.bold,
        ),
        dataTextStyle: TextStyle(
          fontFamily: 'JetBrains Mono',
          color: consoleWhite,
        ),
      ),

      colorScheme: const ColorScheme.dark(
        primary: consoleGreen,
        secondary: consoleTeal,
        error: consoleRed,
        surface: consoleGray,
        onSurface: consoleWhite,
      ),
    );
  }

  // Status colors for different states
  static Color getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'running':
        return consoleGreen;
      case 'pending':
        return consoleYellow;
      case 'failed':
      case 'error':
        return consoleRed;
      case 'succeeded':
        return consoleTeal;
      default:
        return consoleMutedWhite;
    }
  }
}