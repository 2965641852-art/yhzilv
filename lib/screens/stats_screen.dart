import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../database/app_database.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});
  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  Map<String, int> _pomodoroStats = {};
  int _todayPomodoro = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final db = AppDatabase();
    final stats = await db.getPomodoroWeekStats();
    final today = await db.getPomodoroToday();
    setState(() {
      _pomodoroStats = stats;
      _todayPomodoro = today.fold(0, (s, r) => s + r.duration);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('统计'), centerTitle: true, elevation: 0),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 今日番茄
            Container(
              width: double.infinity, padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [Colors.redAccent.withOpacity(0.8), Colors.redAccent]),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(children: [
                const Text('🍅 今日番茄', style: TextStyle(fontSize: 14, color: Colors.white70)),
                Text('$_todayPomodoro 分钟', style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white)),
              ]),
            ),
            const SizedBox(height: 20),
            const Text('本周番茄统计', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            if (_pomodoroStats.isNotEmpty)
              SizedBox(height: 200, child: BarChart(BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: (_pomodoroStats.values.fold(0, (a, b) => a > b ? a : b) * 1.3).toDouble(),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 32, getTitlesWidget: (v, _) => Text('${v.toInt()}m', style: const TextStyle(fontSize: 10)))),
                  bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, getTitlesWidget: (v, _) => Padding(padding: const EdgeInsets.only(top: 4), child: Text(_pomodoroStats.keys.toList()[v.toInt()], style: const TextStyle(fontSize: 10))))),
                ),
                barGroups: _pomodoroStats.entries.toList().asMap().entries.map((e) => BarChartGroupData(x: e.key, barRods: [BarChartRodData(toY: e.value.value.toDouble(), color: Colors.redAccent, width: 18, borderRadius: const BorderRadius.vertical(top: Radius.circular(4)))])).toList(),
              ))),
          ],
        ),
      ),
    );
  }
}
