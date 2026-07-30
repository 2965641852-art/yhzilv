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
                            onTap: () => _checkIn(context, h.id!, h),
                            onLongPress: () => _editHabit(context, h),
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

  void _checkIn(BuildContext context, int habitId, HabitModel habit) async {
    final provider = context.read<HabitProvider>();
    final current = await provider.getTodayCount(habitId);
    int count = current; // 放在 builder 外面，setSt 重建不会重置

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSt) {
          return AlertDialog(
            title: Text('${habit.icon} ${habit.name}'),
            content: Column(mainAxisSize: MainAxisSize.min, children: [
              Text('目标: ${habit.targetCount} ${habit.unit}', style: TextStyle(color: Colors.grey.shade600)),
              const SizedBox(height: 16),
              SizedBox(
                height: 120,
                child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  IconButton(
                    onPressed: count > 0 ? () { count--; setSt(() {}); } : null,
                    icon: const Icon(Icons.remove_circle_outline, size: 36),
                  ),
                  const SizedBox(width: 12),
                  SizedBox(
                    width: 60, height: 120,
                    child: ListWheelScrollView(
                      itemExtent: 40, diameterRatio: 2,
                      onSelectedItemChanged: (v) { count = v; setSt(() {}); },
                      children: List.generate(habit.targetCount * 5 + 1, (i) => Center(child: Text('$i', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)))),
                    ),
                  ),
                  const SizedBox(width: 12),
                  IconButton(
                    onPressed: () { count++; setSt(() {}); },
                    icon: const Icon(Icons.add_circle_outline, size: 36),
                  ),
                ]),
              ),
            ]),
            actions: [
              TextButton(onPressed: () { count = 0; setSt(() {}); }, child: const Text('归零')),
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
              TextButton(onPressed: () {
                provider.toggleHabitComplete(habitId, count: count);
                Navigator.pop(ctx);
              }, child: const Text('确定')),
            ],
          );
        },
      ),
    );
  }

  void _editHabit(BuildContext context, HabitModel h) {
    final nameCtrl = TextEditingController(text: h.name);
    final countCtrl = TextEditingController(text: '${h.targetCount}');
    String unit = h.unit;
    String icon = h.icon;
    final emojis = ['✅','📚','🏃','💪','🧘','🎯','📝','💧','🍎','🌿','🎵','✍️','💻','🔬','📖','🛏','🚿','💊','🧠','🎨'];
    final units = ['次','分钟','个','页','杯','公里','组','小时'];

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSt) => AlertDialog(
          title: const Text('编辑习惯'),
          content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: '习惯名')),
            const SizedBox(height: 10),
            Wrap(spacing: 6, children: emojis.map((e) => GestureDetector(
              onTap: () => setSt(() => icon = e),
              child: Container(padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(border: Border.all(color: icon == e ? Theme.of(ctx).colorScheme.primary : Colors.transparent, width: 2), borderRadius: BorderRadius.circular(8)),
                child: Text(e, style: const TextStyle(fontSize: 24))),
            )).toList()),
            const SizedBox(height: 10),
            Row(children: [
              Expanded(child: TextField(controller: countCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: '目标'))),
              const SizedBox(width: 10),
              SizedBox(width: 100, child: DropdownButtonFormField<String>(value: unit, items: units.map((u) => DropdownMenuItem(value: u, child: Text(u))).toList(), onChanged: (v) => setSt(() => unit = v!), decoration: const InputDecoration(labelText: '单位'))),
            ]),
          ])),
          actions: [
            TextButton(onPressed: () { Navigator.pop(ctx); _showStats(context, h); }, child: const Text('统计')),
            TextButton(onPressed: () { Navigator.pop(ctx); }, child: const Text('取消')),
            TextButton(onPressed: () {
              final n = nameCtrl.text.trim(); if (n.isEmpty) return;
              context.read<HabitProvider>().updateHabit(h.copyWith(name: n, targetCount: int.tryParse(countCtrl.text) ?? 1, unit: unit, icon: icon));
              Navigator.pop(ctx);
            }, child: const Text('保存')),
          ],
        ),
      ),
    );
  }

  void _addHabit(BuildContext context) {
    final nameCtrl = TextEditingController();
    final countCtrl = TextEditingController(text: '1');
    String unit = '次';
    String icon = '✅';
    final emojis = ['✅', '📚', '🏃', '💪', '🧘', '🎯', '📝', '💧', '🍎', '🌿', '🎵', '✍️', '💻', '🔬', '📖', '🛏', '🚿', '💊', '🧠', '🎨'];
    final units = ['次', '分钟', '个', '页', '杯', '公里', '组', '小时'];

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSt) => AlertDialog(
          title: const Text('新建习惯'),
          content: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: '习惯名'), autofocus: true),
              const SizedBox(height: 10),
              Wrap(spacing: 6, children: emojis.map((e) => GestureDetector(
                onTap: () => setSt(() => icon = e),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(border: Border.all(color: icon == e ? Theme.of(ctx).colorScheme.primary : Colors.transparent, width: 2), borderRadius: BorderRadius.circular(8)),
                  child: Text(e, style: const TextStyle(fontSize: 24)),
                ),
              )).toList()),
              const SizedBox(height: 10),
              Row(children: [
                Expanded(child: TextField(controller: countCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: '目标'))),
                const SizedBox(width: 10),
                SizedBox(
                  width: 100,
                  child: DropdownButtonFormField<String>(
                    value: unit, items: units.map((u) => DropdownMenuItem(value: u, child: Text(u))).toList(),
                    onChanged: (v) => setSt(() => unit = v!),
                    decoration: const InputDecoration(labelText: '单位'),
                  ),
                ),
              ]),
            ]),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
            TextButton(onPressed: () {
              final name = nameCtrl.text.trim(); if (name.isEmpty) return;
              context.read<HabitProvider>().addHabit(HabitModel(name: name, targetCount: int.tryParse(countCtrl.text) ?? 1, unit: unit, icon: icon));
              Navigator.pop(ctx);
            }, child: const Text('添加')),
          ],
        ),
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
