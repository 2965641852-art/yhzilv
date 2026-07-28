import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/todo_provider.dart';
import 'providers/usage_provider.dart';
import 'services/notification_service.dart';
import 'screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 初始化通知服务
  await NotificationService().initialize();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => TodoProvider()..loadTodos()),
        ChangeNotifierProvider(create: (_) => UsageProvider()),
      ],
      child: const YehengApp(),
    ),
  );
}

class YehengApp extends StatelessWidget {
  const YehengApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '叶恒的自律生活',
      debugShowCheckedModeBanner: false,

      // 简约清爽主题
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF4A90D9),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF5F7FA),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black87,
          surfaceTintColor: Colors.white,
        ),
        cardTheme: CardThemeData(
          color: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: Color(0xFF4A90D9),
          foregroundColor: Colors.white,
        ),
        fontFamily: null, // 使用系统默认字体
      ),

      // 暗色模式主题
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF4A90D9),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFF1A1A2E),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF16213E),
          surfaceTintColor: Color(0xFF16213E),
        ),
        cardTheme: CardThemeData(
          color: const Color(0xFF16213E),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),

      themeMode: ThemeMode.system,

      home: const HomeScreen(),
    );
  }
}
