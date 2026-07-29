import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'providers/todo_provider.dart';
import 'providers/usage_provider.dart';
import 'providers/memo_provider.dart';
import 'providers/habit_provider.dart';
import 'services/notification_service.dart';
import 'database/app_database.dart';
import 'app_theme.dart';
import 'screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationService().initialize();

  final savedTheme = await AppDatabase().getSetting('theme') ?? '天空蓝';
  final useDark = await AppDatabase().getSetting('theme_dark') ?? 'system';

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => TodoProvider()..loadTodos()),
        ChangeNotifierProvider(create: (_) => UsageProvider()),
        ChangeNotifierProvider(create: (_) => MemoProvider()..loadMemos()),
        ChangeNotifierProvider(create: (_) => HabitProvider()..loadHabits()),
      ],
      child: YehengApp(initialTheme: savedTheme, initialDark: useDark),
    ),
  );
}

class YehengApp extends StatefulWidget {
  final String initialTheme;
  final String initialDark;
  const YehengApp({super.key, required this.initialTheme, required this.initialDark});

  static void setTheme(BuildContext context, String name) {
    final state = context.findAncestorStateOfType<_YehengAppState>();
    state?.setTheme(name);
  }

  static void setDarkMode(BuildContext context, String mode) {
    final state = context.findAncestorStateOfType<_YehengAppState>();
    state?.setDarkMode(mode);
  }

  @override
  State<YehengApp> createState() => _YehengAppState();
}

class _YehengAppState extends State<YehengApp> {
  late String _themeName;
  late String _darkMode;

  @override
  void initState() {
    super.initState();
    _themeName = widget.initialTheme;
    _darkMode = widget.initialDark;
  }

  void setTheme(String name) {
    setState(() => _themeName = name);
    AppDatabase().setSetting('theme', name);
  }

  void setDarkMode(String mode) {
    setState(() => _darkMode = mode);
    AppDatabase().setSetting('theme_dark', mode);
  }

  @override
  Widget build(BuildContext context) {
    final appTheme = AppTheme.byName(_themeName);

    return MaterialApp(
      title: '叶恒的自律生活',
      debugShowCheckedModeBanner: false,
      locale: const Locale('zh', 'CN'),
      supportedLocales: const [Locale('zh', 'CN')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],

      theme: buildTheme(appTheme, Brightness.light),
      darkTheme: buildTheme(appTheme, Brightness.dark),
      themeMode: _darkMode == 'dark'
          ? ThemeMode.dark
          : _darkMode == 'light'
              ? ThemeMode.light
              : ThemeMode.system,

      home: const HomeScreen(),
    );
  }
}
