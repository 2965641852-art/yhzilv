import 'package:intl/intl.dart';

enum TodoPriority { low, medium, high }
enum TodoStatus { pending, completed, expired }
enum TodoType { normal, daily, disposable } // normal=普通, daily=当日完成, disposable=完成即删

class TodoModel {
  final int? id;
  final String title;
  final String description;
  final TodoPriority priority;
  final String category;
  final DateTime? dueDate;
  final DateTime? remindTime;
  final bool isCompleted;
  final bool isDaily;
  final int? durationMinutes;
  final String? lastCompletedDate;
  final TodoType todoType; // 0=normal, 1=daily(当日), 2=disposable(完成即删)
  final int sortOrder;
  final DateTime createdAt;
  final DateTime? completedAt;

  TodoModel({
    this.id,
    required this.title,
    this.description = '',
    this.priority = TodoPriority.medium,
    this.category = '其他',
    this.dueDate,
    this.remindTime,
    this.isCompleted = false,
    this.isDaily = false,
    this.durationMinutes,
    this.lastCompletedDate,
    this.todoType = TodoType.normal,
    this.sortOrder = 0,
    DateTime? createdAt,
    this.completedAt,
  }) : createdAt = createdAt ?? DateTime.now();

  TodoStatus get status {
    if (isCompleted) return TodoStatus.completed;
    if (dueDate != null && dueDate!.isBefore(DateTime.now())) return TodoStatus.expired;
    return TodoStatus.pending;
  }

  String get priorityText {
    switch (priority) {
      case TodoPriority.low: return '低';
      case TodoPriority.medium: return '中';
      case TodoPriority.high: return '高';
    }
  }

  String get formattedDate {
    if (dueDate == null) return '';
    return DateFormat('MM/dd HH:mm').format(dueDate!);
  }

  String get durationText {
    if (durationMinutes == null || durationMinutes == 0) return '';
    if (durationMinutes! >= 60) { final h = durationMinutes! ~/ 60; final m = durationMinutes! % 60; return m > 0 ? '${h}h${m}m' : '${h}h'; }
    return '${durationMinutes}m';
  }

  String get typeLabel {
    switch (todoType) {
      case TodoType.daily: return '某日';
      case TodoType.disposable: return '即删';
      default: return '';
    }
  }

  Map<String, dynamic> toMap() => {
    if (id != null) 'id': id, 'title': title, 'description': description,
    'priority': priority.index, 'category': category,
    'due_date': dueDate?.millisecondsSinceEpoch, 'remind_time': remindTime?.millisecondsSinceEpoch,
    'is_completed': isCompleted ? 1 : 0, 'is_daily': isDaily ? 1 : 0,
    'duration_minutes': durationMinutes, 'last_completed_date': lastCompletedDate,
    'todo_type': todoType.index, 'sort_order': sortOrder,
    'created_at': createdAt.millisecondsSinceEpoch, 'completed_at': completedAt?.millisecondsSinceEpoch,
  };

  factory TodoModel.fromMap(Map<String, dynamic> m) => TodoModel(
    id: m['id'] as int?, title: m['title'] as String,
    description: m['description'] as String? ?? '',
    priority: TodoPriority.values[m['priority'] as int? ?? 1],
    category: m['category'] as String? ?? '其他',
    dueDate: m['due_date'] != null ? DateTime.fromMillisecondsSinceEpoch(m['due_date'] as int) : null,
    remindTime: m['remind_time'] != null ? DateTime.fromMillisecondsSinceEpoch(m['remind_time'] as int) : null,
    isCompleted: (m['is_completed'] as int? ?? 0) == 1,
    isDaily: (m['is_daily'] as int? ?? 0) == 1,
    durationMinutes: m['duration_minutes'] as int?,
    lastCompletedDate: m['last_completed_date'] as String?,
    todoType: TodoType.values[m['todo_type'] as int? ?? 0],
    sortOrder: m['sort_order'] as int? ?? 0,
    createdAt: m['created_at'] != null ? DateTime.fromMillisecondsSinceEpoch(m['created_at'] as int) : DateTime.now(),
    completedAt: m['completed_at'] != null ? DateTime.fromMillisecondsSinceEpoch(m['completed_at'] as int) : null,
  );

  TodoModel copyWith({
    int? id, String? title, String? description, TodoPriority? priority, String? category,
    DateTime? dueDate, DateTime? remindTime, bool? isCompleted, bool? isDaily,
    int? durationMinutes, String? lastCompletedDate, TodoType? todoType, int? sortOrder,
    DateTime? createdAt, DateTime? completedAt,
  }) => TodoModel(
    id: id ?? this.id, title: title ?? this.title, description: description ?? this.description,
    priority: priority ?? this.priority, category: category ?? this.category,
    dueDate: dueDate ?? this.dueDate, remindTime: remindTime ?? this.remindTime,
    isCompleted: isCompleted ?? this.isCompleted, isDaily: isDaily ?? this.isDaily,
    durationMinutes: durationMinutes ?? this.durationMinutes, lastCompletedDate: lastCompletedDate ?? this.lastCompletedDate,
    todoType: todoType ?? this.todoType, sortOrder: sortOrder ?? this.sortOrder,
    createdAt: createdAt ?? this.createdAt, completedAt: completedAt ?? this.completedAt,
  );
}

class TodoCategory {
  static const List<String> defaults = ['工作','学习','生活','运动','健康','阅读','其他'];
}
