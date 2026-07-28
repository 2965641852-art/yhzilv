import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../providers/todo_provider.dart';
import '../providers/usage_provider.dart';
import '../services/usage_stats_service.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  Map<String, int> _weeklyTodos = {};
  Map<String, int> _weeklyUsage = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
  }

  Future<void> _loadData() async {
    final todoProvider = context.read<TodoProvider>();
    final usageService = UsageStatsService();

    final todos = await todoProvider.getWeeklyStats();
    final usage = await usageService.getWeeklyUsageMap();

    setState(() {
      _weeklyTodos = todos;
      _weeklyUsage = usage;
    });
  }

  @override
  Widget build(BuildContext context) {
    final todoProvider = context.watch<TodoProvider>();
    final today = todoProvider.completedToday;
    final pending = todoProvider.pendingCount;
    final total = todoProvider.todos.length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('统计看板'),
        centerTitle: true,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 得分卡片
            _buildScoreCard(today, pending, total),
            const SizedBox(height: 16),

            // 待办周趋势
            _buildSectionTitle('本周完成趋势'),
            const SizedBox(height: 8),
            _buildChartCard(
              child: SizedBox(
                height: 200,
                child: _weeklyTodos.isNotEmpty
                    ? _buildBarChart(
                        _weeklyTodos,
                        Theme.of(context).colorScheme.primary,
                      )
                    : const Center(child: Text('暂无数据')),
              ),
            ),
            const SizedBox(height: 16),

            // 使用时长周趋势
            _buildSectionTitle('本周使用时长'),
            const SizedBox(height: 8),
            _buildChartCard(
              child: SizedBox(
                height: 200,
                child: _weeklyUsage.isNotEmpty
                    ? _buildBarChart(
                        _weeklyUsage,
                        Colors.orange.shade400,
                      )
                    : const Center(child: Text('暂无数据')),
              ),
            ),
            const SizedBox(height: 16),

            // 效率评分
            _buildSectionTitle('专注效率'),
            const SizedBox(height: 8),
            _buildChartCard(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    _buildEfficiencyRow('待办完成率', total > 0 ? today / total : 0),
                    const SizedBox(height: 12),
                    _buildEfficiencyRow('本周日均完成', _weeklyTodos.isNotEmpty
                        ? _weeklyTodos.values.fold<int>(0, (a, b) => a + b) / 7
                        : 0),
                    const SizedBox(height: 12),
                    _buildEfficiencyRow('效率评分',
                        _calculateEfficiencyScore(today, pending, total)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  Widget _buildScoreCard(int today, int pending, int total) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.deepPurple.shade400,
            Colors.blue.shade400,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.deepPurple.shade200,
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '今日专注',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.8),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '$today 项',
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$pending 待完成',
                style: TextStyle(fontSize: 13, color: Colors.white.withOpacity(0.8)),
              ),
              const SizedBox(height: 4),
              Text(
                '共 $total 项',
                style: TextStyle(fontSize: 13, color: Colors.white.withOpacity(0.6)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Widget _buildChartCard({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: child,
    );
  }

  Widget _buildBarChart(Map<String, int> data, Color color) {
    final entries = data.entries.toList();
    if (entries.isEmpty) return const SizedBox.shrink();

    final maxVal = entries.map((e) => e.value).reduce(
        (a, b) => a > b ? a : b);

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: (maxVal * 1.2).toDouble().ceilToDouble(),
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              return BarTooltipItem(
                '${rod.toY.toInt()}',
                TextStyle(color: color, fontWeight: FontWeight.bold),
              );
            },
          ),
        ),
        titlesData: FlTitlesData(
          show: true,
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: true, reservedSize: 30),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                if (value.toInt() < entries.length) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      entries[value.toInt()].key,
                      style: const TextStyle(fontSize: 11),
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ),
        ),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: maxVal > 0 ? (maxVal / 4).ceilToDouble() : 1,
        ),
        borderData: FlBorderData(show: false),
        barGroups: List.generate(entries.length, (i) {
          return BarChartGroupData(
            x: i,
            barRods: [
              BarChartRodData(
                toY: entries[i].value.toDouble(),
                color: color,
                width: 20,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(6),
                ),
              ),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildEfficiencyRow(String label, double value) {
    return Row(
      children: [
        Expanded(
          flex: 3,
          child: Text(label, style: const TextStyle(fontSize: 14)),
        ),
        Expanded(
          flex: 5,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: value.clamp(0.0, 1.0),
              minHeight: 14,
              backgroundColor: Colors.grey.shade200,
              valueColor: AlwaysStoppedAnimation<Color>(
                value > 0.7 ? Colors.green : value > 0.4 ? Colors.orange : Colors.red,
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 40,
          child: Text(
            '${(value * 100).toStringAsFixed(0)}%',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }

  double _calculateEfficiencyScore(int today, int pending, int total) {
    if (total == 0) return 0;
    final completeRate = today / (total > 0 ? total : 1);
    final score = (completeRate * 0.6 + 0.4).clamp(0.0, 1.0);
    return score;
  }
}
