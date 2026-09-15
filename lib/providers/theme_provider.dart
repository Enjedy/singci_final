import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Provider de gestion du Thème Clair/Sombre pour SignCi
class ThemeProvider extends ChangeNotifier {
  static const String _themeKey = "isDarkMode";
  bool _isDarkMode = false;

  bool get isDarkMode => _isDarkMode;

  ThemeMode get themeMode => _isDarkMode ? ThemeMode.dark : ThemeMode.light;

  ThemeProvider() {
    _loadThemeFromPrefs();
  }

  void toggleTheme(bool value) async {
    _isDarkMode = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_themeKey, value);
  }

  Future<void> _loadThemeFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    _isDarkMode = prefs.getBool(_themeKey) ?? false;
    notifyListeners();
  }

  // Thème Clair Pro
  static const MaterialColor royalBlueSwatch = MaterialColor(0xFF0275D8, <int, Color>{
    50: Color(0xFFDBEAFB),
    100: Color(0xFFB7D5F7),
    200: Color(0xFF8EBFF2),
    300: Color(0xFF64A8EC),
    400: Color(0xFF4597E8),
    500: Color(0xFF0275D8),
    600: Color(0xFF0264B8),
    700: Color(0xFF015292),
    800: Color(0xFF013F6D),
    900: Color(0xFF002C4C),
  });

  static ThemeData get lightTheme {
    return ThemeData(
      brightness: Brightness.light,
      primarySwatch: royalBlueSwatch,
      scaffoldBackgroundColor: const Color(0xFFF6F3EC),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF154EA6),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      cardTheme: CardThemeData(
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        color: Colors.white,
      ),
      colorScheme: const ColorScheme.light(
        primary: Color(0xFF0275D8),
        secondary: Color(0xFF701460),
        surface: Colors.white,
        error: Colors.redAccent,
      ),
      useMaterial3: true,
    );
  }

  // Thème Sombre Pro
  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: const Color(0xFF121212),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF1F1F1F),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      cardTheme: CardThemeData(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        color: const Color(0xFF1E1E1E),
      ),
      colorScheme: const ColorScheme.dark(
        primary: Color(0xFF6EA8FF),
        secondary: Color(0xFF9D65FF),
        surface: Color(0xFF1E1E1E),
        error: Colors.redAccent,
      ),
      useMaterial3: true,
    );
  }
}
