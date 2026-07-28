import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../providers/usage_provider.dart';
import '../services/usage_stats_service.dart';

class UsageDetailScreen extends StatefulWidget {
  const UsageDetailScreen({super.key});

  @override
  State<UsageDetailScreen> createState() => _UsageDetailScreenState();
}

class _UsageDetailScreenState extends State<UsageDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  Future<void> _loadData() async {
    final provider = context.read<UsageProvider>();
    final service = UsageStatsService();

    final usages = await service.getTodayUsage();
    await provider.saveUsage(usages);
    await provider.loadTodayUsage();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('使用时长'),
        centerTitle: true,
        elevation: 0,
      ),
      body: Consumer<UsageProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.todaySummary == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.bar_chart, size: 64, color: Colors.grey.shade300),
                  const SizedBox(height: 16),
                  Text(
                    '暂无使用数据',
                    style: TextStyle(fontSize: 16, color: Colors.grey.shade500),
                  ),
                ],
              ),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildTotalCard(provider),
                const SizedBox(height: 20),
                _buildPieChart(provider),
                const SizedBox(height: 20),
                _buildAppList(provider),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildTotalCard(UsageProvider provider) {
    final summary = provider.todaySummary!;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.primary.withOpacity(0.8),
            Theme.of(context).colorScheme.secondary.withOpacity(0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(Icons.phone_android, size: 36, color: Colors.white.withOpacity(0.8)),
          const SizedBox(height: 12),
          Text(
            '今日屏幕使用时间',
            style: TextStyle(fontSize: 14, color: Colors.white.withOpacity(0.8)),
          ),
          const SizedBox(height: 8),
          Text(
            summary.formattedTotalDuration,
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '共 ${summary.apps.length} 个应用',
            style: TextStyle(fontSize: 13, color: Colors.white.withOpacity(0.7)),
          ),
        ],
      ),
    );
  }

  Widget _buildPieChart(UsageProvider provider) {
    final apps = provider.todaySummary!.apps.take(6).toList();
    if (apps.isEmpty) return const SizedBox.shrink();

    final colors = [
      Colors.blue.shade400,
      Colors.red.shade300,
      Colors.green.shade400,
      Colors.orange.shade400,
      Colors.purple.shade400,
      Colors.teal.shade400,
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '应用分布',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 200,
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: PieChart(
                    PieChartData(
                      sections: List.generate(apps.length, (i) {
                        final pct = apps[i].usageDuration /
                            provider.todaySummary!.totalDuration;
                        return PieChartSectionData(
                          value: pct,
                          title: '${(pct * 100).toStringAsFixed(0)}%',
                          color: colors[i % colors.length],
                          radius: 60,
                          titleStyle: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        );
                      }),
                      sectionsSpace: 2,
                      centerSpaceRadius: 30,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 2,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(apps.length, (i) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Row(
                          children: [
                            Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                color: colors[i % colors.length],
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                apps[i].appName,
                                style: const TextStyle(fontSize: 12),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppList(UsageProvider provider) {
    final apps = provider.todaySummary!.apps;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '应用排行',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          ...List.generate(apps.length, (i) {
            final app = apps[i];
            final pct = apps.isNotEmpty && provider.todaySummary != null
                ? app.usageDuration / provider.todaySummary!.totalDuration
                : 0.0;
            final isOver = provider.isOverLimit(app);

            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isOver ? Colors.red.shade50 : Colors.grey.shade50,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: isOver ? Colors.red : Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text(
                        '${i + 1}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: isOver ? Colors.white : Colors.grey.shade600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                app.appName,
                                style: const TextStyle(fontWeight: FontWeight.w500),
                              ),
                            ),
                            Text(
                              app.formattedDuration,
                              style: TextStyle(
                                fontSize: 13,
                                color: isOver ? Colors.red : Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: pct,
                            backgroundColor: Colors.grey.shade200,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              isOver ? Colors.red : Colors.blue,
                            ),
                            minHeight: 4,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (isOver)
                    const Padding(
                      padding: EdgeInsets.only(left: 8),
                      child: Icon(Icons.warning_amber, color: Colors.red, size: 20),
                    ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
