import 'package:flutter/material.dart';

class AppTheme {
  final String name;
  final Color seedColor;
  final bool isDark;

  const AppTheme({required this.name, required this.seedColor, this.isDark = false});

  static const List<AppTheme> themes = [
    AppTheme(name: '天空蓝', seedColor: Color(0xFF4A90D9)),
    AppTheme(name: '薄荷绿', seedColor: Color(0xFF4CAF50)),
    AppTheme(name: '珊瑚橙', seedColor: Color(0xFFFF7043)),
    AppTheme(name: '薰衣紫', seedColor: Color(0xFF7C4DFF)),
    AppTheme(name: '玫瑰粉', seedColor: Color(0xFFE91E63)),
    AppTheme(name: '深海蓝', seedColor: Color(0xFF1565C0)),
    AppTheme(name: '墨夜黑', seedColor: Color(0xFF64B5F6), isDark: true),
    AppTheme(name: '暗夜紫', seedColor: Color(0xFFB388FF), isDark: true),
  ];

  static AppTheme byName(String name) =>
      themes.firstWhere((t) => t.name == name, orElse: () => themes.first);
}

ThemeData buildTheme(AppTheme appTheme, Brightness brightness) {
  final isDark = brightness == Brightness.dark || appTheme.isDark;
  final scheme = ColorScheme.fromSeed(seedColor: appTheme.seedColor, brightness: isDark ? Brightness.dark : Brightness.light);

  return ThemeData(
    colorScheme: scheme,
    useMaterial3: true,
    scaffoldBackgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFF5F7FA),
    appBarTheme: AppBarTheme(
      backgroundColor: isDark ? const Color(0xFF1E1E2E) : Colors.white,
      foregroundColor: isDark ? Colors.white : Colors.black87,
      surfaceTintColor: isDark ? const Color(0xFF1E1E2E) : Colors.white,
    ),
    cardTheme: CardTheme(
      color: isDark ? const Color(0xFF252536) : Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: appTheme.seedColor,
      foregroundColor: isDark ? Colors.black : Colors.white,
    ),
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: isDark ? const Color(0xFF1E1E2E) : null,
      selectedItemColor: appTheme.seedColor,
      unselectedItemColor: Colors.grey.shade400,
    ),
    dividerColor: isDark ? Colors.white12 : null,
  );
}
