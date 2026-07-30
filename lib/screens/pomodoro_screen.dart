import 'dart:async';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../database/app_database.dart';
import '../models/pomodoro_model.dart';

class PomodoroScreen extends StatefulWidget {
  const PomodoroScreen({super.key});
  @override
  State<PomodoroScreen> createState() => _PomodoroScreenState();
}

class _PomodoroScreenState extends State<PomodoroScreen> with SingleTickerProviderStateMixin {
  int _workMin = 25, _breakMin = 5, _remaining = 25 * 60;
  bool _isRunning = false, _isWork = true;
  int _todayCount = 0, _todayMin = 0;
  Map<String, int> _todayByCat = {};
  String _category = '学习';
  Timer? _timer;
  late AnimationController _anim;
  Map<String, int> _weekStats = {};
  final _cats = ['学习', '运动', '科研', '工作', '阅读', '冥想', '其他'];

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(vsync: this, duration: const Duration(seconds: 1500));
    _loadToday();
    _loadWeek();
  }

  Future<void> _loadToday() async {
    final records = await AppDatabase().getPomodoroToday();
    final byCat = await AppDatabase().getPomodoroTodayByCategory();
    setState(() { _todayCount = records.length; _todayMin = records.fold(0, (s, r) => s + r.duration); _todayByCat = byCat; });
  }

  Future<void> _loadWeek() async {
    final stats = await AppDatabase().getPomodoroWeekStats();
    setState(() => _weekStats = stats);
  }

  String get _timeText => '${(_remaining ~/ 60).toString().padLeft(2, '0')}:${(_remaining % 60).toString().padLeft(2, '0')}';

  void _toggle() {
    if (_isRunning) { _timer?.cancel(); _anim.stop(); setState(() => _isRunning = false); }
    else {
      setState(() => _isRunning = true);
      _anim.duration = Duration(seconds: _remaining); _anim.forward(from: 0);
      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        setState(() {
          if (_remaining > 0) { _remaining--; } else {
            _timer?.cancel(); _isRunning = false;
            if (_isWork) {
              AppDatabase().insertPomodoro(PomodoroRecord(duration: _workMin, category: _category, date: DateTime.now()));
              _loadToday(); _loadWeek();
              setState(() { _isWork = false; _remaining = _breakMin * 60; });
            } else { setState(() { _isWork = true; _remaining = _workMin * 60; }); }
            _anim.reset();
          }
        });
      });
    }
  }

  void _reset() { _timer?.cancel(); setState(() { _isRunning = false; _isWork = true; _remaining = _workMin * 60; }); _anim.reset(); }

  @override
  void dispose() { _timer?.cancel(); _anim.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final pct = _isWork ? (_workMin * 60 - _remaining) / (_workMin * 60) : (_breakMin * 60 - _remaining) / (_breakMin * 60);
    return Scaffold(
      appBar: AppBar(title: const Text('番茄专注'), centerTitle: true, elevation: 0),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // 计时圆环
            Stack(alignment: Alignment.center, children: [
              SizedBox(width: 220, height: 220, child: CircularProgressIndicator(value: pct, strokeWidth: 8, color: _isWork ? Colors.redAccent : Colors.green)),
              Column(mainAxisSize: MainAxisSize.min, children: [
                Text(_isWork ? '🍅' : '☕', style: const TextStyle(fontSize: 24)),
                Text(_timeText, style: const TextStyle(fontSize: 44, fontWeight: FontWeight.bold)),
              ]),
            ]),
            const SizedBox(height: 16),
            // 分类选择
            Wrap(spacing: 8, children: _cats.map((c) => ChoiceChip(
              label: Text(c), selected: _category == c, onSelected: (_) => setState(() => _category = c),
              selectedColor: Theme.of(context).colorScheme.primaryContainer,
            )).toList()),
            const SizedBox(height: 12),
            // 时间设置
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              _timeSetter('专注', _workMin, (v) => setState(() { _workMin = v; _remaining = v * 60; })),
              const SizedBox(width: 24),
              _timeSetter('休息', _breakMin, (v) => setState(() => _breakMin = v)),
            ]),
            const SizedBox(height: 16),
            // 按钮
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              ElevatedButton.icon(onPressed: _toggle, icon: Icon(_isRunning ? Icons.pause : Icons.play_arrow), label: Text(_isRunning ? '暂停' : '开始')),
              const SizedBox(width: 12), OutlinedButton.icon(onPressed: _reset, icon: const Icon(Icons.refresh), label: const Text('重置')),
            ]),
            const SizedBox(height: 16),
            Text('✅ 今日 $_todayCount 次 · $_todayMin 分钟', style: TextStyle(fontSize: 15, color: Colors.grey.shade600)),
            // 今日分类饼图（紧挨统计信息）
            if (_todayByCat.isNotEmpty) ...[
              const SizedBox(height: 12),
              const Text('今日分类', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
              SizedBox(height: 160, child: Row(children: [
                Expanded(flex: 2, child: PieChart(PieChartData(
                  sections: _todayByCat.entries.toList().asMap().entries.map((e) {
                    final total = _todayByCat.values.fold(0, (a, b) => a + b);
                    final pct = total > 0 ? e.value.value / total : 0.0;
                    final colors = [Colors.blue.shade400, Colors.green.shade400, Colors.orange.shade400, Colors.purple.shade400, Colors.teal.shade400, Colors.red.shade300, Colors.amber.shade400];
                    return PieChartSectionData(value: pct, title: pct > 0.1 ? '${(pct * 100).toStringAsFixed(0)}%' : '', color: colors[e.key % colors.length], radius: 40, titleStyle: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold));
                  }).toList(), sectionsSpace: 2, centerSpaceRadius: 15,
                ))),
                const SizedBox(width: 8),
                Expanded(flex: 2, child: Column(mainAxisAlignment: MainAxisAlignment.center, children: _todayByCat.entries.toList().asMap().entries.map((e) {
                  final colors = [Colors.blue.shade400, Colors.green.shade400, Colors.orange.shade400, Colors.purple.shade400, Colors.teal.shade400, Colors.red.shade300, Colors.amber.shade400];
                  return Padding(padding: const EdgeInsets.symmetric(vertical: 2), child: Row(children: [
                    Container(width: 8, height: 8, decoration: BoxDecoration(color: colors[e.key % colors.length], shape: BoxShape.circle)),
                    const SizedBox(width: 4),
                    Expanded(child: Text('${e.value.key} ${e.value.value}m', style: const TextStyle(fontSize: 11), overflow: TextOverflow.ellipsis)),
                  ]));
                }).toList())),
              ])),
            ],
            const SizedBox(height: 16),
            // 本周柱状图
            if (_weekStats.isNotEmpty) ...[
              const Text('本周累计', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              SizedBox(
                height: 180, width: double.infinity,
                child: BarChart(BarChartData(
                  alignment: BarChartAlignment.spaceAround, maxY: (_weekStats.values.reduce((a, b) => a > b ? a : b) * 1.3).toDouble(),
                  titlesData: FlTitlesData(
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 32, getTitlesWidget: (v, _) => Text('${v.toInt()}m', style: const TextStyle(fontSize: 10)))),
                    bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, getTitlesWidget: (v, _) => Padding(padding: const EdgeInsets.only(top: 4), child: Text(_weekStats.keys.toList()[v.toInt()], style: const TextStyle(fontSize: 10))))),
                  ),
                  barGroups: _weekStats.entries.toList().asMap().entries.map((e) => BarChartGroupData(x: e.key, barRods: [BarChartRodData(toY: e.value.value.toDouble(), color: Colors.redAccent, width: 16, borderRadius: const BorderRadius.vertical(top: Radius.circular(4)))])).toList(),
                )),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _timeSetter(String label, int val, ValueChanged<int> onChanged) {
    return Column(children: [
      Text('$label: $val 分钟', style: const TextStyle(fontSize: 13)),
      Slider(value: val.toDouble(), min: 5, max: 60, divisions: 11, onChanged: (v) => onChanged(v.toInt())),
    ]);
  }
}
