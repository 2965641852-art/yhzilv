import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/habit_model.dart';
import '../providers/habit_provider.dart';
import '../widgets/habit_card.dart';

class HabitsScreen extends StatefulWidget {
  const HabitsScreen({super.key});
  @override
  State<HabitsScreen> createState() => _HabitsScreenState();
}

class _HabitsScreenState extends State<HabitsScreen> {
  @override
  Widget build(BuildContext context) {
    return Consumer<HabitProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator()));

        return Scaffold(
          appBar: AppBar(
            title: const Text('习惯打卡'),
            centerTitle: true,
            elevation: 0,
          ),
          body: provider.habits.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.repeat_rounded, size: 72, color: Colors.grey.shade300),
                      const SizedBox(height: 16),
                      Text('还没有习惯', style: TextStyle(fontSize: 16, color: Colors.grey.shade500)),
                      Text('点击 + 添加第一个习惯', style: TextStyle(fontSize: 13, color: Colors.grey.shade400)),
                    ],
                  ),
                )
              : Padding(
                  padding: const EdgeInsets.all(12),
                  child: FutureBuilder<List<Map<String, int>>>(
                    future: Future.wait(provider.habits.map((h) => provider.getTodayCount(h.id!).then((c) => {h.id.toString(): c}))),
                    builder: (context, snapshot) {
                      return GridView.builder(
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          mainAxisSpacing: 10,
                          crossAxisSpacing: 10,
                          childAspectRatio: 0.85,
                        ),
                        itemCount: provider.habits.length,
                        itemBuilder: (ctx, i) {
                          final h = provider.habits[i];
                          final count = snapshot.hasData && i < snapshot.data!.length
                              ? snapshot.data![i][h.id.toString()] ?? 0
                              : 0;
                          return HabitCard(
                            habit: h,
                            todayCount: count,
                            onTap: () => provider.toggleComplete(h.id!),
                            onLongPress: () => _showStats(context, h),
                          );
                        },
                      );
                    },
                  ),
                ),
          floatingActionButton: FloatingActionButton(
            onPressed: () => _addHabit(context),
            child: const Icon(Icons.add),
          ),
        );
      },
    );
  }

  void _addHabit(BuildContext context) {
    final nameCtrl = TextEditingController();
    final countCtrl = TextEditingController(text: '1');
    final unitCtrl = TextEditingController(text: '次');
    final iconCtrl = TextEditingController(text: '✅');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('新建习惯'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: '习惯名'), autofocus: true),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(child: TextField(controller: countCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: '目标'))),
                  const SizedBox(width: 8),
                  Expanded(child: TextField(controller: unitCtrl, decoration: const InputDecoration(labelText: '单位'))),
                ],
              ),
              const SizedBox(height: 8),
              TextField(controller: iconCtrl, decoration: const InputDecoration(labelText: '图标(emoji)')),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
          TextButton(
            onPressed: () {
              final name = nameCtrl.text.trim();
              if (name.isEmpty) return;
              context.read<HabitProvider>().addHabit(HabitModel(
                name: name,
                targetCount: int.tryParse(countCtrl.text) ?? 1,
                unit: unitCtrl.text.isNotEmpty ? unitCtrl.text : '次',
                icon: iconCtrl.text.isNotEmpty ? iconCtrl.text : '✅',
              ));
              Navigator.pop(ctx);
            },
            child: const Text('添加'),
          ),
        ],
      ),
    );
  }

  void _showStats(BuildContext context, HabitModel habit) {
    final now = DateTime.now();
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) {
        final habitProvider = context.read<HabitProvider>();
        return SizedBox(
          height: 320,
          child: FutureBuilder<Map<String, int>>(
            future: habitProvider.getMonthStats(habit.id!, now.year, now.month),
            builder: (context, snap) {
              final stats = snap.data ?? {};
              final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
              return Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Text('${habit.name} · ${now.year}年${now.month}月', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 30,
                      child: Row(
                        children: ['一', '二', '三', '四', '五', '六', '日'].map((d) => Expanded(child: Center(child: Text(d, style: TextStyle(fontSize: 11, color: Colors.grey.shade500))))).toList(),
                      ),
                    ),
                    Wrap(
                      spacing: 4,
                      runSpacing: 4,
                      children: List.generate(daysInMonth, (i) {
                        final day = i + 1;
                        final count = stats['$day'] ?? 0;
                        final target = habit.targetCount;
                        final opacity = count >= target ? 1.0 : count > 0 ? 0.5 : 0.1;
                        return Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(opacity),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Center(child: Text('$day', style: const TextStyle(fontSize: 9))),
                        );
                      }),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }
}
