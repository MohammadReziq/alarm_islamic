import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/app_theme.dart';

/// Controls app theme (Dark/Light mode)
class ThemeController extends GetxController {
  static const String _themeKey = 'app_theme';
  
  // Observable theme mode
  final Rx<ThemeMode> themeMode = ThemeMode.dark.obs;
  
  @override
  void onInit() {
    super.onInit();
    _loadTheme();
  }
  
  /// Load saved theme from SharedPreferences
  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final isDark = prefs.getBool(_themeKey) ?? true; // Default to dark
    themeMode.value = isDark ? ThemeMode.dark : ThemeMode.light;
  }
  
  /// Toggle between dark and light theme
  Future<void> toggleTheme() async {
    final isDark = themeMode.value == ThemeMode.dark;
    themeMode.value = isDark ? ThemeMode.light : ThemeMode.dark;
    
    // Save to preferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_themeKey, !isDark);
    
    // Update GetX theme
    Get.changeThemeMode(themeMode.value);
  }
  
  /// Get current ThemeData based on mode
  ThemeData get currentTheme {
    return themeMode.value == ThemeMode.dark 
      ? AppTheme.darkTheme 
      : AppTheme.lightTheme;
  }
  
  /// Check if dark mode is active
  bool get isDarkMode => themeMode.value == ThemeMode.dark;
}
