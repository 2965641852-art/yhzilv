import 'package:flutter/material.dart';
import '../models/anniversary_model.dart';
import '../database/app_database.dart';

class AnniversaryScreen extends StatefulWidget {
  const AnniversaryScreen({super.key});
  @override
  State<AnniversaryScreen> createState() => _AnniversaryScreenState();
}

class _AnniversaryScreenState extends State<AnniversaryScreen> {
  List<AnniversaryModel> _items = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final items = await AppDatabase().getAllAnniversaries();
    setState(() => _items = items);
  }

  Future<void> _add() async {
    final titleCtrl = TextEditingController();
    DateTime date = DateTime.now();
    bool isCountdown = true;
    bool remindAnnually = false;
    String icon = '📅';

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlgState) => AlertDialog(
          title: const Text('添加纪念日'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: '名称', hintText: '例：恋爱纪念日'), autofocus: true),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 8,
                  children: ['💕', '🎂', '💍', '🎓', '🏠', '🎉', '💼', '📅'].map((e) => GestureDetector(
                    onTap: () => setDlgState(() => icon = e),
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        border: Border.all(color: icon == e ? Theme.of(context).colorScheme.primary : Colors.transparent, width: 2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(e, style: const TextStyle(fontSize: 24)),
                    ),
                  )).toList(),
                ),
                const SizedBox(height: 8),
                ListTile(
                  title: Text('${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}'),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () async {
                    final d = await showDatePicker(context: ctx, initialDate: date, firstDate: DateTime(1970), lastDate: DateTime(2100));
                    if (d != null) setDlgState(() => date = d);
                  },
                ),
                SwitchListTile(title: const Text('倒计时'), value: isCountdown, onChanged: (v) => setDlgState(() => isCountdown = v)),
                SwitchListTile(title: const Text('每年提醒'), subtitle: const Text('生日等每年重复'), value: remindAnnually, onChanged: (v) => setDlgState(() => remindAnnually = v)),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
            TextButton(onPressed: () async {
              if (titleCtrl.text.trim().isNotEmpty) {
                await AppDatabase().insertAnniversary(AnniversaryModel(
                  title: titleCtrl.text.trim(), date: date, isCountdown: isCountdown,
                  remindAnnually: remindAnnually, icon: icon,
                ));
                Navigator.pop(ctx);
                _load();
              }
            }, child: const Text('添加')),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('纪念日'), centerTitle: true, elevation: 0),
      body: _items.isEmpty
          ? Center(child: Text('还没有纪念日', style: TextStyle(color: Colors.grey.shade400, fontSize: 16)))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _items.length,
              itemBuilder: (ctx, i) {
                final a = _items[i];
                final diff = a.daysDiff;
                return Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      children: [
                        Text(a.icon, style: const TextStyle(fontSize: 36)),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(child: Text(a.title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16))),
                                  if (a.remindAnnually) const Icon(Icons.repeat, size: 14, color: Colors.orange),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(a.displayText, style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
                              if (a.yearsPassed > 0 && a.daysToNext > 0 && a.daysToNext < 365)
                                Padding(
                                  padding: const EdgeInsets.only(top: 2),
                                  child: Text('🗓 距${a.yearsPassed + 1}周年还有 ${a.daysToNext} 天',
                                    style: TextStyle(fontSize: 12, color: Colors.orange.shade700)),
                                ),
                            ],
                          ),
                        ),
                        Column(
                          children: [
                            Text('${diff.abs()}', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold,
                              color: diff == 0 ? Colors.orange : diff < 0 ? Colors.blue : Colors.green)),
                            Text(diff == 0 ? '今天!' : '天', style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(onPressed: _add, child: const Icon(Icons.add)),
    );
  }
}
