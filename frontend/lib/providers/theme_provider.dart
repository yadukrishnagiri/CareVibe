import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider extends ChangeNotifier {
  static const _key = 'themeMode'; // 'light' | 'dark'
  ThemeMode _mode = ThemeMode.dark; // default dark as requested

  ThemeMode get mode => _mode;
  bool get isDark => _mode == ThemeMode.dark;

  ThemeProvider() {
    // ignore: discarded_futures
    _load();
  }

  void toggle(bool enableDark) async {
    _mode = enableDark ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, enableDark ? 'dark' : 'light');
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final v = prefs.getString(_key);
    if (v == 'dark') {
      _mode = ThemeMode.dark;
    } else if (v == 'light') {
      _mode = ThemeMode.light;
    }
    notifyListeners();
  }
}


