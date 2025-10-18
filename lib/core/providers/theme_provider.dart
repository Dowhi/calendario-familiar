import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final themeProvider = StateNotifierProvider<ThemeNotifier, bool>((ref) => ThemeNotifier());

class ThemeNotifier extends StateNotifier<bool> {
  ThemeNotifier() : super(false) {
    _loadTheme();
  }

  static const String _themeKey = 'isDarkMode';

  Future<void> _loadTheme() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final isDarkMode = prefs.getBool(_themeKey) ?? false;
      state = isDarkMode;
    } catch (e) {
      print('Error loading theme: $e');
      state = false; // Default to light theme
    }
  }

  Future<void> toggleTheme() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final newTheme = !state;
      await prefs.setBool(_themeKey, newTheme);
      state = newTheme;
    } catch (e) {
      print('Error saving theme: $e');
    }
  }

  Future<void> setTheme(bool isDarkMode) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_themeKey, isDarkMode);
      state = isDarkMode;
    } catch (e) {
      print('Error setting theme: $e');
    }
  }
}



