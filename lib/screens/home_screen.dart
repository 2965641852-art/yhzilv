import 'package:flutter/material.dart';
import 'todo_list_screen.dart';
import 'stats_screen.dart';
import 'memo_list_screen.dart';
import 'profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _pages = const [
    TodoListScreen(),
    StatsScreen(),
    MemoListScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _pages),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: Colors.grey.shade200, width: 0.5)),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (i) => setState(() => _currentIndex = i),
          selectedItemColor: Theme.of(context).colorScheme.primary,
          unselectedItemColor: Colors.grey.shade400,
          type: BottomNavigationBarType.fixed,
          elevation: 0,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.checklist_rounded), label: '待办'),
            BottomNavigationBarItem(icon: Icon(Icons.bar_chart_rounded), label: '统计'),
            BottomNavigationBarItem(icon: Icon(Icons.note_alt_outlined), label: '备忘录'),
            BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: '我的'),
          ],
        ),
      ),
    );
  }
}
