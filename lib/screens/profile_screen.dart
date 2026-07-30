import 'package:flutter/material.dart';
import '../database/app_database.dart';
import '../services/notification_service.dart';
import 'anniversary_screen.dart';
import '../app_theme.dart';
import '../main.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String _signature = '自律成就更好的自己';
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _loadSignature();
  }

  Future<void> _loadSignature() async {
    final db = AppDatabase();
    final saved = await db.getSetting('signature');
    if (saved != null && saved.isNotEmpty) {
      setState(() => _signature = saved);
    }
    setState(() => _loaded = true);
  }

  Future<void> _editSignature() async {
    final controller = TextEditingController(text: _signature);
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('个性签名'),
        content: TextField(
          controller: controller,
          maxLength: 30,
          decoration: const InputDecoration(hintText: '输入你的个性签名'),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
          TextButton(onPressed: () => Navigator.pop(ctx, controller.text.trim()), child: const Text('保存')),
        ],
      ),
    );
    if (result != null && result.isNotEmpty) {
      await AppDatabase().setSetting('signature', result);
      setState(() => _signature = result);
    }
  }

  Future<void> _pickDailyReminder(BuildContext context) async {
    final time = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 8, minute: 0),
      initialEntryMode: TimePickerEntryMode.input,
    );
    if (time == null || !context.mounted) return;
    await NotificationService().scheduleDailyCheckin(
      hour: time.hour,
      minute: time.minute,
      message: '新的一天，别忘了完成今日待办！',
    );
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('已设置每日 ${time.hour}:${time.minute.toString().padLeft(2, '0')} 提醒')),
      );
    }
  }

  void _pickTheme(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Wrap(
          spacing: 12,
          runSpacing: 12,
          children: AppTheme.themes.map((t) {
            return GestureDetector(
              onTap: () {
                YehengApp.setTheme(context, t.name);
                if (t.isDark) YehengApp.setDarkMode(context, 'dark');
                Navigator.pop(ctx);
              },
              child: Container(
                width: 70, height: 70,
                decoration: BoxDecoration(color: t.seedColor, borderRadius: BorderRadius.circular(16)),
                child: Center(child: Text(t.name, style: const TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.bold))),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    return Scaffold(
      appBar: AppBar(title: const Text('我的'), centerTitle: true, elevation: 0),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // 用户卡片
            Container(
              width: double.infinity, padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Theme.of(context).colorScheme.primary.withOpacity(0.8), Theme.of(context).colorScheme.primary],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  const CircleAvatar(radius: 36, backgroundColor: Colors.white, child: Icon(Icons.person, size: 36)),
                  const SizedBox(height: 12),
                  const Text('叶恒', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
                  const SizedBox(height: 6),
                  GestureDetector(
                    onTap: _editSignature,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Flexible(child: Text(_signature, style: const TextStyle(fontSize: 13, color: Colors.white70), overflow: TextOverflow.ellipsis)),
                        const SizedBox(width: 4), const Icon(Icons.edit, size: 14, color: Colors.white54),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            _buildMenuItem(Icons.favorite, '纪念日', '重要日期倒计时与正计时', () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const AnniversaryScreen()));
            }),
            _buildMenuItem(Icons.notifications_outlined, '每日打卡提醒', '设置每日早晚打卡时间', () => _pickDailyReminder(context)),
            _buildMenuItem(Icons.palette_outlined, '主题配色', '选择你喜欢的配色风格', () => _pickTheme(context)),
            _buildMenuItem(Icons.info_outline, '关于', '叶恒的自律生活 v2.1.0', () {}),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem(IconData icon, String title, String subtitle, VoidCallback onTap) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(color: Theme.of(context).cardColor, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade200)),
      child: ListTile(
        leading: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Theme.of(context).colorScheme.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(8)), child: Icon(icon, color: Theme.of(context).colorScheme.primary)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
        trailing: const Icon(Icons.chevron_right, color: Colors.grey),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        onTap: onTap,
      ),
    );
  }
}
