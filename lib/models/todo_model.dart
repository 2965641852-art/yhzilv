import 'dart:convert';
import 'package:intl/intl.dart';

enum TodoPriority { low, medium, high }
enum TodoStatus { pending, completed, expired }

/// 任务类型: disposable=完成即删, oneDay=某日完成, custom=自定义规则
enum TodoType { disposable, oneDay, custom }

class TodoModel {
  final int? id;
  final String title;
  final String description;
  final TodoPriority priority;
  final String category;
  final TodoType type;
  final String repeatRule; // JSON: {"mode":"daily"} | {"mode":"weekly","days":[0,6]} | {"mode":"range","start":"...","end":"..."}
  final DateTime? remindTime;
  final bool isCompleted;
  final int sortOrder;
  final DateTime? completedAt;
  final DateTime? dueDate;
  final String? lastCompletedDate;
  final DateTime createdAt;

  TodoModel({
    this.id,
    required this.title,
    this.description = '',
    this.priority = TodoPriority.medium,
    this.category = '其他',
    this.type = TodoType.disposable,
    this.repeatRule = '',
    this.remindTime,
    this.isCompleted = false,
    this.sortOrder = 0,
    this.completedAt,
    this.dueDate,
    this.lastCompletedDate,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  TodoStatus get status {
    if (isCompleted) return TodoStatus.completed;
    return TodoStatus.pending;
  }

  String get priorityText {
    switch (priority) { case TodoPriority.low: return '低'; case TodoPriority.medium: return '中'; case TodoPriority.high: return '高'; }
  }

  String get typeLabel {
    switch (type) { case TodoType.disposable: return '即删'; case TodoType.oneDay: return '某日'; case TodoType.custom: return '自定义'; }
  }

  /// 判断任务在指定日期是否应该显示
  bool shouldShowOn(DateTime date) {
    if (type == TodoType.disposable) return true;
    if (type == TodoType.oneDay) {
      if (dueDate == null) return false;
      return date.year == dueDate!.year && date.month == dueDate!.month && date.day == dueDate!.day;
    }
    // custom: 根据 repeatRule 判断
    if (repeatRule.isEmpty) return true;
    try {
      final rule = jsonDecode(repeatRule);
      final mode = rule['mode'] as String;
      final dow = date.weekday % 7; // 周日=0, 周一=1...周六=6
      switch (mode) {
        case 'daily': return true;
        case 'weekly':
          final days = (rule['days'] as List).cast<int>();
          return days.contains(dow);
        case 'workday': return dow >= 1 && dow <= 5;
        case 'weekend': return dow == 0 || dow == 6;
        case 'range':
          final start = DateTime.parse(rule['start']);
          final end = DateTime.parse(rule['end']);
          final d = DateTime(date.year, date.month, date.day);
          return !d.isBefore(start) && !d.isAfter(end);
        default: return true;
      }
    } catch (_) { return true; }
  }

  Map<String, dynamic> toMap() => {
    if (id != null) 'id': id, 'title': title, 'description': description,
    'priority': priority.index, 'category': category, 'type': type.index,
    'repeat_rule': repeatRule, 'remind_time': remindTime?.millisecondsSinceEpoch,
    'is_completed': isCompleted ? 1 : 0, 'sort_order': sortOrder,
    'completed_at': completedAt?.millisecondsSinceEpoch, 'due_date': dueDate?.millisecondsSinceEpoch,
    'last_completed_date': lastCompletedDate, 'created_at': createdAt.millisecondsSinceEpoch,
  };

  factory TodoModel.fromMap(Map<String, dynamic> m) => TodoModel(
    id: m['id'] as int?, title: m['title'] as String, description: m['description'] as String? ?? '',
    priority: TodoPriority.values[m['priority'] as int? ?? 1], category: m['category'] as String? ?? '其他',
    type: TodoType.values[m['type'] as int? ?? 0], repeatRule: m['repeat_rule'] as String? ?? '',
    remindTime: m['remind_time'] != null ? DateTime.fromMillisecondsSinceEpoch(m['remind_time'] as int) : null,
    isCompleted: (m['is_completed'] as int? ?? 0) == 1, sortOrder: m['sort_order'] as int? ?? 0,
    completedAt: m['completed_at'] != null ? DateTime.fromMillisecondsSinceEpoch(m['completed_at'] as int) : null,
    dueDate: m['due_date'] != null ? DateTime.fromMillisecondsSinceEpoch(m['due_date'] as int) : null,
    lastCompletedDate: m['last_completed_date'] as String?,
    createdAt: m['created_at'] != null ? DateTime.fromMillisecondsSinceEpoch(m['created_at'] as int) : DateTime.now(),
  );

  TodoModel copyWith({int? id, String? title, String? description, TodoPriority? priority, String? category,
    TodoType? type, String? repeatRule, DateTime? remindTime, bool? isCompleted, int? sortOrder,
    DateTime? completedAt, DateTime? dueDate, String? lastCompletedDate, DateTime? createdAt}) =>
    TodoModel(id: id ?? this.id, title: title ?? this.title, description: description ?? this.description,
      priority: priority ?? this.priority, category: category ?? this.category,
      type: type ?? this.type, repeatRule: repeatRule ?? this.repeatRule,
      remindTime: remindTime ?? this.remindTime, isCompleted: isCompleted ?? this.isCompleted,
      sortOrder: sortOrder ?? this.sortOrder, completedAt: completedAt ?? this.completedAt,
      dueDate: dueDate ?? this.dueDate, lastCompletedDate: lastCompletedDate ?? this.lastCompletedDate,
      createdAt: createdAt ?? this.createdAt);
}

class TodoCategory {
  static const List<String> defaults = ['工作','学习','生活','运动','健康','阅读','其他'];
}
