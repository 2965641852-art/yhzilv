import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/todo_model.dart';
import '../providers/todo_provider.dart';
import 'package:provider/provider.dart';

class AddTodoScreen extends StatefulWidget {
  final TodoModel? existingTodo;
  const AddTodoScreen({super.key, this.existingTodo});
  @override
  State<AddTodoScreen> createState() => _AddTodoScreenState();
}

class _AddTodoScreenState extends State<AddTodoScreen> {
  final _titleCtrl = TextEditingController(), _descCtrl = TextEditingController();
  TodoPriority _priority = TodoPriority.medium;
  String _category = '其他';
  TodoType _type = TodoType.disposable;
  String _repeatRule = '';
  DateTime? _dueDate, _remindTime;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    if (widget.existingTodo != null) {
      _isEditing = true;
      final t = widget.existingTodo!;
      _titleCtrl.text = t.title; _descCtrl.text = t.description;
      _priority = t.priority; _category = t.category;
      _type = t.type; _repeatRule = t.repeatRule; _dueDate = t.dueDate; _remindTime = t.remindTime;
    }
  }

  @override
  void dispose() { _titleCtrl.dispose(); _descCtrl.dispose(); super.dispose(); }

  void _setRepeatRule(String rule) => setState(() => _repeatRule = rule);

  Future<void> _pickDate() async {
    final d = await showDatePicker(context: context, initialDate: _dueDate ?? DateTime.now(), firstDate: DateTime(2020), lastDate: DateTime(2030));
    if (d != null) setState(() => _dueDate = d);
  }

  Future<void> _pickTime() async {
    final t = await showTimePicker(context: context, initialTime: TimeOfDay.now());
    if (t != null) setState(() => _remindTime = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day, t.hour, t.minute));
  }

  void _save() {
    if (_titleCtrl.text.trim().isEmpty) return;
    final todo = TodoModel(title: _titleCtrl.text.trim(), description: _descCtrl.text.trim(),
      priority: _priority, category: _category, type: _type, repeatRule: _repeatRule,
      dueDate: _type == TodoType.oneDay ? _dueDate : null, remindTime: _remindTime);
    final p = context.read<TodoProvider>();
    if (_isEditing && widget.existingTodo != null) {
      p.updateTodo(widget.existingTodo!.copyWith(title: todo.title, description: todo.description,
        priority: todo.priority, category: todo.category, type: todo.type, repeatRule: todo.repeatRule,
        dueDate: todo.dueDate, remindTime: todo.remindTime));
    } else { p.addTodo(todo); }
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_isEditing ? '编辑待办' : '新建待办'), centerTitle: true, elevation: 0),
      body: SingleChildScrollView(padding: const EdgeInsets.all(20), child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        TextField(controller: _titleCtrl, decoration: const InputDecoration(labelText: '标题', border: OutlineInputBorder()), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
        const SizedBox(height: 14),
        TextField(controller: _descCtrl, maxLines: 3, decoration: const InputDecoration(labelText: '描述（可选）', border: OutlineInputBorder())),
        const SizedBox(height: 20),
        _section('类型'), _typeSelector(),
        if (_type == TodoType.oneDay) ...[const SizedBox(height: 12),
          ListTile(title: Text(_dueDate == null ? '选择日期' : DateFormat('M月d日').format(_dueDate!)), trailing: const Icon(Icons.calendar_today), onTap: _pickDate)],
        if (_type == TodoType.custom) ...[const SizedBox(height: 12), _customRuleBuilder()],
        const SizedBox(height: 20),
        _section('优先级'), _prioritySelector(),
        const SizedBox(height: 20),
        _section('分类'), _categorySelector(),
        const SizedBox(height: 20),
        _section('提醒时间'),
        ListTile(title: Text(_remindTime == null ? '不提醒' : DateFormat('MM/dd HH:mm').format(_remindTime!)), trailing: const Icon(Icons.notifications_outlined), onTap: _pickTime),
        const SizedBox(height: 30),
        ElevatedButton(onPressed: _save, style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
          child: Text(_isEditing ? '保存修改' : '创建待办', style: const TextStyle(fontSize: 16))),
      ])),
    );
  }

  Widget _section(String t) => Padding(padding: const EdgeInsets.only(bottom: 8), child: Text(t, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.grey.shade600)));

  Widget _typeSelector() => Row(children: [
    _typeBtn(TodoType.disposable, '完成即删', Icons.delete_outline, Colors.purple),
    _typeBtn(TodoType.oneDay, '某日完成', Icons.today, Colors.amber),
    _typeBtn(TodoType.custom, '自定义', Icons.tune, Colors.blue),
  ]);

  Widget _typeBtn(TodoType t, String label, IconData icon, Color c) {
    final sel = _type == t;
    return Expanded(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 2), child: ChoiceChip(
      label: FittedBox(fit: BoxFit.scaleDown, child: Text(label, style: TextStyle(fontSize: 11, color: sel ? Colors.white : Colors.grey.shade700, fontWeight: sel ? FontWeight.bold : FontWeight.normal))),
      selected: sel, onSelected: (_) => setState(() => _type = t), selectedColor: c, backgroundColor: Colors.grey.shade100,
      side: BorderSide(color: sel ? c : Colors.grey.shade300), padding: const EdgeInsets.symmetric(horizontal: 2),
    )));
  }

  Widget _customRuleBuilder() {
    final rule = _repeatRule.isEmpty ? {'mode': 'daily'} : jsonDecode(_repeatRule);
    final mode = rule['mode'] as String;
    return Card(child: Padding(padding: const EdgeInsets.all(12), child: Column(children: [
      DropdownButtonFormField<String>(value: mode, decoration: const InputDecoration(labelText: '重复规则', border: InputBorder.none), items: [
        DropdownMenuItem(value: 'daily', child: const Text('每天')),
        DropdownMenuItem(value: 'weekly', child: const Text('每周指定')),
        DropdownMenuItem(value: 'workday', child: const Text('工作日')),
        DropdownMenuItem(value: 'weekend', child: const Text('周末')),
        DropdownMenuItem(value: 'range', child: const Text('日期范围')),
      ].map((e) => e).toList(), onChanged: (v) { if (v != null) _setRepeatRule(jsonEncode({'mode': v})); }),
      if (mode == 'weekly') Wrap(spacing: 6, children: ['日','一','二','三','四','五','六'].asMap().entries.map((e) => ChoiceChip(
        label: Text(e.value), selected: ((rule['days'] as List?) ?? []).contains(e.key),
        onSelected: (sel) {
          final days = List<int>.from((rule['days'] as List?) ?? []);
          sel ? days.add(e.key) : days.remove(e.key);
          _setRepeatRule(jsonEncode({'mode': 'weekly', 'days': days}));
        }, selectedColor: Theme.of(context).colorScheme.primary, backgroundColor: Colors.grey.shade100,
      )).toList()),
      if (mode == 'range')
        Row(children: [
          Expanded(child: OutlinedButton(onPressed: () async {
            final d = await showDatePicker(context: context, initialDate: DateTime.now(), firstDate: DateTime(2020), lastDate: DateTime(2030));
            if (d != null) _setRepeatRule(jsonEncode({'mode': 'range', 'start': DateFormat('yyyy-MM-dd').format(d), 'end': rule['end'] ?? DateFormat('yyyy-MM-dd').format(DateTime.now().add(const Duration(days: 30)))}));
          }, child: Text('开始: ${rule['start'] ?? '未选'}'))),
          const SizedBox(width: 8),
          Expanded(child: OutlinedButton(onPressed: () async {
            final d = await showDatePicker(context: context, initialDate: DateTime.now().add(const Duration(days: 30)), firstDate: DateTime(2020), lastDate: DateTime(2030));
            if (d != null) _setRepeatRule(jsonEncode({'mode': 'range', 'start': rule['start'] ?? DateFormat('yyyy-MM-dd').format(DateTime.now()), 'end': DateFormat('yyyy-MM-dd').format(d)}));
          }, child: Text('结束: ${rule['end'] ?? '未选'}'))),
        ]),
    ])));
  }

  Widget _prioritySelector() => Row(children: TodoPriority.values.map((p) {
    final sel = _priority == p;
    final (lbl, clr) = switch (p) { TodoPriority.low => ('低', Colors.green), TodoPriority.medium => ('中', Colors.orange), TodoPriority.high => ('高', Colors.red) };
    return Expanded(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 3), child: ChoiceChip(label: Text(lbl), selected: sel, onSelected: (_) => setState(() => _priority = p),
      selectedColor: clr.withOpacity(0.2), backgroundColor: Colors.grey.shade100, side: BorderSide(color: sel ? clr : Colors.grey.shade300),
      labelStyle: TextStyle(color: sel ? clr : Colors.grey.shade600, fontWeight: sel ? FontWeight.bold : FontWeight.normal),
    )));
  }).toList());

  Widget _categorySelector() => Wrap(spacing: 8, runSpacing: 8, children: TodoCategory.defaults.map((cat) {
    final sel = _category == cat;
    return ChoiceChip(label: Text(cat), selected: sel, onSelected: (_) => setState(() => _category = cat),
      backgroundColor: Colors.grey.shade100, selectedColor: Theme.of(context).colorScheme.primaryContainer,
      side: BorderSide(color: sel ? Theme.of(context).colorScheme.primary : Colors.grey.shade300));
  }).toList());
}
