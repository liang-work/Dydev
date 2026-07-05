import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/logger_service.dart';

class ThemeProvider extends ChangeNotifier {
  static const _tag = 'ThemeProvider';
  static const _key = 'theme_mode';

  ThemeMode _mode = ThemeMode.system;

  ThemeMode get mode => _mode;

  Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final stored = prefs.getString(_key) ?? 'system';
      _mode = _themeModeFromString(stored);
      LoggerService.d(_tag, 'Loaded theme: $stored');
    } catch (e) {
      LoggerService.e(_tag, 'Failed to load theme preference', e);
    }
    notifyListeners();
  }

  Future<void> setMode(ThemeMode mode) async {
    if (_mode == mode) return;
    _mode = mode;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_key, _themeModeToString(mode));
    } catch (e) {
      LoggerService.e(_tag, 'Failed to persist theme preference', e);
    }
  }

  static ThemeMode _themeModeFromString(String s) {
    switch (s) {
      case 'light': return ThemeMode.light;
      case 'dark': return ThemeMode.dark;
      default: return ThemeMode.system;
    }
  }

  static String _themeModeToString(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light: return 'light';
      case ThemeMode.dark: return 'dark';
      case ThemeMode.system: return 'system';
    }
  }
}
