import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/usage_provider.dart';
import 'usage_permission_screen.dart';
import 'usage_detail_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _limitController = TextEditingController();
  String _selectedApp = '';

  @override
  void dispose() {
    _limitController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('我的'),
        centerTitle: true,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Consumer<UsageProvider>(
          builder: (context, usageProvider, child) {
            return Column(
              children: [
                // 用户卡片
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Theme.of(context).colorScheme.primary.withOpacity(0.8),
                        Theme.of(context).colorScheme.primary,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Column(
                    children: [
                      CircleAvatar(
                        radius: 36,
                        backgroundColor: Colors.white,
                        child: Icon(Icons.person, size: 36),
                      ),
                      SizedBox(height: 12),
                      Text(
                        '叶恒',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        '自律成就更好的自己',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // 功能列表
                _buildMenuItem(
                  icon: Icons.bar_chart_rounded,
                  title: '使用时长详情',
                  subtitle: '查看各应用使用统计',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const UsageDetailScreen(),
                      ),
                    );
                  },
                ),
                _buildMenuItem(
                  icon: Icons.security,
                  title: '使用时长权限',
                  subtitle: '开启应用使用情况访问',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const UsagePermissionScreen(),
                      ),
                    );
                  },
                ),
                _buildMenuItem(
                  icon: Icons.timer_off,
                  title: '应用使用限额',
                  subtitle: '设置各应用每日使用时长上限',
                  onTap: () => _showLimitDialog(context, usageProvider),
                ),
                const SizedBox(height: 16),
                const Divider(),
                _buildMenuItem(
                  icon: Icons.notifications_outlined,
                  title: '每日打卡提醒',
                  subtitle: '设置每日早晚打卡时间',
                  onTap: () {},
                ),
                _buildMenuItem(
                  icon: Icons.info_outline,
                  title: '关于',
                  subtitle: '叶恒的自律生活 v1.0.0',
                  onTap: () {},
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: Theme.of(context).colorScheme.primary),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
        trailing:
            const Icon(Icons.chevron_right, color: Colors.grey),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        onTap: onTap,
      ),
    );
  }

  void _showLimitDialog(BuildContext context, UsageProvider provider) {
    _limitController.clear();
    _selectedApp = '';

    // 获取可限制的应用列表
    final apps = provider.todayUsage;
    if (apps.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请先加载使用时长数据')),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    '设置应用使用限额',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  // 选择应用
                  DropdownButtonFormField<String>(
                    value: _selectedApp.isEmpty ? null : _selectedApp,
                    decoration: InputDecoration(
                      labelText: '选择应用',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    items: apps.map((app) {
                      return DropdownMenuItem(
                        value: app.packageName,
                        child: Text(app.appName),
                      );
                    }).toList(),
                    onChanged: (v) => setSheetState(() => _selectedApp = v ?? ''),
                  ),
                  const SizedBox(height: 12),
                  // 设置分钟数
                  TextField(
                    controller: _limitController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: '每日限额（分钟）',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      suffixIcon: const Icon(Icons.timer),
                    ),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {
                      final minutes = int.tryParse(_limitController.text);
                      if (_selectedApp.isNotEmpty && minutes != null && minutes > 0) {
                        provider.setLimit(_selectedApp, minutes);
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('已设置 ${apps.firstWhere((a) => a.packageName == _selectedApp).appName} 每日限额 ${minutes} 分钟'),
                          ),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('保存设置'),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
