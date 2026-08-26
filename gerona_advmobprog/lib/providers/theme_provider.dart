import 'package:flutter/material.dart';

class ThemeProvider with ChangeNotifier {
  bool _isDark = false;

  bool get isDark => _isDark;

  // LAB_ACT2 ENHANCEMENT 3:
  // Provides the light theme used by the application.
  ThemeData get lightTheme => ThemeData(
        brightness: Brightness.light,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      );

  // LAB_ACT2 ENHANCEMENT 3:
  // Provides the dark theme used by the application.
  ThemeData get darkTheme => ThemeData(
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      );

  // LAB_ACT2 ENHANCEMENT 3:
  // Switches between light mode and dark mode.
  void toggleTheme() {
    _isDark = !_isDark;
    notifyListeners();
  }
}
