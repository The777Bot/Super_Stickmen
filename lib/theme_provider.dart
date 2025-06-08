import 'package:flutter/material.dart';

class ThemeProvider extends ChangeNotifier {
  bool _isDarkMode = false;

  bool get isDarkMode => _isDarkMode;

  void toggleTheme() {
    _isDarkMode = !_isDarkMode;
    notifyListeners();
  }

  ThemeData get theme => _isDarkMode ? _darkTheme : _lightTheme;

  static final _lightTheme = ThemeData(
    brightness: Brightness.light,
    primarySwatch: Colors.blue,
    scaffoldBackgroundColor: Colors.white,
    colorScheme: ColorScheme.light(
      primary: Colors.blue.shade900,
      secondary: Colors.purple.shade900,
      surface: Colors.white,
      background: Colors.white,
    ),
  );

  static final _darkTheme = ThemeData(
    brightness: Brightness.dark,
    primarySwatch: Colors.blue,
    scaffoldBackgroundColor: Colors.black,
    colorScheme: ColorScheme.dark(
      primary: Colors.blue.shade200,
      secondary: Colors.purple.shade200,
      surface: Colors.grey.shade900,
      background: Colors.black,
    ),
  );
}