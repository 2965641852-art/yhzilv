import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/todo_model.dart';
import '../providers/todo_provider.dart';
import '../services/notification_service.dart';

class AddTodoScreen extends StatefulWidget {
  final TodoModel? existingTodo;

  const AddTodoScreen({super.key, this.existingTodo});

  @override
  State<AddTodoScreen> createState() => _AddTodoScreenState();
}

class _AddTodoScreenState extends State<AddTodoScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descController = TextEditingController();

  TodoPriority _priority = TodoPriority.medium;
  String _category = '其他';
  DateTime? _dueDate;
  DateTime? _remindTime;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    if (widget.existingTodo != null) {
      _isEditing = true;
      final t = widget.existingTodo!;
      _titleController.text = t.title;
      _descController.text = t.description;
      _priority = t.priority;
      _category = t.category;
      _dueDate = t.dueDate;
      _remindTime = t.remindTime;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? '编辑待办' : '新增待办'),
        centerTitle: true,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 标题
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: '标题',
                  hintText: '你要完成什么？',
                  prefixIcon: const Icon(Icons.edit_note),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: (v) => (v == null || v.trim().isEmpty) ? '标题不能为空' : null,
              ),
              const SizedBox(height: 16),

              // 描述
              TextFormField(
                controller: _descController,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: '描述（可选）',
                  prefixIcon: const Icon(Icons.description_outlined),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 20),

              // 优先级
              _buildSectionLabel('优先级'),
              _buildPrioritySelector(),
              const SizedBox(height: 20),

              // 分类
              _buildSectionLabel('分类'),
              _buildCategorySelector(),
              const SizedBox(height: 20),

              // 截止时间
              _buildSectionLabel('截止时间'),
              _buildDateTimePicker(
                label: _dueDate == null ? '设置截止时间' : DateFormat('MM月dd日 HH:mm').format(_dueDate!),
                icon: Icons.access_time,
                hasClear: _dueDate != null,
                onTap: () => _pickDateTime(true),
                onClear: () => setState(() => _dueDate = null),
              ),
              const SizedBox(height: 16),

              // 提醒时间
              _buildSectionLabel('提醒时间'),
              _buildDateTimePicker(
                label: _remindTime == null ? '设置提醒时间' : DateFormat('MM月dd日 HH:mm').format(_remindTime!),
                icon: Icons.notifications_outlined,
                hasClear: _remindTime != null,
                onTap: () => _pickDateTime(false),
                onClear: () => setState(() => _remindTime = null),
              ),
              const SizedBox(height: 32),

              // 保存按钮
              ElevatedButton(
                onPressed: _saveTodo,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  _isEditing ? '保存修改' : '创建待办',
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Colors.grey.shade600,
        ),
      ),
    );
  }

  Widget _buildPrioritySelector() {
    return Row(
      children: TodoPriority.values.map((p) {
        final selected = _priority == p;
        final (label, color) = switch (p) {
          TodoPriority.low => ('低', Colors.green),
          TodoPriority.medium => ('中', Colors.orange),
          TodoPriority.high => ('高', Colors.red),
        };
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: ChoiceChip(
              label: Text(label),
              selected: selected,
              onSelected: (_) => setState(() => _priority = p),
              selectedColor: color.withOpacity(0.2),
              backgroundColor: Colors.grey.shade100,
              side: BorderSide(
                color: selected ? color : Colors.grey.shade300,
              ),
              labelStyle: TextStyle(
                color: selected ? color : Colors.grey.shade600,
                fontWeight: selected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildCategorySelector() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: TodoCategory.defaults.map((cat) {
        final selected = _category == cat;
        return ChoiceChip(
          label: Text(cat),
          selected: selected,
          onSelected: (_) => setState(() => _category = cat),
          backgroundColor: Colors.grey.shade100,
          selectedColor: Theme.of(context).colorScheme.primaryContainer,
          side: BorderSide(
            color: selected
                ? Theme.of(context).colorScheme.primary
                : Colors.grey.shade300,
          ),
        );
      }).toList(),
    );
  }

  Widget _buildDateTimePicker({
    required String label,
    required IconData icon,
    required VoidCallback onTap,
    required VoidCallback? onClear,
    required bool hasClear,
  }) {
    return Row(
      children: [
        Expanded(
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(icon, size: 20, color: Colors.grey.shade500),
                  const SizedBox(width: 12),
                  Text(
                    label,
                    style: TextStyle(
                      color: _dueDate == null && !hasClear
                          ? Colors.grey.shade500
                          : Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (hasClear)
          IconButton(
            onPressed: onClear,
            icon: const Icon(Icons.close, size: 20),
          ),
      ],
    );
  }

  Future<void> _pickDateTime(bool isDueDate) async {
    final now = DateTime.now();
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: Theme.of(context).colorScheme,
        ),
        child: child!,
      ),
    );
    if (pickedDate == null || !mounted) return;

    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(now),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: Theme.of(context).colorScheme,
        ),
        child: child!,
      ),
    );
    if (pickedTime == null) return;

    final combined = DateTime(
      pickedDate.year,
      pickedDate.month,
      pickedDate.day,
      pickedTime.hour,
      pickedTime.minute,
    );

    setState(() {
      if (isDueDate) {
        _dueDate = combined;
      } else {
        _remindTime = combined;
      }
    });
  }

  void _saveTodo() async {
    if (!_formKey.currentState!.validate()) return;

    final todoProvider = context.read<TodoProvider>();
    final notificationService = NotificationService();

    if (_isEditing && widget.existingTodo != null) {
      final old = widget.existingTodo!;
      // 如果提醒时间变更，先取消旧提醒
      if (old.remindTime != _remindTime && old.id != null && old.remindTime != null) {
        await notificationService.cancelReminder(old.id!);
      }

      await todoProvider.updateTodo(old.copyWith(
        title: _titleController.text.trim(),
        description: _descController.text.trim(),
        priority: _priority,
        category: _category,
        dueDate: _dueDate,
        remindTime: _remindTime,
      ));

      // 设置新提醒
      if (_remindTime != null && old.id != null) {
        await notificationService.scheduleTodoReminder(
          id: old.id!,
          title: _titleController.text.trim(),
          remindTime: _remindTime!,
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('已更新')),
        );
      }
    } else {
      final todo = TodoModel(
        title: _titleController.text.trim(),
        description: _descController.text.trim(),
        priority: _priority,
        category: _category,
        dueDate: _dueDate,
        remindTime: _remindTime,
      );

      await todoProvider.addTodo(todo);

      // 获取刚插入的 ID 来设置提醒
      final todos = todoProvider.todos;
      if (todos.isNotEmpty && _remindTime != null) {
        final inserted = todos.first;
        if (inserted.id != null) {
          await notificationService.scheduleTodoReminder(
            id: inserted.id!,
            title: todo.title,
            remindTime: _remindTime!,
          );
        }
      }
    }

    if (mounted) Navigator.pop(context);
  }
}
