import 'package:flutter/material.dart';
import 'package:musicapp/theme/app_theme.dart';

class ThemeProvider extends ChangeNotifier {
  ThemeProvider({bool initialDarkMode = true})
      : _isDarkMode = initialDarkMode;

  bool _isDarkMode;

  bool get isDarkMode => _isDarkMode;

  bool get isLightMode => !_isDarkMode;

  ThemeMode get themeMode =>
      _isDarkMode ? ThemeMode.dark : ThemeMode.light;

  ThemeData get darkTheme => AppTheme.darkTheme;

  ThemeData get lightTheme => AppTheme.lightTheme;

  void toggleTheme(bool value) {
    if (_isDarkMode == value) return;

    _isDarkMode = value;
    notifyListeners();
  }

  void setDarkMode() {
    toggleTheme(true);
  }

  void setLightMode() {
    toggleTheme(false);
  }
}
