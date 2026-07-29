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
    final db = AppDatabase();
    final items = await db.getAllAnniversaries();
    setState(() => _items = items);
  }

  Future<void> _add() async {
    final titleCtrl = TextEditingController();
    DateTime date = DateTime.now();
    bool isCountdown = true;
    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlgState) => AlertDialog(
          title: const Text('添加纪念日'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: '名称'), autofocus: true),
              const SizedBox(height: 12),
              ListTile(
                title: Text('${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}'),
                trailing: const Icon(Icons.calendar_today),
                onTap: () async {
                  final d = await showDatePicker(context: ctx, initialDate: date, firstDate: DateTime(2000), lastDate: DateTime(2100));
                  if (d != null) setDlgState(() => date = d);
                },
              ),
              SwitchListTile(title: const Text('倒计时'), value: isCountdown, onChanged: (v) => setDlgState(() => isCountdown = v)),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
            TextButton(onPressed: () {
              if (titleCtrl.text.trim().isNotEmpty) {
                AppDatabase().insertAnniversary(AnniversaryModel(title: titleCtrl.text.trim(), date: date, isCountdown: isCountdown));
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
                  child: ListTile(
                    leading: Text(a.icon, style: const TextStyle(fontSize: 32)),
                    title: Text(a.title, style: const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Text(a.displayText),
                    trailing: Text(
                      diff == 0 ? '🎉 今天！' : '${diff.abs()}天',
                      style: TextStyle(color: diff <= 0 ? Colors.orange : Colors.blue, fontWeight: FontWeight.bold),
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(onPressed: _add, child: const Icon(Icons.add)),
    );
  }
}
